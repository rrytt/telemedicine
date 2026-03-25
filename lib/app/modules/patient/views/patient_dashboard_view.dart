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
                onChanged: (String? value) => controller.selectedDoctorId.value = value,
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
                return Text('${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
              }),
            ),
            const SizedBox(height: 10),
            Obx(() {
              return FilledButton.icon(
                onPressed: controller.isBooking.value ? null : controller.bookAppointment,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  controller.isBooking.value ? 'Booking...' : 'Book Appointment',
                ),
              );
            }),
            const SizedBox(height: 8),
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
                    border: Border(
                      top: BorderSide(color: GithubTheme.border),
                    ),
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
                              style:
                                  const TextStyle(color: GithubTheme.textSecondary),
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
                                ? () => controller.selectChatAppointment(item.id)
                                : null,
                            child: Text(item.chatEnabled ? 'Open Chat' : 'Waiting'),
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
              title: 'Chat & Files',
              subtitle: 'Message your doctor and share files, images, or videos',
              showDivider: false,
            ),
            Obx(() {
              final List<PatientAppointment> accepted = controller.appointments
                  .where((PatientAppointment item) => item.chatEnabled)
                  .toList();

              return DropdownButtonFormField<String>(
                initialValue: controller.selectedChatAppointmentId.value,
                decoration: InputDecoration(
                  labelText: 'Active Appointment Chat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: accepted
                    .map(
                      (PatientAppointment e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text('${e.doctor} (${e.time})'),
                      ),
                    )
                    .toList(),
                onChanged: accepted.isEmpty ? null : controller.selectChatAppointment,
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              return Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: controller.canStartSelectedVideoCall
                      ? controller.openSelectedVideoCall
                      : null,
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Start Video Call'),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.messagesError.value.isNotEmpty) {
                return Text(
                  controller.messagesError.value,
                  style: const TextStyle(color: Color(0xFFCF222E)),
                );
              }

              if (controller.isLoadingMessages.value) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: GithubTheme.border),
                  borderRadius: BorderRadius.circular(6),
                  color: GithubTheme.bg,
                ),
                child: controller.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(color: GithubTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: controller.messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChatMessageItem msg = controller.messages[index];
                          final bool own = controller.isOwnMessage(msg.senderId);
                          return Align(
                            alignment:
                                own ? Alignment.centerRight : Alignment.centerLeft,
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
            const SizedBox(height: 12),
            Obx(() {
              return LinearProgressIndicator(
                value: controller.isUploading.value
                    ? controller.uploadProgress.value.clamp(0, 1)
                    : 0,
                minHeight: 8,
                backgroundColor: const Color(0xFFEAEEF2),
                borderRadius: BorderRadius.circular(4),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: controller.messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your message to doctor...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Obx(() {
                  return FilledButton(
                    onPressed: controller.isUploading.value
                        ? null
                        : controller.sendTextMessage,
                    child: Text(
                      controller.isSendingMessage.value ? 'Sending...' : 'Send Message',
                    ),
                  );
                }),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: controller.isUploading.value
                      ? null
                      : controller.sendAttachment,
                  child: const Text('Send File/Image/Video'),
                ),
              ],
            ),
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
