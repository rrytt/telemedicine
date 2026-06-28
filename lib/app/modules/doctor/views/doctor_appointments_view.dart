import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
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
        backgroundColor: DoctorStyles.surface.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: Border(
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
              style: TextStyle(fontSize: 16, color: DoctorStyles.danger),
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
            padding: EdgeInsets.symmetric(vertical: 12),
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
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: DoctorStyles.cardDecoration(borderRadius: 18),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
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
                      style: TextStyle(
                        color: DoctorStyles.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DoctorStyles.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: patient.isPending
                              ? DoctorStyles.warning.withValues(alpha: 0.15)
                              : DoctorStyles.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          patient.state,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: patient.isPending ? DoctorStyles.slate : DoctorStyles.success,
                          ),
                        ),
                      ),
                      Text(
                        patient.scheduledAt,
                        style: TextStyle(
                          fontSize: 12,
                          color: DoctorStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (patient.canChat &&
                      controller.unreadForAppointment(patient.appointmentId) > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${controller.unreadForAppointment(patient.appointmentId)} unread messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: DoctorStyles.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    Get.toNamed(
                      AppRoutes.publicProfile,
                      arguments: <String, dynamic>{'id': patient.patientId},
                    );
                    break;
                  case 'accept':
                    controller.acceptAppointment(index);
                    break;
                  case 'reject':
                    controller.rejectAppointment(index);
                    break;
                  case 'chat':
                    controller.pickPatient(index);
                    Get.toNamed(AppRoutes.doctorChat);
                    break;
                  case 'delete':
                    _confirmRemoveAppointment(context, controller, index);
                    break;
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profile'), dense: true, contentPadding: EdgeInsets.zero)),
                ];
                if (patient.isPending) {
                  items.addAll([
                    const PopupMenuItem(value: 'accept', child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Accept'), dense: true, contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.cancel_outlined), title: Text('Reject'), dense: true, contentPadding: EdgeInsets.zero)),
                  ]);
                } else {
                  items.add(const PopupMenuItem(value: 'chat', child: ListTile(leading: Icon(Icons.chat), title: Text('Chat'), dense: true, contentPadding: EdgeInsets.zero)));
                }
                items.add(const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Remove'), dense: true, contentPadding: EdgeInsets.zero)));
                return items;
              },
            ),
          ],
        ),
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
