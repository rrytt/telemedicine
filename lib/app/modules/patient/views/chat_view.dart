import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../theme/github_theme.dart';
import '../controllers/patient_controller.dart';

class ChatView extends GetView<PatientController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientAppointment? appointment = Get.arguments as PatientAppointment?;

    if (appointment != null) {
      controller.selectChatAppointment(appointment.id);
    }

    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('No appointment selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${appointment.doctor}'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.canStartSelectedVideoCall
                ? controller.openSelectedVideoCall
                : null,
            icon: const Icon(Icons.video_call_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDE5DD),
        ),
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
                        style: const TextStyle(
                          color: Color(0xFFCF222E),
                        ),
                      ),
                    ),
                  );
                }

                if (controller.isLoadingMessages.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(
                        color: GithubTheme.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: controller.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessageItem msg = controller.messages[index];
                    final bool own = controller.isOwnMessage(msg.senderId);
                    return Align(
                      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: own ? const Color(0xFFDCF8C6) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if ((msg.message ?? '').isNotEmpty) Text(msg.message!),
                              if ((msg.attachmentName ?? '').isNotEmpty)
                                if (_isImage(msg.attachmentType))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Image.network(
                                      _getAttachmentUrl(msg.attachmentPath!),
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          color: Colors.grey[200],
                                          child: const Center(child: CircularProgressIndicator()),
                                        );
                                      },
                                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Attachment: ${msg.attachmentName} (${msg.attachmentType ?? '-'})',
                                            style: const TextStyle(
                                              color: Color(0xFF0B57D0),
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Attachment: ${msg.attachmentName} (${msg.attachmentType ?? '-'})',
                                      style: const TextStyle(
                                        color: Color(0xFF0B57D0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      controller.formatMessageTime(msg.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: GithubTheme.textSecondary,
                                      ),
                                    ),
                                    if (own) ...<Widget>[
                                      const SizedBox(width: 5),
                                      Builder(
                                        builder: (BuildContext context) {
                                          final String status = controller.messageStatusFor(msg);
                                          final IconData icon = status == 'Seen' || status == 'Delivered'
                                              ? Icons.done_all
                                              : Icons.done;
                                          final Color color = status == 'Seen'
                                              ? const Color(0xFF34B7F1)
                                              : GithubTheme.textSecondary;
                                          return Icon(icon, size: 14, color: color);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: controller.sendAttachment,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => controller.sendTextMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.sendTextMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImage(String? type) {
    if (type == null) return false;
    final String lowerType = type.toLowerCase();
    return lowerType == 'jpg' || lowerType == 'jpeg' || lowerType == 'png' || lowerType == 'gif' || lowerType == 'webp';
  }

  String _getAttachmentUrl(String path) {
    return SupabaseService.client.storage.from('medical-files').getPublicUrl(path);
  }
}