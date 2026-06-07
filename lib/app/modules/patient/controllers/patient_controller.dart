import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/agora/agora_service.dart';
import '../../../routes/app_pages.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorOption {
  const DoctorOption({
    required this.id,
    required this.name,
    this.specialty,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? specialty;
  final String? avatarUrl;
}

class PatientAppointment {
  const PatientAppointment({
    required this.id,
    required this.doctorId,
    required this.doctor,
    required this.time,
    required this.status,
    this.urgent = false,
    this.doctorAvatarUrl,
  });

  final String id;
  final String doctorId;
  final String doctor;
  final String time;
  final String status;
  final bool urgent;
  final String? doctorAvatarUrl;

  bool get chatEnabled => status == 'Accepted';
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.senderId,
    this.message,
    this.attachmentName,
    this.attachmentType,
    this.attachmentPath,
    this.deliveryStatus,
    this.seenAt,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String? message;
  final String? attachmentName;
  final String? attachmentType;
  final String? attachmentPath;
  final String? deliveryStatus;
  final DateTime? seenAt;
  final DateTime? createdAt;
}

class PatientController extends GetxController {
  final RxList<PatientAppointment> appointments = <PatientAppointment>[].obs;

  final RxList<DoctorOption> doctors = <DoctorOption>[].obs;
  final RxList<DoctorOption> filteredDoctors = <DoctorOption>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxnString selectedDoctorId = RxnString();
  final Rxn<DateTime> selectedDateTime = Rxn<DateTime>();
  final RxBool isBooking = false.obs;

  final TextEditingController messageController = TextEditingController();
  final TextEditingController complaintTitleController =
      TextEditingController();
  final TextEditingController complaintBodyController = TextEditingController();
  final RxnString selectedChatAppointmentId = RxnString();
  final RxList<ChatMessageItem> messages = <ChatMessageItem>[].obs;
  final RxMap<String, int> unreadCountsByAppointment = <String, int>{}.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  RealtimeChannel? _messagesChannel;

  final RxBool isLoadingAppointments = false.obs;
  final RxString appointmentsError = ''.obs;
  final RxString bookingError = ''.obs;
  final RxString messagesError = ''.obs;
  final RxBool isSubmittingComplaint = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxString uploadStatusMessage = ''.obs;
  final RxBool uploadStatusError = false.obs;

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  bool get hasAcceptedAppointmentForChat => appointments.any(
    (PatientAppointment item) =>
        item.id == selectedChatAppointmentId.value && item.chatEnabled,
  );

  PatientAppointment? get selectedChatAppointment {
    for (final PatientAppointment item in appointments) {
      if (item.id == selectedChatAppointmentId.value) {
        return item;
      }
    }
    return null;
  }

  bool get canStartSelectedVideoCall =>
      selectedChatAppointment?.chatEnabled ?? false;

  bool isOwnMessage(String senderId) => senderId == _currentUserId;

  int unreadForAppointment(String appointmentId) =>
      unreadCountsByAppointment[appointmentId] ?? 0;

  String formatMessageTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final DateTime local = value.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String messageStatusFor(ChatMessageItem message) {
    if (!isOwnMessage(message.senderId)) {
      return '';
    }

    final String dbStatus = (message.deliveryStatus ?? '').toLowerCase();
    if (dbStatus == 'seen' || message.seenAt != null) {
      return 'Seen';
    }
    if (dbStatus == 'delivered') {
      return 'Delivered';
    }
    if (dbStatus == 'sent') {
      return 'Sent';
    }

    final DateTime? createdAt = message.createdAt;
    if (createdAt != null &&
        DateTime.now().difference(createdAt).inSeconds < 8) {
      return 'Sent';
    }

    final int index = messages.indexWhere(
      (ChatMessageItem m) => m.id == message.id,
    );
    if (index != -1) {
      final bool seenByReply = messages
          .skip(index + 1)
          .any((ChatMessageItem m) => !isOwnMessage(m.senderId));
      if (seenByReply) {
        return 'Seen';
      }
    }
    return 'Delivered';
  }

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
    loadAppointments();
    _setupRealtimeMessages();
  }

  @override
  void onClose() {
    if (_messagesChannel != null) {
      SupabaseService.client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
    messageController.dispose();
    complaintTitleController.dispose();
    complaintBodyController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void searchDoctors(String query) {
    if (query.isEmpty) {
      filteredDoctors.assignAll(doctors);
    } else {
      filteredDoctors.assignAll(
        doctors.where(
          (DoctorOption d) =>
              d.name.toLowerCase().contains(query.toLowerCase()) ||
              (d.specialty?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        ),
      );
    }
  }

  void sendConsultationRequest(String doctorId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      await SupabaseService.client.from('appointments').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': 'Pending',
      });

      Get.snackbar('Request Sent', 'Consultation request sent to doctor');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    }
  }

  void _setupRealtimeMessages() {
    if (!SupabaseService.isConfigured) {
      return;
    }

    if (_messagesChannel != null) {
      SupabaseService.client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }

    final String channelName =
        'patient-chat-${_currentUserId ?? DateTime.now().millisecondsSinceEpoch}';
    _messagesChannel = SupabaseService.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (PostgresChangePayload payload) {
            final String? selected = selectedChatAppointmentId.value;
            if (selected == null) {
              return;
            }

            final String newAppointment =
                payload.newRecord['appointment_id']?.toString() ?? '';
            final String oldAppointment =
                payload.oldRecord['appointment_id']?.toString() ?? '';
            if (newAppointment == selected || oldAppointment == selected) {
              loadMessages();
            } else {
              _loadUnreadCounts();
            }
          },
        )
        .subscribe();
  }

  String _friendlyError(Object error) {
    final String message = error.toString();
    final String lower = message.toLowerCase();
    if (lower.contains('permission denied') ||
        lower.contains('row-level security')) {
      return 'Permission denied by database policy.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('host')) {
      return 'Network error while connecting to Supabase.';
    }
    return 'Unexpected Supabase error.';
  }

  Future<void> loadDoctors() async {
    bookingError.value = '';
    if (!SupabaseService.isConfigured) {
      return;
    }
    try {
      final List<dynamic> response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, specialty, avatar_url')
          .eq('role', 'doctor')
          .order('full_name', ascending: true)
          .limit(100);

      final List<DoctorOption> list = await Future.wait(response.map<Future<DoctorOption>>(
        (dynamic row) async {
          final Map<String, dynamic> map = row as Map<String, dynamic>;
          final String name = map['full_name']?.toString() ?? 'Doctor';
          final String avatarPath = map['avatar_url']?.toString() ?? '';
          final String avatarUrl = avatarPath.isNotEmpty
              ? await _createSignedAvatarUrl(avatarPath)
              : '';
          return DoctorOption(
            id: map['id'].toString(),
            name: name,
            specialty: map['specialty']?.toString(),
            avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
          );
        },
      ));

      doctors.assignAll(list);
      filteredDoctors.assignAll(list);
      selectedDoctorId.value ??= list.isNotEmpty ? list.first.id : null;
      if (list.isEmpty) {
        bookingError.value = 'No registered doctors found yet.';
      }
    } catch (e) {
      bookingError.value = 'Failed to load doctors list. ${_friendlyError(e)}';
    }
  }

  Future<String> _createSignedAvatarUrl(String path) async {
    try {
      final String signedUrl = await SupabaseService.client.storage
          .from('avatars')
          .createSignedUrl(path, 3600);
      return signedUrl;
    } catch (_) {
      return '';
    }
  }

  Future<void> bookAppointment() async {
    bookingError.value = '';

    if (!SupabaseService.isConfigured) {
      bookingError.value = 'Supabase is not configured.';
      return;
    }

    final String? userId = _currentUserId;
    if (userId == null) {
      bookingError.value = 'User session is missing.';
      return;
    }

    if (selectedDoctorId.value == null || selectedDateTime.value == null) {
      bookingError.value = 'Please select doctor and appointment date.';
      return;
    }

    try {
      isBooking.value = true;
      await SupabaseService.client
          .from('appointments')
          .insert(<String, dynamic>{
            'patient_id': userId,
            'doctor_id': selectedDoctorId.value,
            'scheduled_at': selectedDateTime.value!.toUtc().toIso8601String(),
            'status': 'Pending',
          });

      Get.snackbar('Booked', 'Appointment request sent to doctor.');
      await loadAppointments();
    } catch (_) {
      bookingError.value = 'Failed to book appointment.';
    } finally {
      isBooking.value = false;
    }
  }

  Future<void> loadAppointments() async {
    appointmentsError.value = '';
    if (!SupabaseService.isConfigured) {
      return;
    }

    final String? userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      appointmentsError.value = 'User session is missing.';
      return;
    }

    try {
      isLoadingAppointments.value = true;
      final List<dynamic> response = await SupabaseService.client
          .from('appointments')
          .select(
            'id, doctor_id, status, scheduled_at, is_urgent, doctor:doctor_id(full_name, avatar_url)',
          )
          .eq('patient_id', userId)
          .eq('patient_deleted', false)
          .order('scheduled_at', ascending: true)
          .limit(30);

      final List<PatientAppointment> parsed = await Future.wait(
        response.map<Future<PatientAppointment>>(
          (dynamic row) async {
            final Map<String, dynamic> map = row as Map<String, dynamic>;
            final Map<String, dynamic>? doctor =
                map['doctor'] as Map<String, dynamic>?;
            final String avatarPath = doctor?['avatar_url']?.toString() ?? '';
            final String avatarUrl = avatarPath.isNotEmpty
                ? await _createSignedAvatarUrl(avatarPath)
                : '';

            return PatientAppointment(
              id: map['id']?.toString() ?? '',
              doctorId: map['doctor_id']?.toString() ?? '',
              doctor: (doctor?['full_name']?.toString().isNotEmpty ?? false)
                  ? doctor!['full_name'].toString()
                  : 'Doctor',
              time: _formatDate(map['scheduled_at']?.toString()),
              status: map['status']?.toString() ?? 'Scheduled',
              urgent: map['is_urgent'] == true,
              doctorAvatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            );
          },
        ),
      );

      appointments.assignAll(parsed);
      if (parsed.isNotEmpty) {
        PatientAppointment? accepted;
        for (final PatientAppointment item in parsed) {
          if (item.chatEnabled) {
            accepted = item;
            break;
          }
        }
        selectedChatAppointmentId.value ??= accepted?.id;
        if (selectedChatAppointmentId.value != null) {
          await loadMessages();
        }
        await _loadUnreadCounts();
      } else {
        selectedChatAppointmentId.value = null;
        messages.clear();
        unreadCountsByAppointment.clear();
      }
    } catch (_) {
      appointmentsError.value = 'Failed to load appointments from Supabase.';
    } finally {
      isLoadingAppointments.value = false;
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'No date';
    }
    final DateTime? dateTime = DateTime.tryParse(value)?.toLocal();
    if (dateTime == null) {
      return value;
    }
    final String mm = dateTime.month.toString().padLeft(2, '0');
    final String dd = dateTime.day.toString().padLeft(2, '0');
    final String hh = dateTime.hour.toString().padLeft(2, '0');
    final String min = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$mm-$dd $hh:$min';
  }

  void stopRealtimeMessages() {
    if (_messagesChannel != null) {
      SupabaseService.client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
  }

  void openVideoCall(PatientAppointment appointment, {String? token}) {
    if (!appointment.chatEnabled) {
      Get.snackbar(
        'Info',
        'Video call becomes available after doctor acceptance.',
      );
      return;
    }

    Get.toNamed(
      AppRoutes.call,
      arguments: <String, dynamic>{
        'appId': AgoraService.appId,
        'token': AgoraService.resolveToken(token),
        'appointmentId': appointment.id,
        'channelName': AgoraService.buildAppointmentChannel(appointment.id),
      },
    );
  }

  void openSelectedVideoCall() {
    final PatientAppointment? appointment = selectedChatAppointment;
    if (appointment == null) {
      Get.snackbar('Info', 'Select an accepted appointment first.');
      return;
    }

    openVideoCall(appointment);
  }

  Future<void> loadMessages() async {
    messagesError.value = '';
    final String? appointmentId = selectedChatAppointmentId.value;
    if (appointmentId == null) {
      messages.clear();
      return;
    }

    PatientAppointment? appt;
    for (final PatientAppointment item in appointments) {
      if (item.id == appointmentId) {
        appt = item;
        break;
      }
    }
    if (appt == null || !appt.chatEnabled) {
      messages.clear();
      messagesError.value = 'Chat opens after doctor accepts the appointment.';
      return;
    }

    if (!SupabaseService.isConfigured) {
      return;
    }

    try {
      isLoadingMessages.value = true;
      List<dynamic> response;
      try {
        response = await SupabaseService.client
            .from('chat_messages')
            .select(
              'id, sender_id, message_text, attachment_name, attachment_type, attachment_path, delivery_status, seen_at, created_at',
            )
            .eq('appointment_id', appointmentId)
            .order('created_at', ascending: true)
            .limit(200);
      } catch (_) {
        response = await SupabaseService.client
            .from('chat_messages')
            .select(
              'id, sender_id, message_text, attachment_name, attachment_type, attachment_path, created_at',
            )
            .eq('appointment_id', appointmentId)
            .order('created_at', ascending: true)
            .limit(200);
      }

      messages.assignAll(
        response.map((dynamic row) {
          final Map<String, dynamic> map = row as Map<String, dynamic>;
          return ChatMessageItem(
            id: map['id']?.toString() ?? '',
            senderId: map['sender_id']?.toString() ?? '',
            message: map['message_text']?.toString(),
            attachmentName: map['attachment_name']?.toString(),
            attachmentType: map['attachment_type']?.toString(),
            attachmentPath: map['attachment_path']?.toString(),
            deliveryStatus: map['delivery_status']?.toString(),
            seenAt: DateTime.tryParse(map['seen_at']?.toString() ?? ''),
            createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
          );
        }).toList(),
      );

      await _markIncomingDeliveredAndSeen(appointmentId);
      await _loadUnreadCounts();
    } catch (_) {
      messagesError.value = 'Failed to load chat messages.';
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> _markIncomingDeliveredAndSeen(String appointmentId) async {
    final String? userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await SupabaseService.client
          .from('chat_messages')
          .update(<String, dynamic>{'delivery_status': 'delivered'})
          .eq('appointment_id', appointmentId)
          .neq('sender_id', userId)
          .eq('delivery_status', 'sent');

      await SupabaseService.client
          .from('chat_messages')
          .update(<String, dynamic>{
            'delivery_status': 'seen',
            'seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('appointment_id', appointmentId)
          .neq('sender_id', userId)
          .neq('delivery_status', 'seen');
    } catch (_) {
      // Keep compatibility with databases that don't have status columns yet.
    }
  }

  void selectChatAppointment(String appointmentId) {
    if (selectedChatAppointmentId.value == appointmentId) {
      return; // Already selected, no need to reload
    }
    selectedChatAppointmentId.value = appointmentId;
    loadMessages();
    _setupRealtimeMessages(); // Ensure real-time listening is active for the new appointment
  }

  Future<void> _insertChatMessage(Map<String, dynamic> payload) async {
    final Map<String, dynamic> withStatus = <String, dynamic>{
      ...payload,
      'delivery_status': 'sent',
    };

    try {
      await SupabaseService.client.from('chat_messages').insert(withStatus);
    } catch (_) {
      await SupabaseService.client.from('chat_messages').insert(payload);
    }
  }

  Future<void> _loadUnreadCounts() async {
    final String? userId = _currentUserId;
    if (userId == null) {
      unreadCountsByAppointment.clear();
      return;
    }

    final List<String> ids = appointments
        .where((PatientAppointment item) => item.chatEnabled)
        .map((PatientAppointment item) => item.id)
        .toList();

    if (ids.isEmpty) {
      unreadCountsByAppointment.clear();
      return;
    }

    final Map<String, int> counts = <String, int>{
      for (final String id in ids) id: 0,
    };

    try {
      List<dynamic> response;
      try {
        response = await SupabaseService.client
            .from('chat_messages')
            .select('appointment_id, sender_id, delivery_status')
            .inFilter('appointment_id', ids)
            .neq('sender_id', userId)
            .neq('delivery_status', 'seen');
      } catch (_) {
        response = await SupabaseService.client
            .from('chat_messages')
            .select('appointment_id, sender_id')
            .inFilter('appointment_id', ids)
            .neq('sender_id', userId);
      }

      for (final dynamic row in response) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final String appointmentId = map['appointment_id']?.toString() ?? '';
        if (counts.containsKey(appointmentId)) {
          counts[appointmentId] = (counts[appointmentId] ?? 0) + 1;
        }
      }

      unreadCountsByAppointment.assignAll(counts);
    } catch (_) {
      // Keep existing counters on transient query failures.
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      Get.snackbar('Error', 'Appointment identifier is missing.');
      return;
    }

    if (!SupabaseService.isConfigured) {
      Get.snackbar('Error', 'Supabase is not configured.');
      return;
    }

    final String? userId = _currentUserId;
    if (userId == null) {
      Get.snackbar('Error', 'User session is missing.');
      return;
    }

    try {
      isLoadingAppointments.value = true;

      final Map<String, dynamic>? appointment = await SupabaseService.client
          .from('appointments')
          .select('id, patient_id, doctor_id, patient_deleted, doctor_deleted')
          .eq('id', appointmentId)
          .maybeSingle();

      if (appointment == null) {
        Get.snackbar('Error', 'Appointment was not found.');
        return;
      }

      final String rowPatientId = appointment['patient_id']?.toString() ?? '';
      final String rowDoctorId = appointment['doctor_id']?.toString() ?? '';
      final bool patientDeleted = appointment['patient_deleted'] == true;
      final bool doctorDeleted = appointment['doctor_deleted'] == true;

      if (rowPatientId != userId) {
        Get.snackbar('Error', 'You can only remove your own appointment records.');
        return;
      }

      if (patientDeleted) {
        Get.snackbar('Info', 'This appointment is already removed from your list.');
        return;
      }

      if (doctorDeleted) {
        await _removeAppointmentResources(appointmentId, rowPatientId, rowDoctorId);

        if (selectedChatAppointmentId.value == appointmentId) {
          selectedChatAppointmentId.value = null;
          messages.clear();
        }

        Get.snackbar(
          'Deleted',
          'Appointment removed permanently after both sides deleted it.',
        );
      } else {
        await SupabaseService.client
            .from('appointments')
            .update(<String, dynamic>{'patient_deleted': true})
            .eq('id', appointmentId)
            .eq('patient_id', userId);

        if (selectedChatAppointmentId.value == appointmentId) {
          selectedChatAppointmentId.value = null;
          messages.clear();
        }

        Get.snackbar(
          'Removed',
          'Appointment removed from your list. The doctor can still access it until they also remove it.',
        );
      }

      await loadAppointments();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove appointment: ${_friendlyError(e)}',
      );
    } finally {
      isLoadingAppointments.value = false;
    }
  }

  Future<void> _removeAppointmentResources(
    String appointmentId,
    String patientId,
    String doctorId,
  ) async {
    final List<String> prefixes = <String>[
      '$patientId/$appointmentId',
      '$doctorId/$appointmentId',
    ];

    for (final String prefix in prefixes) {
      try {
        final List<dynamic> storedFiles = await SupabaseService.client.storage
            .from('medical-files')
            .list(path: prefix);
        if (storedFiles.isNotEmpty) {
          final List<String> removePaths = storedFiles
              .map((dynamic item) => item['name']?.toString())
              .whereType<String>()
              .map((String name) => '$prefix/$name')
              .toList();
          if (removePaths.isNotEmpty) {
            await SupabaseService.client.storage
                .from('medical-files')
                .remove(removePaths);
          }
        }
      } catch (_) {
        // Ignore storage cleanup errors and continue.
      }
    }

    for (final String prefix in prefixes) {
      try {
        await SupabaseService.client
            .from('medical_files')
            .delete()
            .like('file_path', '$prefix/%');
      } catch (_) {
        // Ignore cleanup failures and continue.
      }
    }

    try {
      await SupabaseService.client
          .from('chat_messages')
          .delete()
          .eq('appointment_id', appointmentId);
    } catch (_) {
      // Continue even if chat cleanup fails.
    }

    await SupabaseService.client
        .from('appointments')
        .delete()
        .eq('id', appointmentId);
  }

  Future<void> sendTextMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty || isSendingMessage.value) {
      return;
    }

    final String? appointmentId = selectedChatAppointmentId.value;
    final String? userId = _currentUserId;
    if (appointmentId == null || userId == null) {
      return;
    }

    try {
      isSendingMessage.value = true;
      await _insertChatMessage(<String, dynamic>{
        'appointment_id': appointmentId,
        'sender_id': userId,
        'message_text': text,
      });
      messageController.clear();
      await loadMessages();
    } catch (_) {
      Get.snackbar('Error', 'Failed to send message.');
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> sendAttachment() async {
    if (isUploading.value) {
      return;
    }

    final String? appointmentId = selectedChatAppointmentId.value;
    final String? userId = _currentUserId;
    if (appointmentId == null || userId == null) {
      return;
    }

    PatientAppointment? appt;
    for (final PatientAppointment item in appointments) {
      if (item.id == appointmentId) {
        appt = item;
        break;
      }
    }
    if (appt == null || !appt.chatEnabled) {
      Get.snackbar('Info', 'Doctor must accept appointment before chat/files.');
      return;
    }

    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final PlatformFile file = picked.files.first;
    if (file.bytes == null) {
      Get.snackbar('Error', 'Unable to read selected file.');
      return;
    }

    try {
      isUploading.value = true;
      uploadStatusError.value = false;
      uploadStatusMessage.value = 'Uploading file to secure storage...';
      uploadProgress.value = 0.2;

      final String safeName = file.name.replaceAll(' ', '_');
      final String path =
          '$userId/$appointmentId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      await SupabaseService.client.storage
          .from('medical-files')
          .uploadBinary(path, file.bytes!);
      uploadProgress.value = 0.7;

      await SupabaseService.client
          .from('medical_files')
          .insert(<String, dynamic>{
            'patient_id': userId,
            'doctor_id': appt.doctorId,
            'uploaded_by': userId,
            'file_name': file.name,
            'file_path': path,
            'content_type': file.extension,
          });

      await _insertChatMessage(<String, dynamic>{
        'appointment_id': appointmentId,
        'sender_id': userId,
        'attachment_path': path,
        'attachment_name': file.name,
        'attachment_type': file.extension,
      });

      uploadProgress.value = 1;
      uploadStatusMessage.value =
          'Upload complete. File shared with your doctor.';
      Get.snackbar('Uploaded', 'File sent to doctor in chat.');
      await loadMessages();
    } catch (_) {
      uploadStatusError.value = true;
      uploadStatusMessage.value = 'Upload failed. Please try again.';
      Get.snackbar('Error', 'Failed to upload and send file.');
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0;
    }
  }

  void openImage(ChatMessageItem message) {
    final String? type = message.attachmentType?.toLowerCase();
    if (message.attachmentPath != null &&
        (type == 'jpg' || type == 'jpeg' || type == 'png' || type == 'webp')) {
      Get.toNamed(
        AppRoutes.imageViewer,
        arguments: {
          'path': message.attachmentPath,
          'name': message.attachmentName ?? 'image.jpg',
        },
      );
    }
  }

  Future<void> submitComplaint() async {
    final String title = complaintTitleController.text.trim();
    final String body = complaintBodyController.text.trim();
    if (title.isEmpty || body.isEmpty || isSubmittingComplaint.value) {
      return;
    }

    if (!SupabaseService.isConfigured) {
      Get.snackbar('Info', 'Supabase is not configured.');
      return;
    }

    final String? userId = _currentUserId;
    if (userId == null) {
      return;
    }

    String? doctorId = selectedDoctorId.value;
    if ((doctorId == null || doctorId.isEmpty) && appointments.isNotEmpty) {
      doctorId = appointments.first.doctorId;
    }

    try {
      isSubmittingComplaint.value = true;
      await SupabaseService.client.from('complaints').insert(<String, dynamic>{
        'patient_id': userId,
        'doctor_id': doctorId,
        'title': title,
        'body': body,
      });
      complaintTitleController.clear();
      complaintBodyController.clear();
      Get.snackbar('Sent', 'Complaint sent to admin for review.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to submit complaint.');
    } finally {
      isSubmittingComplaint.value = false;
    }
  }

  Future<void> simulateUpload() async {
    await sendAttachment();
  }
}
