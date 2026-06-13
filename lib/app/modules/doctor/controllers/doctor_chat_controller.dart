import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String patientName = 'Patient';
  String appointmentId = '';
  String patientId = '';

  final RxBool isSending = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  StreamSubscription? _messagesSubscription;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      patientName = Get.arguments['patientName'] ?? 'Patient';
      appointmentId = Get.arguments['appointmentId'] ?? '';
      patientId = Get.arguments['patientId'] ?? '';
      _subscribeToMessages();
      _markAsSeen();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    _messagesSubscription?.cancel();
    super.onClose();
  }

  void _subscribeToMessages() {
    if (appointmentId.isEmpty) return;

    _messagesSubscription = SupabaseService.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: true)
        .listen((data) {
      messages.assignAll(data);
      _markAsSeen();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markAsSeen() async {
    if (appointmentId.isEmpty) return;
    final String? userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client
          .from('chat_messages')
          .update({
            'delivery_status': 'seen',
            'seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('appointment_id', appointmentId)
          .neq('sender_id', userId)
          .neq('delivery_status', 'seen');
    } catch (_) {}
  }

  Future<void> sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty || appointmentId.isEmpty || isSending.value) return;

    final String? senderId = SupabaseService.client.auth.currentUser?.id;
    if (senderId == null) return;

    isSending.value = true;
    messageController.clear();

    try {
      await SupabaseService.client.from('chat_messages').insert({
        'appointment_id': appointmentId,
        'sender_id': senderId,
        'message_text': text,
        'delivery_status': 'sent',
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendAttachment() async {
    if (isUploading.value || appointmentId.isEmpty || patientId.isEmpty) return;

    final String? userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (picked == null || picked.files.isEmpty) return;
    final PlatformFile file = picked.files.first;
    if (file.bytes == null) return;

    try {
      isUploading.value = true;
      uploadProgress.value = 0.2;

      final String safeName = file.name.replaceAll(' ', '_');
      final String path = '$userId/$appointmentId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      // رفع الملف إلى التخزين (Storage)
      await SupabaseService.client.storage
          .from('medical-files')
          .uploadBinary(path, file.bytes!);
      
      uploadProgress.value = 0.6;

      // تسجيل الملف في قاعدة البيانات لتفعيل صلاحية RLS
      await SupabaseService.client.from('medical_files').insert({
        'patient_id': patientId,
        'doctor_id': userId,
        'uploaded_by': userId,
        'file_name': file.name,
        'file_path': path,
        'content_type': file.extension,
      });

      uploadProgress.value = 0.8;

      // إرسال الملف كرسالة في المحادثة
      await SupabaseService.client.from('chat_messages').insert({
        'appointment_id': appointmentId,
        'sender_id': userId,
        'attachment_path': path,
        'attachment_name': file.name,
        'attachment_type': file.extension,
        'delivery_status': 'sent',
      });

      uploadProgress.value = 1.0;
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload attachment: $e');
    } finally {
      isUploading.value = false;
      Future.delayed(const Duration(seconds: 1), () => uploadProgress.value = 0);
    }
  }

  bool isMe(String? senderId) {
    return senderId == SupabaseService.client.auth.currentUser?.id;
  }

  Future<void> openImage(Map<String, dynamic> message) async {
    final String? path = message['attachment_path']?.toString();
    final String? name = message['attachment_name']?.toString();
    final String? type = message['attachment_type']?.toString().toLowerCase().replaceAll('.', '');
    
    const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'];
    const videoExtensions = ['mp4', 'mov', 'avi'];

    if (path == null) return;

    if (imageExtensions.contains(type)) {
      try {
        // توليد رابط موقّع لأن التخزين خاص (Private Storage)
        final String signedUrl = await SupabaseService.client.storage
            .from('medical-files')
            .createSignedUrl(path, 3600); // صالح لمدة ساعة

        debugPrint('Generated Signed URL: $signedUrl');

        Get.toNamed(AppRoutes.imageViewer, arguments: {
          'url': signedUrl,
          'path': path,
          'name': name ?? 'image.jpg',
        });
      } catch (e) {
        debugPrint('Error generating signed URL: $e');
        Get.snackbar('خطأ', 'ليس لديك صلاحية الوصول لهذه الصورة');
      }
    } else if (videoExtensions.contains(type)) {
      // هنا يمكن إضافة توجيه لشاشة مشغل الفيديو مستقبلاً
      Get.snackbar('Video', 'Video player integration coming soon');
    } else {
      Get.snackbar('File', 'Opening $type files is not supported yet');
    }
  }

  Future<void> closeSession() async {
    if (appointmentId.isEmpty) return;

    try {
      await SupabaseService.client
          .from('appointments')
          .update({'status': 'Completed'})
          .eq('id', appointmentId);
      Get.back(); // العودة للشاشة السابقة
      Get.snackbar('Session Closed', 'The session has been closed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to close session: $e');
    }
  }
}