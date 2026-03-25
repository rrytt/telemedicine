import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/agora/agora_service.dart';
import '../../../routes/app_pages.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorOption {
  const DoctorOption({required this.id, required this.name});

  final String id;
  final String name;
}

class PatientAppointment {
  const PatientAppointment({
    required this.id,
    required this.doctorId,
    required this.doctor,
    required this.time,
    required this.status,
    this.urgent = false,
  });

  final String id;
  final String doctorId;
  final String doctor;
  final String time;
  final String status;
  final bool urgent;

  bool get chatEnabled => status == 'Accepted';
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.senderId,
    this.message,
    this.attachmentName,
    this.attachmentType,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String? message;
  final String? attachmentName;
  final String? attachmentType;
  final DateTime? createdAt;
}

class PatientController extends GetxController {
  final RxList<PatientAppointment> appointments = <PatientAppointment>[
    const PatientAppointment(
      id: 'demo-1',
      doctorId: 'demo-d1',
      doctor: 'Dr. Layan Ahmed - Cardiology',
      time: 'Monday 11:00 AM',
      status: 'Accepted',
    ),
    const PatientAppointment(
      id: 'demo-2',
      doctorId: 'demo-d2',
      doctor: 'Dr. Nader Youssef - Dermatology',
      time: 'Tuesday 4:30 PM',
      status: 'Pending',
      urgent: true,
    ),
    const PatientAppointment(
      id: 'demo-3',
      doctorId: 'demo-d3',
      doctor: 'Dr. Sara Ali - Nutrition',
      time: 'Thursday 9:00 AM',
      status: 'Pending',
    ),
  ].obs;

  final RxList<DoctorOption> doctors = <DoctorOption>[].obs;
  final RxnString selectedDoctorId = RxnString();
  final Rxn<DateTime> selectedDateTime = Rxn<DateTime>();
  final RxBool isBooking = false.obs;

  final TextEditingController messageController = TextEditingController();
  final TextEditingController complaintTitleController = TextEditingController();
  final TextEditingController complaintBodyController = TextEditingController();
  final RxnString selectedChatAppointmentId = RxnString();
  final RxList<ChatMessageItem> messages = <ChatMessageItem>[].obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  Timer? _messagePoller;

  final RxBool isLoadingAppointments = false.obs;
  final RxString appointmentsError = ''.obs;
  final RxString bookingError = ''.obs;
  final RxString messagesError = ''.obs;
  final RxBool isSubmittingComplaint = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  bool get hasAcceptedAppointmentForChat => appointments
      .any((PatientAppointment item) => item.id == selectedChatAppointmentId.value && item.chatEnabled);

  PatientAppointment? get selectedChatAppointment {
    for (final PatientAppointment item in appointments) {
      if (item.id == selectedChatAppointmentId.value) {
        return item;
      }
    }
    return null;
  }

  bool get canStartSelectedVideoCall => selectedChatAppointment?.chatEnabled ?? false;

  bool isOwnMessage(String senderId) => senderId == _currentUserId;

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
    loadAppointments();
    _messagePoller = Timer.periodic(const Duration(seconds: 4), (_) {
      if (selectedChatAppointmentId.value != null) {
        loadMessages();
      }
    });
  }

  @override
  void onClose() {
    _messagePoller?.cancel();
    messageController.dispose();
    complaintTitleController.dispose();
    complaintBodyController.dispose();
    super.onClose();
  }

  Future<void> loadDoctors() async {
    if (!SupabaseService.isConfigured) {
      return;
    }
    try {
      final List<dynamic> response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'doctor')
          .order('full_name', ascending: true)
          .limit(100);

      final List<DoctorOption> list = response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final String name = map['full_name']?.toString() ?? 'Doctor';
        return DoctorOption(id: map['id'].toString(), name: name);
      }).toList();

      doctors.assignAll(list);
      selectedDoctorId.value ??= list.isNotEmpty ? list.first.id : null;
    } catch (_) {
      // Keep silent fallback for demo mode.
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
      await SupabaseService.client.from('appointments').insert(<String, dynamic>{
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
            'id, doctor_id, status, scheduled_at, is_urgent, doctor:doctor_id(full_name)',
          )
          .eq('patient_id', userId)
          .order('scheduled_at', ascending: true)
          .limit(30);

      final List<PatientAppointment> parsed = response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final Map<String, dynamic>? doctor =
            map['doctor'] as Map<String, dynamic>?;

        return PatientAppointment(
          id: map['id']?.toString() ?? '',
          doctorId: map['doctor_id']?.toString() ?? '',
          doctor: (doctor?['full_name']?.toString().isNotEmpty ?? false)
              ? doctor!['full_name'].toString()
              : 'Doctor',
          time: _formatDate(map['scheduled_at']?.toString()),
          status: map['status']?.toString() ?? 'Scheduled',
          urgent: map['is_urgent'] == true,
        );
      }).toList();

      if (parsed.isNotEmpty) {
        appointments.assignAll(parsed);
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

  void selectChatAppointment(String? appointmentId) {
    selectedChatAppointmentId.value = appointmentId;
    loadMessages();
  }

  void openVideoCall(PatientAppointment appointment, {String? token}) {
    if (!appointment.chatEnabled) {
      Get.snackbar('Info', 'Video call becomes available after doctor acceptance.');
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
      final List<dynamic> response = await SupabaseService.client
          .from('chat_messages')
          .select('id, sender_id, message_text, attachment_name, attachment_type, created_at')
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: true)
          .limit(200);

      messages.assignAll(response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        return ChatMessageItem(
          id: map['id']?.toString() ?? '',
          senderId: map['sender_id']?.toString() ?? '',
          message: map['message_text']?.toString(),
          attachmentName: map['attachment_name']?.toString(),
          attachmentType: map['attachment_type']?.toString(),
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
        );
      }).toList());
    } catch (_) {
      messagesError.value = 'Failed to load chat messages.';
    } finally {
      isLoadingMessages.value = false;
    }
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
      await SupabaseService.client.from('chat_messages').insert(<String, dynamic>{
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
      uploadProgress.value = 0.2;

      final String safeName = file.name.replaceAll(' ', '_');
      final String path =
          '$userId/$appointmentId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      await SupabaseService.client.storage
          .from('medical-files')
          .uploadBinary(path, file.bytes!);
      uploadProgress.value = 0.7;

      await SupabaseService.client.from('medical_files').insert(<String, dynamic>{
        'patient_id': userId,
        'doctor_id': appt.doctorId,
        'uploaded_by': userId,
        'file_name': file.name,
        'file_path': path,
        'content_type': file.extension,
      });

      await SupabaseService.client.from('chat_messages').insert(<String, dynamic>{
        'appointment_id': appointmentId,
        'sender_id': userId,
        'attachment_path': path,
        'attachment_name': file.name,
        'attachment_type': file.extension,
      });

      uploadProgress.value = 1;
      Get.snackbar('Uploaded', 'File sent to doctor in chat.');
      await loadMessages();
    } catch (_) {
      Get.snackbar('Error', 'Failed to upload and send file.');
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0;
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
      await SupabaseService.client.from('complaints').insert(
        <String, dynamic>{
          'patient_id': userId,
          'doctor_id': doctorId,
          'title': title,
          'body': body,
        },
      );
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
