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
  });

  final String appointmentId;
  final String patientId;
  final String name;
  final String state;
  final String scheduledAt;

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
    this.deliveryStatus,
    this.seenAt,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String? message;
  final String? attachmentName;
  final String? attachmentType;
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
  final RxBool isSavingNote = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxString queueError = ''.obs;
  final RxString messagesError = ''.obs;
  final RxString notes = ''.obs;
  final TextEditingController messageController = TextEditingController();
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
  bool get canReplyToSelectedPatient => selectedItem?.canChat ?? false;
  bool get canStartVideoCall => selectedItem?.canChat ?? false;
  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

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
            'id, patient_id, status, scheduled_at, patient:patient_id(full_name)',
          )
          .eq('doctor_id', doctorId)
          .order('scheduled_at', ascending: true)
          .limit(50);

      final List<DoctorPatientItem> rows = response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final Map<String, dynamic>? patient =
            map['patient'] as Map<String, dynamic>?;

        return DoctorPatientItem(
          appointmentId: map['id']?.toString() ?? '',
          patientId: map['patient_id']?.toString() ?? '',
          name: (patient?['full_name']?.toString().isNotEmpty ?? false)
              ? patient!['full_name'].toString()
              : 'Patient',
          state: map['status']?.toString() ?? 'Pending',
          scheduledAt: _formatDate(map['scheduled_at']?.toString()),
        );
      }).toList();

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
              'id, sender_id, message_text, attachment_name, attachment_type, delivery_status, seen_at, created_at',
            )
            .eq('appointment_id', selectedAppointmentId)
            .order('created_at', ascending: true)
            .limit(200);
      } catch (_) {
        response = await SupabaseService.client
            .from('chat_messages')
            .select(
              'id, sender_id, message_text, attachment_name, attachment_type, created_at',
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

  Future<void> acceptSelectedAppointment() async {
    if (!SupabaseService.isConfigured ||
        selectedItem == null ||
        !selectedItem!.isPending) {
      return;
    }

    try {
      isAccepting.value = true;
      await SupabaseService.client
          .from('appointments')
          .update(<String, dynamic>{'status': 'Accepted'})
          .eq('id', selectedAppointmentId);

      await loadQueue();
      Get.snackbar('Accepted', 'Appointment accepted. Chat is now active.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to accept appointment.');
    } finally {
      isAccepting.value = false;
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
}
