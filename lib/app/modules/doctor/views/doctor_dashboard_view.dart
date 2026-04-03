import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/doctor_controller.dart';

class DoctorDashboardView extends StatelessWidget {
  const DoctorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final DoctorController controller = Get.put(DoctorController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: GithubTopBar(
        title: 'Doctor Portal',
        onLogout: authController.logout,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 1100;
            if (compact) {
              return ListView(
                children: <Widget>[
                  _queueCard(controller),
                  const SizedBox(height: 12),
                  _previewCard(controller),
                  const SizedBox(height: 12),
                  _consultationCard(controller),
                  const SizedBox(height: 12),
                  _securityCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 320, child: _queueCard(controller)),
                const SizedBox(width: 12),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      _previewCard(controller),
                      const SizedBox(height: 12),
                      _consultationCard(controller),
                      const SizedBox(height: 12),
                      _securityCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _queueCard(DoctorController controller) {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Chats',
            subtitle: 'Patients shown as WhatsApp-style conversations',
          ),
          Obx(() {
            if (controller.isLoadingQueue.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.queueError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.queueError.value,
                  style: const TextStyle(color: Color(0xFFCF222E)),
                ),
              );
            }

            return Column(
              children: List<Widget>.generate(controller.queue.length, (int i) {
                final DoctorPatientItem patient = controller.queue[i];
                final bool selected = controller.selectedIndex.value == i;
                final int unread = controller.unreadForAppointment(
                  patient.appointmentId,
                );

                return InkWell(
                  onTap: () => controller.pickPatient(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: const Border(
                        top: BorderSide(color: GithubTheme.border),
                      ),
                      color: selected ? const Color(0xFFE7F7ED) : Colors.white,
                    ),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: const Color(0xFF128C7E),
                          foregroundColor: Colors.white,
                          child: Text(
                            patient.name.isNotEmpty
                                ? patient.name[0].toUpperCase()
                                : 'P',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                patient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${patient.state} • ${patient.scheduledAt}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: GithubTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          patient.canChat
                              ? Icons.mark_chat_read
                              : Icons.schedule,
                          size: 18,
                          color: patient.canChat
                              ? const Color(0xFF128C7E)
                              : GithubTheme.textSecondary,
                        ),
                        if (unread > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _previewCard(DoctorController controller) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Obx(() {
            return GithubSectionHeader(
              title: 'Document Preview',
              subtitle: 'Patient files: ${controller.selectedPatientName}',
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Obx(() {
              final DoctorPatientItem? selected = controller.selectedItem;

              if (selected == null || !selected.isPending) {
                return const SizedBox.shrink();
              }

              return FilledButton.icon(
                onPressed: controller.isAccepting.value
                    ? null
                    : controller.acceptSelectedAppointment,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  controller.isAccepting.value
                      ? 'Accepting...'
                      : 'Accept Appointment',
                ),
              );
            }),
          ),
          Obx(() {
            if (controller.documents.isEmpty) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GithubTheme.border),
                ),
                child: const Text(
                  'No uploaded files found for this patient yet.',
                  style: TextStyle(color: GithubTheme.textSecondary),
                ),
              );
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GithubTheme.border),
              ),
              child: Column(
                children: List<Widget>.generate(controller.documents.length, (
                  int index,
                ) {
                  final DoctorDocumentItem document =
                      controller.documents[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: index == 0
                          ? null
                          : const Border(
                              top: BorderSide(color: GithubTheme.border),
                            ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.insert_drive_file_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                document.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${document.fileType.toUpperCase()} • ${document.uploadedAt} • ${document.uploadedBy}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: GithubTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Preview'),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _securityCard() {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Access Control',
            subtitle:
                'RBAC permissions for patient records and consultation assets',
          ),
          _accessItem('Assigned Doctor', 'write', true),
          _accessItem('Nurse Team', 'read', true),
          _accessItem('External Specialist', 'pending', false),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Add Member'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_moderator_outlined),
                  label: const Text('Revoke Access'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessItem(String label, String permission, bool active) {
    final Color bg = active ? const Color(0xFFDAFBE1) : const Color(0xFFFFF8C5);
    final Color text = active
        ? const Color(0xFF1A7F37)
        : const Color(0xFF9A6700);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GithubTheme.border)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.admin_panel_settings_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          GithubBadge(text: permission, textColor: text, bgColor: bg),
        ],
      ),
    );
  }

  Widget _consultationCard(DoctorController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 780;
            final Widget videoPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Consultation Center',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFF24292F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.videocam_outlined, color: Colors.white70),
                        SizedBox(height: 8),
                        Text(
                          'Live Video Feed',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  return FilledButton.icon(
                    onPressed: controller.canStartVideoCall
                        ? controller.openSelectedVideoCall
                        : null,
                    icon: const Icon(Icons.video_call_outlined),
                    label: Text(
                      controller.canStartVideoCall
                          ? 'Start Video Call'
                          : 'Accept Appointment First',
                    ),
                  );
                }),
              ],
            );

            final Widget notesPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Clinical Notes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  return TextFormField(
                    initialValue: controller.notes.value,
                    maxLines: 8,
                    onChanged: (String value) => controller.notes.value = value,
                    decoration: InputDecoration(
                      hintText: 'Use markdown: #, -, **bold**',
                      filled: true,
                      fillColor: GithubTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: GithubTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: GithubTheme.border),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Obx(() {
                  return FilledButton.icon(
                    onPressed: controller.isSavingNote.value
                        ? null
                        : controller.saveClinicalNote,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      controller.isSavingNote.value ? 'Saving...' : 'Save Note',
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text(
                  'Patient Chat',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 360,
                  decoration: BoxDecoration(
                    border: Border.all(color: GithubTheme.border),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFEDE5DD),
                  ),
                  child: Column(
                    children: <Widget>[
                      Obx(() {
                        return Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF075E54),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: const Color(0xFF128C7E),
                                foregroundColor: Colors.white,
                                radius: 16,
                                child: Text(
                                  controller.selectedPatientName.isNotEmpty
                                      ? controller.selectedPatientName[0]
                                            .toUpperCase()
                                      : 'P',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.selectedPatientName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: controller.canStartVideoCall
                                    ? controller.openSelectedVideoCall
                                    : null,
                                icon: const Icon(
                                  Icons.video_call_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoadingMessages.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

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

                          if (controller.messages.isEmpty) {
                            return const Center(
                              child: Text(
                                'No chat messages yet.',
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
                              final DoctorChatMessageItem msg =
                                  controller.messages[index];
                              final bool own = controller.isOwnMessage(
                                msg.senderId,
                              );
                              return Align(
                                alignment: own
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: own
                                          ? const Color(0xFFDCF8C6)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if ((msg.message ?? '').isNotEmpty)
                                          Text(msg.message!),
                                        if ((msg.attachmentName ?? '')
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
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
                                                controller.formatMessageTime(
                                                  msg.createdAt,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      GithubTheme.textSecondary,
                                                ),
                                              ),
                                              if (own) ...<Widget>[
                                                const SizedBox(width: 5),
                                                Icon(
                                                  controller.messageStatusFor(
                                                            msg,
                                                          ) ==
                                                          'Seen'
                                                      ? Icons.done_all
                                                      : controller
                                                                .messageStatusFor(
                                                                  msg,
                                                                ) ==
                                                            'Delivered'
                                                      ? Icons.done_all
                                                      : Icons.done,
                                                  size: 14,
                                                  color:
                                                      controller
                                                              .messageStatusFor(
                                                                msg,
                                                              ) ==
                                                          'Seen'
                                                      ? const Color(0xFF34B7F1)
                                                      : const Color(0xFF7A7A7A),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: controller.messageController,
                                minLines: 1,
                                maxLines: 4,
                                enabled: controller.canReplyToSelectedPatient,
                                decoration: InputDecoration(
                                  hintText: controller.canReplyToSelectedPatient
                                      ? 'Type a message'
                                      : 'Accept appointment first to enable chat',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              return FloatingActionButton.small(
                                onPressed:
                                    controller.isSendingMessage.value ||
                                        !controller.canReplyToSelectedPatient
                                    ? null
                                    : controller.sendMessage,
                                backgroundColor: const Color(0xFF128C7E),
                                foregroundColor: Colors.white,
                                child: controller.isSendingMessage.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                children: <Widget>[
                  videoPanel,
                  const SizedBox(height: 12),
                  notesPanel,
                ],
              );
            }

            return Row(
              children: <Widget>[
                SizedBox(width: 280, child: videoPanel),
                const SizedBox(width: 12),
                Expanded(child: notesPanel),
              ],
            );
          },
        ),
      ),
    );
  }
}
