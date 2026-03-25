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
            title: 'Patient Queue',
            subtitle: 'Incoming and active patient appointment requests',
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

                Color badgeBg = const Color(0xFFDDF4FF);
                Color badgeText = const Color(0xFF0969DA);
                if (patient.state == 'Pending') {
                  badgeBg = const Color(0xFFFFF8C5);
                  badgeText = const Color(0xFF9A6700);
                } else if (patient.state == 'Accepted') {
                  badgeBg = const Color(0xFFDAFBE1);
                  badgeText = const Color(0xFF1A7F37);
                } else if (patient.state == 'Rejected') {
                  badgeBg = const Color(0xFFFFEBE9);
                  badgeText = const Color(0xFFCF222E);
                }

                return InkWell(
                  onTap: () => controller.pickPatient(i),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: const Border(
                        top: BorderSide(color: GithubTheme.border),
                      ),
                      color: selected
                          ? const Color(0xFFF0F6FC)
                          : GithubTheme.surface,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                patient.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                patient.scheduledAt,
                                style: const TextStyle(
                                  color: GithubTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GithubBadge(
                          text: patient.state,
                          textColor: badgeText,
                          bgColor: badgeBg,
                        ),
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GithubTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'medical_report.txt',
                  style: TextStyle(
                    color: Color(0xFF7EE787),
                    fontFamily: 'Courier New',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Blood pressure: 120/80\nHeart rate: 76 bpm\nAttached radiology image pending review.',
                  style: TextStyle(
                    color: Color(0xFFC9D1D9),
                    fontFamily: 'Courier New',
                  ),
                ),
              ],
            ),
          ),
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
                  'Chat with Patient',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.isLoadingMessages.value) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (controller.messagesError.value.isNotEmpty) {
                    return Text(
                      controller.messagesError.value,
                      style: const TextStyle(color: Color(0xFFCF222E)),
                    );
                  }

                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: GithubTheme.border),
                      borderRadius: BorderRadius.circular(6),
                      color: GithubTheme.bg,
                    ),
                    child: controller.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No chat messages yet.',
                              style: TextStyle(color: GithubTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: controller.messages.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DoctorChatMessageItem msg =
                                  controller.messages[index];
                              final bool own = controller.isOwnMessage(msg.senderId);
                              return Align(
                                alignment: own
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: own
                                        ? const Color(0xFFDAFBE1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: GithubTheme.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      if ((msg.message ?? '').isNotEmpty)
                                        Text(msg.message!),
                                      if ((msg.attachmentName ?? '').isNotEmpty)
                                        Text(
                                          'Attachment: ${msg.attachmentName} (${msg.attachmentType ?? '-'})',
                                          style: const TextStyle(
                                            color: Color(0xFF0969DA),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.messageController,
                  maxLines: 2,
                  enabled: controller.canReplyToSelectedPatient,
                  decoration: InputDecoration(
                    hintText: controller.canReplyToSelectedPatient
                        ? 'Reply to patient...'
                        : 'Accept appointment first to enable chat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  return FilledButton(
                    onPressed: controller.isSendingMessage.value ||
                            !controller.canReplyToSelectedPatient
                        ? null
                        : controller.sendMessage,
                    child: Text(
                      controller.isSendingMessage.value
                          ? 'Sending...'
                          : 'Send Reply',
                    ),
                  );
                }),
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
