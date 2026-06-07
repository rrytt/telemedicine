import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/admin_controller.dart';

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: GithubTopBar(
        title: 'Complaints Review',
        onLogout: authController.logout,
      ),
      drawer: GithubDrawer(
        menuTitle: 'Admin Menu',
        items: <GithubDrawerItem>[
          GithubDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () => Get.toNamed(AppRoutes.admin),
          ),
          GithubDrawerItem(
            icon: Icons.person_outline,
            label: 'Accounts',
            onTap: () => Get.toNamed(AppRoutes.adminAccounts),
          ),
          GithubDrawerItem(
            icon: Icons.report_outlined,
            label: 'Complaints',
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => authController.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoadingComplaints.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.complaintsError.value.isNotEmpty) {
            return Card(
              color: GithubTheme.warningSurface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  controller.complaintsError.value,
                  style: const TextStyle(color: GithubTheme.warning),
                ),
              ),
            );
          }

          if (controller.complaints.isEmpty) {
            return const Center(
              child: Text('No complaints have been submitted yet.'),
            );
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const GithubSectionHeader(
                title: 'Complaint Queue',
                subtitle: 'Review open issues and publish admin responses.',
              ),
              const SizedBox(height: 16),
              ...controller.complaints.map((AdminComplaintItem complaint) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GithubTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GithubBadge(
                            text: complaint.status,
                            textColor: GithubTheme.info,
                            bgColor: GithubTheme.infoSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patient: ${complaint.patientName} | Doctor: ${complaint.doctorName ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: GithubTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(complaint.body),
                      if ((complaint.adminResponse ?? '')
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GithubTheme.mutedSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GithubTheme.border),
                          ),
                          child: Text(
                            'Admin response: ${complaint.adminResponse}',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          SizedBox(
                            width: 150,
                            child: DropdownButtonFormField<String>(
                              initialValue: complaint.status,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: 'open',
                                  child: Text('open'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'in_review',
                                  child: Text('in_review'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'resolved',
                                  child: Text('resolved'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'rejected',
                                  child: Text('rejected'),
                                ),
                              ],
                              onChanged: (String? value) {
                                if (value != null &&
                                    value != complaint.status) {
                                  controller.updateComplaintStatus(
                                    complaint.id,
                                    value,
                                  );
                                }
                              },
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _showRespondDialog(
                              context,
                              controller,
                              complaint.id,
                            ),
                            child: const Text('Respond'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _showRespondDialog(
    BuildContext context,
    AdminController controller,
    String complaintId,
  ) async {
    final TextEditingController textController = TextEditingController();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Respond to Complaint'),
          content: TextField(
            controller: textController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Admin response'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (save == true) {
      await controller.respondToComplaint(complaintId, textController.text);
    }
  }
}
