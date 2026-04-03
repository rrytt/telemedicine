import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/patient_controller.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.put(PatientController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: GithubTopBar(
        title: 'Patient Dashboard',
        onLogout: authController.logout,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 980;
            if (compact) {
              return ListView(
                children: <Widget>[
                  const PatientSidebarCard(),
                  const SizedBox(height: 12),
                  _bookingCard(context, controller),
                  const SizedBox(height: 12),
                  _appointmentsCard(controller),
                  const SizedBox(height: 12),
                  _chatCard(controller),
                  const SizedBox(height: 12),
                  _accessCard(controller),
                  const SizedBox(height: 12),
                  _complaintCard(controller),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(width: 240, child: PatientSidebarCard()),
                const SizedBox(width: 12),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      _bookingCard(context, controller),
                      const SizedBox(height: 12),
                      _appointmentsCard(controller),
                      const SizedBox(height: 12),
                      _chatCard(controller),
                      const SizedBox(height: 12),
                      _accessCard(controller),
                      const SizedBox(height: 12),
                      _complaintCard(controller),
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

  Widget _bookingCard(BuildContext context, PatientController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const GithubSectionHeader(
              title: 'Book Appointment',
              subtitle: 'Choose a doctor and request a new appointment',
              showDivider: false,
            ),
            Obx(() {
              return DropdownButtonFormField<String>(
                initialValue: controller.selectedDoctorId.value,
                decoration: InputDecoration(
                  labelText: 'Doctor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: controller.doctors
                    .map(
                      (DoctorOption e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) =>
                    controller.selectedDoctorId.value = value,
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final DateTime now = DateTime.now();
                final DateTime? date = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 90)),
                  initialDate: now,
                );
                if (date == null || !context.mounted) {
                  return;
                }

                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time == null) {
                  return;
                }

                controller.selectedDateTime.value = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              },
              icon: const Icon(Icons.schedule_outlined),
              label: Obx(() {
                final DateTime? dt = controller.selectedDateTime.value;
                if (dt == null) {
                  return const Text('Pick Date & Time');
                }
                return Text(
                  '${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                );
              }),
            ),
            const SizedBox(height: 10),
            Obx(() {
              return FilledButton.icon(
                onPressed: controller.isBooking.value
                    ? null
                    : controller.bookAppointment,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  controller.isBooking.value
                      ? 'Booking...'
                      : 'Book Appointment',
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GithubTheme.border),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.upload_file_outlined,
                    color: GithubTheme.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drag and drop files here, or click "Send File/Image/Video"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Supported: PDF, images, and videos',
                    style: TextStyle(
                      color: GithubTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    if (controller.uploadStatusMessage.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      controller.uploadStatusMessage.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.uploadStatusError.value
                            ? const Color(0xFFCF222E)
                            : const Color(0xFF1A7F37),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.bookingError.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Text(
                controller.bookingError.value,
                style: const TextStyle(color: Color(0xFFCF222E), fontSize: 12),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _accessCard(PatientController controller) {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Security & Access',
            subtitle: 'Manage who can access your medical records',
          ),
          Obx(() {
            if (controller.doctors.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No registered doctors available.',
                  style: TextStyle(color: GithubTheme.textSecondary),
                ),
              );
            }

            return Column(
              children: controller.doctors
                  .map(
                    (DoctorOption doctor) =>
                        _accessRow(doctor.name, 'Doctor', 'Read / Write', true),
                  )
                  .toList(),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Grant Access'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Review Permissions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessRow(String name, String role, String permission, bool active) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GithubTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.shield_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$role • $permission',
                      style: const TextStyle(
                        color: GithubTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GithubBadge(
                text: active ? 'Active' : 'Restricted',
                textColor: active
                    ? const Color(0xFF1A7F37)
                    : const Color(0xFF9A6700),
                bgColor: active
                    ? const Color(0xFFDAFBE1)
                    : const Color(0xFFFFF8C5),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Revoke')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appointmentsCard(PatientController controller) {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Appointments',
            subtitle: 'Your upcoming and accepted appointments',
          ),
          Obx(() {
            if (controller.isLoadingAppointments.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.appointmentsError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.appointmentsError.value,
                  style: const TextStyle(color: Color(0xFFCF222E)),
                ),
              );
            }

            return Column(
              children: controller.appointments.map((PatientAppointment item) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: GithubTheme.border)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.doctor,
                              style: const TextStyle(
                                color: Color(0xFF0969DA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.time,
                              style: const TextStyle(
                                color: GithubTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                GithubBadge(
                                  text: item.status,
                                  textColor: item.status == 'Accepted'
                                      ? const Color(0xFF1A7F37)
                                      : item.status == 'Rejected'
                                      ? const Color(0xFFCF222E)
                                      : const Color(0xFF0969DA),
                                  bgColor: item.status == 'Accepted'
                                      ? const Color(0xFFDAFBE1)
                                      : item.status == 'Rejected'
                                      ? const Color(0xFFFFEBE9)
                                      : const Color(0xFFDDF4FF),
                                ),
                                const SizedBox(width: 6),
                                if (item.urgent)
                                  const GithubBadge(
                                    text: 'Urgent',
                                    textColor: Color(0xFFCF222E),
                                    bgColor: Color(0xFFFFEBE9),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          FilledButton(
                            onPressed: item.chatEnabled
                                ? () =>
                                      controller.selectChatAppointment(item.id)
                                : null,
                            child: Text(
                              item.chatEnabled ? 'Open Chat' : 'Waiting',
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: item.chatEnabled
                                ? () => controller.openVideoCall(item)
                                : null,
                            icon: const Icon(Icons.video_call_outlined),
                            label: const Text('Join Video Call'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _chatCard(PatientController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const GithubSectionHeader(
              title: 'WhatsApp Style Chat',
              subtitle:
                  'Doctors appear as conversations with a full chat layout',
              showDivider: false,
            ),
            Obx(() {
              final List<PatientAppointment> accepted = controller.appointments
                  .where((PatientAppointment item) => item.chatEnabled)
                  .toList();
              final PatientAppointment? active =
                  controller.selectedChatAppointment;

              if (accepted.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GithubTheme.border),
                  ),
                  child: const Text(
                    'No accepted appointments yet. Once a doctor accepts, chat appears here like WhatsApp.',
                    style: TextStyle(color: GithubTheme.textSecondary),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 860;
                  final Widget conversationsPane = Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: GithubTheme.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.separated(
                      shrinkWrap: compact,
                      itemCount: accepted.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: GithubTheme.border),
                      itemBuilder: (BuildContext context, int index) {
                        final PatientAppointment item = accepted[index];
                        final int unread = controller.unreadForAppointment(
                          item.id,
                        );
                        final bool isSelected =
                            item.id ==
                            controller.selectedChatAppointmentId.value;
                        return InkWell(
                          onTap: () =>
                              controller.selectChatAppointment(item.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            color: isSelected
                                ? const Color(0xFFE7F7ED)
                                : Colors.white,
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF128C7E),
                                  foregroundColor: Colors.white,
                                  child: Text(
                                    item.doctor.isNotEmpty
                                        ? item.doctor[0].toUpperCase()
                                        : 'D',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.doctor,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.time,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: GithubTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (unread > 0)
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
                            ),
                          ),
                        );
                      },
                    ),
                  );

                  final Widget chatPane = Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: GithubTheme.border),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFEDE5DD),
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 58,
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
                                  (active?.doctor ?? 'D')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  active?.doctor ?? 'Doctor Chat',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: controller.canStartSelectedVideoCall
                                    ? controller.openSelectedVideoCall
                                    : null,
                                icon: const Icon(
                                  Icons.video_call_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                final ChatMessageItem msg =
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
                                                    color: GithubTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                                if (own) ...<Widget>[
                                                  const SizedBox(width: 5),
                                                  Builder(
                                                    builder:
                                                        (BuildContext context) {
                                                          final String
                                                          status = controller
                                                              .messageStatusFor(
                                                                msg,
                                                              );
                                                          final IconData icon =
                                                              status ==
                                                                      'Seen' ||
                                                                  status ==
                                                                      'Delivered'
                                                              ? Icons.done_all
                                                              : Icons.done;
                                                          final Color color =
                                                              status == 'Seen'
                                                              ? const Color(
                                                                  0xFF34B7F1,
                                                                )
                                                              : const Color(
                                                                  0xFF7A7A7A,
                                                                );

                                                          return Icon(
                                                            icon,
                                                            size: 14,
                                                            color: color,
                                                          );
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                onPressed: controller.isUploading.value
                                    ? null
                                    : controller.sendAttachment,
                                icon: const Icon(Icons.attach_file),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controller.messageController,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Type a message',
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
                                  onPressed: controller.isUploading.value
                                      ? null
                                      : controller.sendTextMessage,
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
                  );

                  if (compact) {
                    return Column(
                      children: <Widget>[
                        SizedBox(height: 200, child: conversationsPane),
                        const SizedBox(height: 10),
                        SizedBox(height: 420, child: chatPane),
                        const SizedBox(height: 10),
                        Obx(() {
                          return LinearProgressIndicator(
                            value: controller.isUploading.value
                                ? controller.uploadProgress.value.clamp(0, 1)
                                : 0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFDDE3E8),
                            borderRadius: BorderRadius.circular(4),
                          );
                        }),
                      ],
                    );
                  }

                  return SizedBox(
                    height: 520,
                    child: Row(
                      children: <Widget>[
                        SizedBox(width: 280, child: conversationsPane),
                        const SizedBox(width: 10),
                        Expanded(child: chatPane),
                      ],
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              return LinearProgressIndicator(
                value: controller.isUploading.value
                    ? controller.uploadProgress.value.clamp(0, 1)
                    : 0,
                minHeight: 6,
                backgroundColor: const Color(0xFFDDE3E8),
                borderRadius: BorderRadius.circular(4),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _complaintCard(PatientController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const GithubSectionHeader(
              title: 'Submit Complaint',
              subtitle: 'Send a complaint to admin for review',
              showDivider: false,
            ),
            TextField(
              controller: controller.complaintTitleController,
              decoration: InputDecoration(
                labelText: 'Complaint title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.complaintBodyController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Complaint details',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              return FilledButton.icon(
                onPressed: controller.isSubmittingComplaint.value
                    ? null
                    : controller.submitComplaint,
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(
                  controller.isSubmittingComplaint.value
                      ? 'Sending...'
                      : 'Send Complaint',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
