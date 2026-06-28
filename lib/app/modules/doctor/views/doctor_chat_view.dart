import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/supabase/supabase_service.dart';
import '../controllers/doctor_controller.dart';
import '../doctor_theme.dart';

class DoctorChatView extends GetView<DoctorController> {
  const DoctorChatView({super.key});

  Color get bgColor => DoctorStyles.surface;
  Color get cardColor => DoctorStyles.surface;
  Color get borderColor => DoctorStyles.border;
  Color get textPrimary => DoctorStyles.textPrimary;
  Color get textSecondary => DoctorStyles.textSecondary;
  Color get accentBlue => DoctorStyles.blue;
  Color get successGreen => DoctorStyles.success;
  Color get headerColor => DoctorStyles.surface;
  Color get dangerRed => DoctorStyles.danger;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.1),
                border: Border.all(color: successGreen.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.adjust, size: 14, color: successGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Open',
                    style: TextStyle(
                      color: successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              controller.selectedPatientName,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: textPrimary, size: 26),
            tooltip: 'View patient profile',
            onPressed: () {
              final String patientId = controller.selectedPatientId;
              if (patientId.isEmpty) {
                Get.snackbar('Error', 'Patient id missing');
                return;
              }
              Get.toNamed(
                '/profile/view',
                arguments: <String, dynamic>{'id': patientId},
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.video_call, color: successGreen, size: 26),
            tooltip: 'Start Video Call',
            onPressed: () async {
              if (controller.selectedAppointmentId.isEmpty) {
                Get.snackbar('Error', 'Appointment ID is missing');
                return;
              }

              // Check if appointment is accepted
              try {
                final response = await SupabaseService.client
                    .from('appointments')
                    .select('status')
                    .eq('id', controller.selectedAppointmentId)
                    .single();

                final String status = response['status']?.toString() ?? '';
                if (status != 'Accepted' && status != 'Completed') {
                  Get.snackbar(
                    'Error',
                    'Video call is only available for accepted appointments',
                  );
                  return;
                }

                controller.openSelectedVideoCall();
              } catch (e) {
                Get.snackbar('Error', 'Failed to check appointment status: $e');
              }
            },
          ),
          const SizedBox(width: 8),
          Obx(
            () => controller.isClosingSession.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(Icons.close, color: dangerRed, size: 26),
                    tooltip: 'Close Session',
                    onPressed: () => _showCloseSessionDialog(context),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Clinical Notes Section
          Container(
            margin: EdgeInsets.only(bottom: 12.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Clinical Notes',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => controller.isSavingNote.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: Icon(Icons.save, color: successGreen),
                              onPressed: () => controller.saveClinicalNote(),
                              tooltip: 'Save Notes',
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.noteController,
                  onChanged: (value) => controller.notes.value = value,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter clinical notes...',
                    hintStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentBlue),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  style: TextStyle(color: textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Documents Section
          Container(
            margin: EdgeInsets.only(bottom: 12.0),
            padding: EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Medical Files',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.attach_file, color: accentBlue),
                      onPressed: () => controller.sendAttachment(),
                      tooltip: 'Upload File',
                    ),
                  ],
                ),
                Obx(() {
                  if (controller.documents.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No files uploaded yet',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.documents.length,
                      itemBuilder: (context, index) {
                        final doc = controller.documents[index];
                        return Container(
                          width: 120,
                          height: double.infinity,
                          margin: EdgeInsets.only(right: 8.0),
                          padding: EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: textSecondary,
                                size: 16,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 9,
                                ),
                              ),
                              Text(
                                doc.uploadedAt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Chat Messages Section
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messagesError.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      controller.messagesError.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                );
              }
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  final bool isMe = controller.isOwnMessage(msg.senderId);
                  return _buildGitHubStyleMessage(
                    sender: isMe
                        ? 'Doctor (You)'
                        : controller.selectedPatientName,
                    message: msg.message ?? '',
                    time: controller.formatMessageTime(msg.createdAt),
                    isMe: isMe,
                    status: controller.messageStatusFor(msg),
                    msg: msg,
                    attachmentType: msg.attachmentType,
                    attachmentPath: msg.attachmentPath,
                  );
                },
              );
            }),
          ),

          // Message Input Section
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildGitHubStyleMessage({
    required String sender,
    required String message,
    required String time,
    required bool isMe,
    String? status,
    required DoctorChatMessageItem msg,
    String? attachmentType,
    String? attachmentPath,
  }) {
    final String? attachmentName = msg.attachmentName;
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: isMe ? accentBlue.withValues(alpha: 0.5) : borderColor,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? accentBlue.withValues(alpha: 0.1)
                  : headerColor.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: isMe ? accentBlue.withValues(alpha: 0.5) : borderColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sender,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status != null && status.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: successGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: successGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (status != null && status.isNotEmpty)
                      const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                if (attachmentName != null && attachmentName.isNotEmpty)
                  if (_isImage(attachmentType, attachmentName) &&
                      attachmentPath != null)
                    GestureDetector(
                      onTap: () => controller.openImage(msg),
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Hero(
                            tag: attachmentPath,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: _getAttachmentUrl(attachmentPath),
                                httpHeaders: {
                                  'Authorization':
                                      'Bearer ${SupabaseService.client.auth.currentSession?.accessToken ?? ""}',
                                  'apikey': SupabaseService.anonKey,
                                },
                                width: 250,
                                fit: BoxFit.cover,
                                placeholder:
                                    (BuildContext context, String url) =>
                                        Container(
                                          width: 250,
                                          height: 200,
                                          color: bgColor,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: accentBlue,
                                            ),
                                          ),
                                        ),
                                errorWidget:
                                    (
                                      BuildContext context,
                                      String url,
                                      dynamic error,
                                    ) {
                                      return Container(
                                        width: 250,
                                        height: 200,
                                        color: bgColor,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: textSecondary,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, color: accentBlue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            attachmentName,
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload status
            Obx(() {
              if (controller.uploadStatusMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: EdgeInsets.only(bottom: 8.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: controller.uploadStatusError.value
                      ? dangerRed.withValues(alpha: 0.1)
                      : successGreen.withValues(alpha: 0.1),
                  border: Border.all(
                    color: controller.uploadStatusError.value
                        ? dangerRed
                        : successGreen,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.uploadStatusError.value
                          ? Icons.error
                          : Icons.check_circle,
                      color: controller.uploadStatusError.value
                          ? dangerRed
                          : successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.uploadStatusMessage.value,
                        style: TextStyle(
                          color: controller.uploadStatusError.value
                              ? dangerRed
                              : successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (controller.isUploading.value)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: controller.uploadProgress.value,
                        ),
                      ),
                  ],
                ),
              );
            }),

            TextField(
              controller: controller.messageController,
              style: TextStyle(color: textPrimary),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Leave a comment...',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: bgColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: accentBlue),
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => controller.sendAttachment(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(Icons.attach_file, color: textSecondary),
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.not_interested,
                        color: dangerRed,
                        size: 16,
                      ),
                      onPressed: () => _showCloseSessionDialog(Get.context!),
                      label: Text(
                        'Close session',
                        style: TextStyle(
                          color: dangerRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => controller.isSendingMessage.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => controller.sendMessage(),
                              child: const Text(
                                'Comment',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseSessionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text('Close Session', style: TextStyle(color: textPrimary)),
        content: Text(
          'Are you sure you want to close this appointment session? This action cannot be undone.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.closeCurrentSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }

  bool _isImage(String? type, String? filename) {
    final List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (type != null) {
      final lowerType = type.toLowerCase().replaceAll('.', '');
      if (lowerType.startsWith('image/') ||
          imageExtensions.contains(lowerType)) {
        return true;
      }
    }
    if (filename != null) {
      final lowerFilename = filename.toLowerCase();
      return lowerFilename.endsWith('.jpg') ||
          lowerFilename.endsWith('.jpeg') ||
          lowerFilename.endsWith('.png') ||
          lowerFilename.endsWith('.gif') ||
          lowerFilename.endsWith('.webp');
    }
    return false;
  }

  String _getAttachmentUrl(String path) {
    // للوصول للملفات المحمية بـ RLS، يجب استخدام مسار 'authenticated' بدلاً من 'public'
    final String baseUrl = SupabaseService.supabaseUrl;
    final String authenticatedUrl =
        '$baseUrl/storage/v1/object/authenticated/medical-files/$path';

    debugPrint('Authenticated Image URL: $authenticatedUrl');
    return authenticatedUrl;
  }
}
