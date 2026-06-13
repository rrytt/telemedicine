import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/agora/agora_service.dart';
import '../../../routes/app_pages.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorPatientItem {
  const DoctorPatientItem({
    required this.appointmentId,
    required this.patientId,
    required this.name,
    required this.state,
    required this.scheduledAt,
    this.avatarUrl,
  });

  final String appointmentId;
  final String patientId;
  final String name;
  final String state;
  final String scheduledAt;
  final String? avatarUrl;

  bool get canChat => state == 'Accepted' || state == 'Completed';
  bool get isPending => state == 'Pending';
}

class DoctorChatMessageItem {
  const DoctorChatMessageItem({
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

class DoctorDocumentItem {
  const DoctorDocumentItem({
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final String fileName;
  final String fileType;
  final String uploadedAt;
  final String uploadedBy;
}

class DoctorController extends GetxController {
  final RxList<DoctorPatientItem> queue = <DoctorPatientItem>[].obs;

  final RxInt selectedIndex = 0.obs;
  final RxBool isLoadingQueue = false.obs;
  final RxBool isAccepting = false.obs;
  final RxBool isRejecting = false.obs;
  final RxBool isClosingSession = false.obs;
  final RxBool isSavingNote = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isUploading = false.obs;
  final RxString queueError = ''.obs;
  final RxString messagesError = ''.obs;
  final RxString uploadStatusMessage = ''.obs;
  final RxBool uploadStatusError = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString notes = ''.obs;
  final RxString processingAppointmentId = ''.obs;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final RxList<DoctorChatMessageItem> messages = <DoctorChatMessageItem>[].obs;
  final RxMap<String, int> unreadCountsByAppointment = <String, int>{}.obs;
  final RxList<DoctorDocumentItem> documents = <DoctorDocumentItem>[].obs;
  RealtimeChannel? _messagesChannel;

  DoctorPatientItem? get selectedItem {
    if (queue.isEmpty ||
        selectedIndex.value < 0 ||
        selectedIndex.value >= queue.length) {
      return null;
    }
    return queue[selectedIndex.value];
  }

  String get selectedPatientName => selectedItem?.name ?? 'No patient';
  String get selectedAppointmentId => selectedItem?.appointmentId ?? '';
  String get selectedPatientId => selectedItem?.patientId ?? '';
  String? get selectedPatientAvatarUrl => selectedItem?.avatarUrl;
  bool get canReplyToSelectedPatient => selectedItem?.canChat ?? false;
  bool get canStartVideoCall => selectedItem?.canChat ?? false;
  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;
  String get userId => _currentUserId ?? '';

  bool isOwnMessage(String senderId) => senderId == _currentUserId;

  int unreadForAppointment(String appointmentId) =>
      unreadCountsByAppointment[appointmentId] ?? 0;

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

  String formatMessageTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final DateTime local = value.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String messageStatusFor(DoctorChatMessageItem message) {
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
      (DoctorChatMessageItem m) => m.id == message.id,
    );
    if (index != -1) {
      final bool seenByReply = messages
          .skip(index + 1)
          .any((DoctorChatMessageItem m) => !isOwnMessage(m.senderId));
      if (seenByReply) {
        return 'Seen';
      }
    }
    return 'Delivered';
  }

  @override
  void onInit() {
    super.onInit();
    loadQueue();
    _setupRealtimeMessages();
  }

  @override
  void onClose() {
    if (_messagesChannel != null) {
      SupabaseService.client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
    messageController.dispose();
    noteController.dispose();
    super.onClose();
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
        'doctor-chat-${_currentUserId ?? DateTime.now().millisecondsSinceEpoch}';
    _messagesChannel = SupabaseService.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (PostgresChangePayload payload) {
            final String selected = selectedAppointmentId;
            if (selected.isEmpty) {
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

  Future<void> loadQueue() async {
    queueError.value = '';
    if (!SupabaseService.isConfigured) {
      return;
    }

    final String? doctorId = SupabaseService.client.auth.currentUser?.id;
    if (doctorId == null) {
      queueError.value = 'User session is missing.';
      return;
    }

    try {
      isLoadingQueue.value = true;
      final List<dynamic> response = await SupabaseService.client
          .from('appointments')
          .select(
            'id, patient_id, status, scheduled_at, patient:patient_id(full_name, avatar_url)',
          )
          .eq('doctor_id', doctorId)
          .eq('doctor_deleted', false)
          .order('scheduled_at', ascending: true)
          .limit(50);

      final List<DoctorPatientItem> rows = await Future.wait(
        response.map<Future<DoctorPatientItem>>(
          (dynamic row) async {
            final Map<String, dynamic> map = row as Map<String, dynamic>;
            final Map<String, dynamic>? patient =
                map['patient'] as Map<String, dynamic>?;
            final String avatarPath = patient?['avatar_url']?.toString() ?? '';
            final String avatarUrl = avatarPath.isNotEmpty
                ? await _createSignedAvatarUrl(avatarPath)
                : '';

            return DoctorPatientItem(
              appointmentId: map['id']?.toString() ?? '',
              patientId: map['patient_id']?.toString() ?? '',
              name: (patient?['full_name']?.toString().isNotEmpty ?? false)
                  ? patient!['full_name'].toString()
                  : 'Patient',
              state: map['status']?.toString() ?? 'Pending',
              scheduledAt: _formatDate(map['scheduled_at']?.toString()),
              avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            );
          },
        ),
      );

      queue.assignAll(rows);
      if (rows.isNotEmpty) {
        selectedIndex.value = 0;
        await loadLatestNote();
        await loadMessages();
        await loadDocuments();
        await _loadUnreadCounts();
      } else {
        selectedIndex.value = 0;
        notes.value = '';
        messages.clear();
        documents.clear();
        unreadCountsByAppointment.clear();
      }
    } catch (_) {
      queueError.value = 'Failed to load patient queue from Supabase.';
    } finally {
      isLoadingQueue.value = false;
    }
  }

  Future<void> loadLatestNote() async {
    if (!SupabaseService.isConfigured || selectedAppointmentId.isEmpty) {
      return;
    }

    try {
      final dynamic row = await SupabaseService.client
          .from('clinical_notes')
          .select('body')
          .eq('appointment_id', selectedAppointmentId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row is Map<String, dynamic> && row['body'] != null) {
        notes.value = row['body'].toString();
        noteController.text = notes.value;
      }
    } catch (_) {
      // Keep current text if no note is found.
    }
  }

  Future<void> loadMessages() async {
    messagesError.value = '';
    if (!SupabaseService.isConfigured || selectedAppointmentId.isEmpty) {
      return;
    }

    if (!canReplyToSelectedPatient) {
      messages.clear();
      messagesError.value =
          'Accept appointment first, then you can chat with the patient.';
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
            .eq('appointment_id', selectedAppointmentId)
            .order('created_at', ascending: true)
            .limit(200);
      } catch (_) {
        response = await SupabaseService.client
            .from('chat_messages')
            .select(
              'id, sender_id, message_text, attachment_name, attachment_type, attachment_path, created_at',
            )
            .eq('appointment_id', selectedAppointmentId)
            .order('created_at', ascending: true)
            .limit(200);
      }

      messages.assignAll(
        response.map((dynamic row) {
          final Map<String, dynamic> map = row as Map<String, dynamic>;
          return DoctorChatMessageItem(
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

      await _markIncomingDeliveredAndSeen(selectedAppointmentId);
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

    final List<String> ids = queue
        .where((DoctorPatientItem item) => item.canChat)
        .map((DoctorPatientItem item) => item.appointmentId)
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

  Future<void> loadDocuments() async {
    if (!SupabaseService.isConfigured || selectedPatientId.isEmpty) {
      documents.clear();
      return;
    }

    try {
      final List<dynamic> response = await SupabaseService.client
          .from('medical_files')
          .select('file_name, content_type, created_at, uploaded_by')
          .eq('patient_id', selectedPatientId)
          .eq(
            'doctor_id',
            SupabaseService.client.auth.currentUser?.id as Object,
          )
          .order('created_at', ascending: false)
          .limit(15);

      documents.assignAll(
        response.map((dynamic row) {
          final Map<String, dynamic> map = row as Map<String, dynamic>;
          final String uploadedBy = map['uploaded_by']?.toString() ?? '';
          return DoctorDocumentItem(
            fileName: map['file_name']?.toString() ?? 'Unknown file',
            fileType: map['content_type']?.toString() ?? 'file',
            uploadedAt: _formatDate(map['created_at']?.toString()),
            uploadedBy: uploadedBy == selectedPatientId ? 'Patient' : 'Doctor',
          );
        }).toList(),
      );
    } catch (_) {
      documents.clear();
    }
  }

  Future<void> sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty ||
        isSendingMessage.value ||
        !SupabaseService.isConfigured) {
      return;
    }

    if (!canReplyToSelectedPatient) {
      Get.snackbar('Info', 'Accept appointment first, then send reply.');
      return;
    }

    final String? userId = _currentUserId;
    if (userId == null || selectedAppointmentId.isEmpty) {
      return;
    }

    try {
      isSendingMessage.value = true;
      await _insertChatMessage(<String, dynamic>{
        'appointment_id': selectedAppointmentId,
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
    if (isUploading.value || !SupabaseService.isConfigured) {
      return;
    }

    if (!canReplyToSelectedPatient) {
      Get.snackbar('Info', 'Accept appointment first, then send attachments.');
      return;
    }

    final String appointmentId = selectedAppointmentId;
    final String? userId = _currentUserId;
    if (appointmentId.isEmpty || userId == null) {
      return;
    }

    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.image,
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
      uploadStatusMessage.value = 'Uploading attachment...';
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
            'patient_id': selectedPatientId,
            'doctor_id': SupabaseService.client.auth.currentUser?.id,
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

      uploadProgress.value = 1.0;
      uploadStatusMessage.value = 'Attachment sent.';
      await loadMessages();
    } catch (_) {
      uploadStatusError.value = true;
      uploadStatusMessage.value = 'Failed uploading attachment.';
      Get.snackbar('Error', 'Failed to upload attachment.');
    } finally {
      isUploading.value = false;
      Future<void>.delayed(const Duration(seconds: 2), () {
        uploadStatusMessage.value = '';
        uploadProgress.value = 0;
      });
    }
  }

  Future<void> acceptAppointment(int index) async {
    selectedIndex.value = index;
    await acceptSelectedAppointment();
  }

  Future<void> rejectAppointment(int index) async {
    selectedIndex.value = index;
    await rejectSelectedAppointment();
  }

  Future<void> acceptSelectedAppointment() async {
    if (!SupabaseService.isConfigured ||
        selectedItem == null ||
        !selectedItem!.isPending) {
      return;
    }

    final String appointmentId = selectedAppointmentId;
    if (appointmentId.isEmpty) {
      return;
    }

    try {
      processingAppointmentId.value = appointmentId;
      isAccepting.value = true;
      await SupabaseService.client
          .from('appointments')
          .update(<String, dynamic>{'status': 'Accepted'})
          .eq('id', appointmentId);

      await loadQueue();
      Get.snackbar('Accepted', 'Appointment accepted. Chat is now active.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to accept appointment.');
    } finally {
      isAccepting.value = false;
      processingAppointmentId.value = '';
    }
  }

  Future<void> rejectSelectedAppointment() async {
    if (!SupabaseService.isConfigured ||
        selectedItem == null ||
        !selectedItem!.isPending) {
      return;
    }

    final String appointmentId = selectedAppointmentId;
    if (appointmentId.isEmpty) {
      return;
    }

    try {
      processingAppointmentId.value = appointmentId;
      isRejecting.value = true;
      await SupabaseService.client
          .from('appointments')
          .update(<String, dynamic>{'status': 'Rejected'})
          .eq('id', appointmentId);

      await loadQueue();
      Get.snackbar('Rejected', 'Appointment rejected successfully.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to reject appointment.');
    } finally {
      isRejecting.value = false;
      processingAppointmentId.value = '';
    }
  }
  
  Future<void> hideAppointment(int index) async {
    if (index < 0 || index >= queue.length) {
      return;
    }
    selectedIndex.value = index;
    await hideSelectedAppointment();
  }

  Future<void> hideSelectedAppointment() async {
    if (!SupabaseService.isConfigured || selectedAppointmentId.isEmpty) {
      return;
    }

    final String appointmentId = selectedAppointmentId;
    final String? doctorId = _currentUserId;
    if (doctorId == null) {
      Get.snackbar('Error', 'User session is missing.');
      return;
    }

    try {
      isLoadingQueue.value = true;
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

      if (rowDoctorId != doctorId) {
        Get.snackbar('Error', 'You can only remove your own appointment records.');
        return;
      }

      if (doctorDeleted) {
        Get.snackbar('Info', 'This appointment is already removed from your list.');
        return;
      }

      if (patientDeleted) {
        await _removeAppointmentResources(appointmentId, rowPatientId, rowDoctorId);
        Get.snackbar(
          'Deleted',
          'Appointment removed permanently after both sides deleted it.',
        );
      } else {
        await SupabaseService.client
            .from('appointments')
            .update(<String, dynamic>{'doctor_deleted': true})
            .eq('id', appointmentId)
            .eq('doctor_id', doctorId);
        Get.snackbar(
          'Removed',
          'Appointment removed from your list. The patient can still access it until they also remove it.',
        );
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to remove appointment.');
    } finally {
      await loadQueue();
      isLoadingQueue.value = false;
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

  Future<void> closeCurrentSession() async {
    if (!SupabaseService.isConfigured || selectedAppointmentId.isEmpty) {
      return;
    }

    try {
      isClosingSession.value = true;
      await SupabaseService.client
          .from('appointments')
          .update(<String, dynamic>{'status': 'Completed'})
          .eq('id', selectedAppointmentId);

      // Clear current session data
      messages.clear();
      notes.value = '';
      noteController.clear();
      documents.clear();
      unreadCountsByAppointment[selectedAppointmentId] = 0;

      await loadQueue();
      Get.back(); // Navigate back to dashboard
      Get.snackbar('Session Closed', 'The appointment session has been completed.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to close session.');
    } finally {
      isClosingSession.value = false;
    }
  }

  Future<void> saveClinicalNote() async {
    if (!SupabaseService.isConfigured) {
      Get.snackbar('Info', 'Supabase is not configured.');
      return;
    }

    final String? doctorId = SupabaseService.client.auth.currentUser?.id;
    if (doctorId == null || selectedAppointmentId.isEmpty) {
      return;
    }

    try {
      isSavingNote.value = true;
      await SupabaseService.client
          .from('clinical_notes')
          .insert(<String, dynamic>{
            'appointment_id': selectedAppointmentId,
            'doctor_id': doctorId,
            'patient_id': selectedPatientId,
            'body': notes.value.trim(),
          });
      Get.snackbar('Saved', 'Clinical note saved successfully.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to save clinical note.');
    } finally {
      isSavingNote.value = false;
    }
  }

  void pickPatient(int index) {
    selectedIndex.value = index;
    loadLatestNote();
    loadMessages();
    loadDocuments();
  }

  void openSelectedVideoCall({String? token}) {
    final DoctorPatientItem? appointment = selectedItem;
    if (appointment == null || !appointment.canChat) {
      Get.snackbar(
        'Info',
        'Accept appointment first, then start the video call.',
      );
      return;
    }

    Get.toNamed(
      AppRoutes.call,
      arguments: <String, dynamic>{
        'appId': AgoraService.appId,
        'token': AgoraService.resolveToken(token),
        'appointmentId': appointment.appointmentId,
        'channelName': AgoraService.buildAppointmentChannel(
          appointment.appointmentId,
        ),
      },
    );
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

  void openImage(DoctorChatMessageItem message) {
    final String? type = message.attachmentType?.toLowerCase();
    if (message.attachmentPath != null &&
        (type == 'jpg' || type == 'jpeg' || type == 'png' || type == 'webp' || type == 'gif')) {
      Get.toNamed(
        AppRoutes.imageViewer,
        arguments: {
          'path': message.attachmentPath,
          'name': message.attachmentName ?? 'image.jpg',
        },
      );
    }
  }
}
