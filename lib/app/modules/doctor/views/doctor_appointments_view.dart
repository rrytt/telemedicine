import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/github_theme.dart';
import '../controllers/doctor_controller.dart';
import '../doctor_theme.dart';

class DoctorAppointmentsView extends GetView<DoctorController> {
  const DoctorAppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Appointments'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: DoctorStyles.border, width: 1),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          Obx(() {
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

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadQueue();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: controller.queue.length,
            itemBuilder: (context, index) {
              final patient = controller.queue[index];
              return _buildPatientCard(context, patient, index);
            },
          ),
        );
      }),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, DoctorPatientItem patient, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: DoctorStyles.cardDecoration(borderRadius: 18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: DoctorStyles.blue.withValues(alpha: 0.16),
          backgroundImage: patient.avatarUrl != null
              ? NetworkImage(patient.avatarUrl!)
              : null,
          child: patient.avatarUrl == null
              ? Text(
                  patient.name.isNotEmpty
                      ? patient.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: DoctorStyles.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: DoctorStyles.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: patient.isPending
                        ? GithubTheme.warning.withValues(alpha: 0.15)
                        : GithubTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    patient.state,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: patient.isPending ? DoctorStyles.slate : GithubTheme.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patient.scheduledAt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DoctorStyles.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (patient.canChat &&
                controller.unreadForAppointment(patient.appointmentId) > 0) ...[
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
                      _buildActionButton(
                        label: 'Accept',
                        isProcessing: controller.isAccepting.value &&
                            controller.processingAppointmentId.value ==
                                patient.appointmentId,
                        color: DoctorStyles.navy,
                        onPressed: controller.processingAppointmentId.value ==
                                patient.appointmentId
                            ? null
                            : () => controller.acceptAppointment(index),
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        label: 'Reject',
                        isProcessing: controller.isRejecting.value &&
                            controller.processingAppointmentId.value ==
                                patient.appointmentId,
                        color: GithubTheme.danger,
                        onPressed: controller.processingAppointmentId.value ==
                                patient.appointmentId
                            ? null
                            : () => controller.rejectAppointment(index),
                      ),
                      const SizedBox(width: 6),
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
                      const SizedBox(width: 6),
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
  }

  Widget _buildActionButton({
    required String label,
    required bool isProcessing,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label, style: const TextStyle(fontSize: 13)),
      ),
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
