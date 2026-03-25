import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  });

  final String id;
  final String senderId;
  final String? message;
  final String? attachmentName;
  final String? attachmentType;
}

class DoctorController extends GetxController {
  final RxList<DoctorPatientItem> queue = <DoctorPatientItem>[
    const DoctorPatientItem(
      appointmentId: 'demo-1',
      patientId: 'demo-p1',
      name: 'Mariam Khaled',
      state: 'Pending',
      scheduledAt: '2026-03-23 10:00',
    ),
    const DoctorPatientItem(
      appointmentId: 'demo-2',
      patientId: 'demo-p2',
      name: 'Yousef Hatem',
      state: 'Accepted',
      scheduledAt: '2026-03-24 12:30',
    ),
    const DoctorPatientItem(
      appointmentId: 'demo-3',
      patientId: 'demo-p3',
      name: 'Nora Adel',
      state: 'Completed',
      scheduledAt: '2026-03-22 09:00',
    ),
  ].obs;

  final RxInt selectedIndex = 0.obs;
  final RxBool isLoadingQueue = false.obs;
  final RxBool isAccepting = false.obs;
  final RxBool isSavingNote = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxString queueError = ''.obs;
  final RxString messagesError = ''.obs;
  final RxString notes =
      '## Clinical Notes\n- Patient reports mild symptoms.\n- Follow-up in 72h.'.obs;
  final TextEditingController messageController = TextEditingController();
  final RxList<DoctorChatMessageItem> messages = <DoctorChatMessageItem>[].obs;
  Timer? _messagePoller;

  DoctorPatientItem? get selectedItem {
    if (queue.isEmpty || selectedIndex.value < 0 || selectedIndex.value >= queue.length) {
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

  @override
  void onInit() {
    super.onInit();
    loadQueue();
    _messagePoller = Timer.periodic(const Duration(seconds: 4), (_) {
      if (selectedAppointmentId.isNotEmpty) {
        loadMessages();
      }
    });
  }

  @override
  void onClose() {
    _messagePoller?.cancel();
    messageController.dispose();
    super.onClose();
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
          .select('id, patient_id, status, scheduled_at, patient:patient_id(full_name)')
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

      if (rows.isNotEmpty) {
        queue.assignAll(rows);
        selectedIndex.value = 0;
        await loadLatestNote();
        await loadMessages();
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
      final List<dynamic> response = await SupabaseService.client
          .from('chat_messages')
          .select('id, sender_id, message_text, attachment_name, attachment_type')
          .eq('appointment_id', selectedAppointmentId)
          .order('created_at', ascending: true)
          .limit(200);

      messages.assignAll(response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        return DoctorChatMessageItem(
          id: map['id']?.toString() ?? '',
          senderId: map['sender_id']?.toString() ?? '',
          message: map['message_text']?.toString(),
          attachmentName: map['attachment_name']?.toString(),
          attachmentType: map['attachment_type']?.toString(),
        );
      }).toList());
    } catch (_) {
      messagesError.value = 'Failed to load chat messages.';
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty || isSendingMessage.value || !SupabaseService.isConfigured) {
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
      await SupabaseService.client.from('chat_messages').insert(
        <String, dynamic>{
          'appointment_id': selectedAppointmentId,
          'sender_id': userId,
          'message_text': text,
        },
      );
      messageController.clear();
      await loadMessages();
    } catch (_) {
      Get.snackbar('Error', 'Failed to send message.');
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> acceptSelectedAppointment() async {
    if (!SupabaseService.isConfigured || selectedItem == null || !selectedItem!.isPending) {
      return;
    }

    try {
      isAccepting.value = true;
      await SupabaseService.client.from('appointments').update(
        <String, dynamic>{'status': 'Accepted'},
      ).eq('id', selectedAppointmentId);

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
      await SupabaseService.client.from('clinical_notes').insert(
        <String, dynamic>{
          'appointment_id': selectedAppointmentId,
          'doctor_id': doctorId,
          'patient_id': selectedPatientId,
          'body': notes.value.trim(),
        },
      );
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
  }

  void openSelectedVideoCall({String? token}) {
    final DoctorPatientItem? appointment = selectedItem;
    if (appointment == null || !appointment.canChat) {
      Get.snackbar('Info', 'Accept appointment first, then start the video call.');
      return;
    }

    Get.toNamed(
      AppRoutes.call,
      arguments: <String, dynamic>{
        'appId': AgoraService.appId,
        'token': AgoraService.resolveToken(token),
        'appointmentId': appointment.appointmentId,
        'channelName': AgoraService.buildAppointmentChannel(appointment.appointmentId),
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
