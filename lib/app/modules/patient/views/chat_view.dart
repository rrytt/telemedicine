import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../patient_theme.dart';
import '../controllers/patient_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  PatientController get controller => Get.find<PatientController>();

  @override
  void initState() {
    super.initState();
    controller.loadMessages();
  }



  void _sendMessage() {
    final text = controller.messageController.text.trim();
    if (text.isEmpty) return;
    controller.sendTextMessage();
  }

  @override
  Widget build(BuildContext context) {
    final PatientAppointment? appt = controller.selectedChatAppointment;
    final String doctorName = appt?.doctor ?? 'Doctor';

    return Scaffold(
      backgroundColor: PatientStyles.surface,
      appBar: AppBar(
        backgroundColor: PatientStyles.teal,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          'Dr. $doctorName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.openSelectedVideoCall,
            icon: const Icon(Icons.videocam, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              final appt = controller.selectedChatAppointment;
              if (appt != null) {
                Get.toNamed(
                  AppRoutes.publicProfile,
                  arguments: <String, dynamic>{'id': appt.doctorId},
                );
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messagesError.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.messagesError.value,
                    style: TextStyle(color: PatientStyles.textSecondary),
                  ),
                );
              }
              final messages = controller.messages;
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: PatientStyles.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final bool isMe = controller.isOwnMessage(msg.senderId);
                  return _buildMessageBubble(msg, isMe);
                },
              );
            }),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PatientStyles.surface,
              border: Border(
                top: BorderSide(color: PatientStyles.border),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: PatientStyles.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF4ECDC4)),
                  ),
                  Obx(() {
                    final sending = controller.isSendingMessage.value;
                    return Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(Icons.send, color: Colors.white),
                            ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg, bool isMe) {
    final String? text = msg.message;
    final bool hasAttachment = msg.attachmentName != null &&
        msg.attachmentName!.isNotEmpty;
    final bool isImage = hasAttachment &&
        (msg.attachmentType?.toLowerCase().startsWith('image/') == true ||
            _isImageExtension(msg.attachmentName));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isImage && msg.attachmentPath != null)
              _buildImageAttachment(msg.attachmentPath!)
            else if (text != null && text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? PatientStyles.teal : PatientStyles.border,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : PatientStyles.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              )
            else if (hasAttachment)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? PatientStyles.teal : PatientStyles.border,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      msg.attachmentName ?? 'File',
                      style: TextStyle(
                        color: isMe ? Colors.white : PatientStyles.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 4, right: 4),
              child: Text(
                '${controller.formatMessageTime(msg.createdAt)} ${isMe ? controller.messageStatusFor(msg) : ''}',
                style: TextStyle(
                  color: PatientStyles.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment(String path) {
    const baseUrl = 'https://supabase.example.com/storage/v1/object/public/';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        '$baseUrl$path',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: PatientStyles.border,
            child: Center(
              child: Icon(Icons.broken_image, color: PatientStyles.textSecondary),
            ),
          );
        },
      ),
    );
  }

  bool _isImageExtension(String? name) {
    if (name == null) return false;
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}
