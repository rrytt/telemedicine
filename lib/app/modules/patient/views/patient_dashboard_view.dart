import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../controllers/patient_controller.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.put(PatientController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1B7F58),
              ),
              child: Text(
                'Patient Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Doctors'),
              onTap: () {
                Get.back();
                _showSearchDoctorsDialog(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Submit Complaint'),
              onTap: () {
                Get.back();
                _showComplaintDialog(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Get.back();
                authController.logout();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _chatCard(controller),
      ),
    );
  }

  Widget _chatCard(PatientController controller) {
    return Obx(() {
      final List<PatientAppointment> accepted = controller.appointments
          .where((PatientAppointment item) => item.chatEnabled)
          .toList();

      if (accepted.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(50),
          decoration: const BoxDecoration(
            color: Color(0xFFE5DDD5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No chats yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Your conversations with doctors will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Container(
        color: const Color(0xFFE5DDD5),
        child: ListView.separated(
          itemCount: accepted.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
          itemBuilder: (BuildContext context, int index) {
            final PatientAppointment item = accepted[index];
            final int unread = controller.unreadForAppointment(item.id);
            return InkWell(
              onTap: () => Get.toNamed(AppRoutes.chat, arguments: item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      radius: 24,
                      child: Text(
                        item.doctor.isNotEmpty ? item.doctor[0].toUpperCase() : 'D',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.doctor,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to continue your chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (unread > 0) ...<Widget>[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _showSearchDoctorsDialog(BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Doctors'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: controller.searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or specialty',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (String value) => controller.searchDoctors(value),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.filteredDoctors.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No doctors found.'),
                    );
                  }
                  return SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: controller.filteredDoctors.length,
                      itemBuilder: (BuildContext context, int index) {
                        final DoctorOption doctor = controller.filteredDoctors[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF128C7E),
                            child: Text(doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D'),
                          ),
                          title: Text(doctor.name),
                          subtitle: Text(doctor.specialty ?? 'General'),
                          trailing: FilledButton(
                            onPressed: () {
                              Get.back();
                              controller.sendConsultationRequest(doctor.id);
                            },
                            child: const Text('Request'),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showComplaintDialog(BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller.complaintTitleController,
                decoration: const InputDecoration(
                  labelText: 'Complaint title',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.complaintBodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Complaint details',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            Obx(() {
              return FilledButton(
                onPressed: controller.isSubmittingComplaint.value
                    ? null
                    : () {
                        controller.submitComplaint();
                        Get.back();
                      },
                child: Text(
                  controller.isSubmittingComplaint.value ? 'Sending...' : 'Send',
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
