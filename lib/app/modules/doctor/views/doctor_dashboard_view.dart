import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../theme/github_theme.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../controllers/doctor_controller.dart';

class DoctorDashboardView extends GetView<DoctorController> {
  const DoctorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      drawer: GithubDrawer(
        menuTitle: 'Doctor Menu',
        items: <GithubDrawerItem>[
          GithubDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => Get.toNamed(AppRoutes.doctorProfile),
          ),
          GithubDrawerItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          GithubDrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingQueue.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.queueError.isNotEmpty) {
          return Center(
            child: Text(
              controller.queueError.value,
              style: const TextStyle(fontSize: 16, color: GithubTheme.danger),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (controller.queue.isEmpty) {
          return const Center(
            child: Text(
              'No appointments found',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: controller.queue.length,
          itemBuilder: (context, index) {
            final patient = controller.queue[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 1.5,
              shadowColor: GithubTheme.textPrimary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: GithubTheme.primary.withValues(alpha: 0.16),
                  backgroundImage: patient.avatarUrl != null
                      ? NetworkImage(patient.avatarUrl!)
                      : null,
                  child: patient.avatarUrl == null
                      ? Text(
                          patient.name.isNotEmpty
                              ? patient.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: GithubTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  patient.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Status: ${patient.state}'),
                    const SizedBox(height: 4),
                    Text('Scheduled: ${patient.scheduledAt}'),
                    if (patient.canChat &&
                        controller.unreadForAppointment(patient.appointmentId) >
                            0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${controller.unreadForAppointment(patient.appointmentId)} unread messages',
                        style: const TextStyle(
                          color: GithubTheme.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      tooltip: 'View patient profile',
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.publicProfile,
                          arguments: <String, dynamic>{'id': patient.patientId},
                        );
                      },
                    ),
                    patient.isPending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    controller.processingAppointmentId.value ==
                                            patient.appointmentId
                                        ? null
                                        : () => controller.acceptAppointment(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GithubTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Obx(() {
                                  final bool isProcessing =
                                      controller.isAccepting.value &&
                                      controller.processingAppointmentId.value ==
                                          patient.appointmentId;
                                  return isProcessing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Accept');
                                }),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    controller.processingAppointmentId.value ==
                                            patient.appointmentId
                                        ? null
                                        : () => controller.rejectAppointment(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GithubTheme.danger,
                                  foregroundColor: Colors.white,
                                ),
                                child: Obx(() {
                                  final bool isProcessing =
                                      controller.isRejecting.value &&
                                      controller.processingAppointmentId.value ==
                                          patient.appointmentId;
                                  return isProcessing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Reject');
                                }),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove appointment',
                                onPressed: () => _confirmRemoveAppointment(
                                  context,
                                  controller,
                                  index,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chat,
                                  color: GithubTheme.info,
                                ),
                                onPressed: () {
                                  controller.pickPatient(index);
                                  Get.toNamed(AppRoutes.doctorChat);
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove appointment',
                                onPressed: () => _confirmRemoveAppointment(
                                  context,
                                  controller,
                                  index,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmRemoveAppointment(
    BuildContext context,
    DoctorController controller,
    int index,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Appointment'),
          content: const Text(
            'Remove this appointment from your dashboard. The patient will still be able to access it until they also remove it.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Get.back();
                await controller.hideAppointment(index);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
