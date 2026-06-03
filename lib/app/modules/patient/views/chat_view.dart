import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/github_theme.dart';
import '../controllers/patient_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final PatientController controller = Get.find<PatientController>();
  PatientAppointment? appointment;

  @override
  void initState() {
    super.initState();
    appointment = Get.arguments as PatientAppointment?;
    if (appointment != null) {
      controller.selectChatAppointment(appointment!.id);
    }
  }

  @override
  void dispose() {
    controller.stopRealtimeMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return Scaffold(
        backgroundColor: GithubTheme.bg,
        appBar: AppBar(
          title: const Text('Chat'),
          elevation: 0,
          backgroundColor: GithubTheme.surface,
          foregroundColor: GithubTheme.textPrimary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        body: const Center(child: Text('No appointment selected')),
      );
    }

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: Text('Chat with ${appointment!.doctor}'),
        elevation: 0,
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'View doctor profile',
            onPressed: () {
              Get.toNamed(
                AppRoutes.publicProfile,
                arguments: <String, dynamic>{'id': appointment!.doctorId},
              );
            },
          ),
          IconButton(
            onPressed: controller.canStartSelectedVideoCall
                ? controller.openSelectedVideoCall
                : null,
            icon: const Icon(Icons.video_call_outlined),
          ),
        ],
      ),
      body: Container(
        color: GithubTheme.bg,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Obx(() {
                if (controller.messagesError.value.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        controller.messagesError.value,
                        style: const TextStyle(color: GithubTheme.danger),
                      ),
                    ),
                  );
                }

                if (controller.isLoadingMessages.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: GithubTheme.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessageItem msg = controller.messages[index];
                    final bool own = controller.isOwnMessage(msg.senderId);
                    return _buildGitHubStyleMessage(msg, own, context);
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: GithubTheme.bg,
                border: Border(
                  top: BorderSide(color: GithubTheme.border, width: 1.0),
                ),
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: GithubTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GithubTheme.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      InkWell(
                        onTap: controller.sendAttachment,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: GithubTheme.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GithubTheme.border),
                          ),
                          child: const Icon(
                            Icons.attach_file,
                            color: GithubTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          style: const TextStyle(
                            color: GithubTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Leave a comment...',
                            hintStyle: const TextStyle(
                              color: GithubTheme.textSecondary,
                            ),
                            filled: true,
                            fillColor: GithubTheme.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: GithubTheme.border,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: GithubTheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          onSubmitted: (_) => controller.sendTextMessage(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GithubTheme.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        onPressed: controller.sendTextMessage,
                        child: const Text(
                          'Comment',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitHubStyleMessage(
    ChatMessageItem msg,
    bool own,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: GithubTheme.surface,
        border: Border.all(
          color: own
              ? GithubTheme.primary.withValues(alpha: 0.5)
              : GithubTheme.border,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GithubTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Message Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: own
                  ? GithubTheme.primary.withValues(alpha: 0.1)
                  : GithubTheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: own
                      ? GithubTheme.primary.withValues(alpha: 0.5)
                      : GithubTheme.border,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      own ? 'You' : 'Doctor',
                      style: const TextStyle(
                        color: GithubTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'commented ${controller.formatMessageTime(msg.createdAt)}',
                      style: const TextStyle(
                        color: GithubTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (own)
                  Builder(
                    builder: (BuildContext context) {
                      final String status = controller.messageStatusFor(msg);
                      final IconData icon =
                          status == 'Seen' || status == 'Delivered'
                          ? Icons.done_all
                          : Icons.done;
                      final Color color = status == 'Seen'
                          ? GithubTheme.primary
                          : GithubTheme.textSecondary;
                      return Icon(icon, size: 14, color: color);
                    },
                  ),
              ],
            ),
          ),
          // Message Body
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if ((msg.message ?? '').isNotEmpty)
                  Text(
                    msg.message!,
                    style: const TextStyle(
                      color: GithubTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                if ((msg.attachmentName ?? '').isNotEmpty)
                  if (_isImage(msg.attachmentType, msg.attachmentName) &&
                      msg.attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          // تأكد من وجود دالة openImage في PatientController
                          // سنمرر البيانات اللازمة لفتح الصورة
                          controller.openImage(msg);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: msg.attachmentPath!,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: GithubTheme.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: CachedNetworkImage(
                                imageUrl: _getAttachmentUrl(
                                  msg.attachmentPath!,
                                ),
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
                                          color: GithubTheme.bg,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
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
                                        color: GithubTheme.bg,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Icons.broken_image,
                                              color: GithubTheme.textSecondary,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    GithubTheme.textSecondary,
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
                    ) // Removed comma here to connect to the 'else' below
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.attach_file,
                            size: 16,
                            color: GithubTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              msg.attachmentName ?? 'Attachment',
                              style: const TextStyle(
                                color: GithubTheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  bool _isImage(String? type, String? filename) {
    final String lowerType = (type ?? '').toLowerCase();
    final String lowerName = (filename ?? '').toLowerCase();
    return lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png') ||
        lowerType.contains('gif') ||
        lowerType.contains('webp') ||
        lowerType.startsWith('image/') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp');
  }

  String _getAttachmentUrl(String path) {
    // للوصول للملفات المحمية، نستخدم مسار authenticated
    final String baseUrl = SupabaseService.supabaseUrl;
    final String authenticatedUrl =
        '$baseUrl/storage/v1/object/authenticated/medical-files/$path';
    debugPrint('Patient Authenticated Image URL: $authenticatedUrl');
    return authenticatedUrl;
  }
}
