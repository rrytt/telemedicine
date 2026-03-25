import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: GithubTopBar(
        title: 'Admin Portal',
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
                  _accountsCard(context, controller),
                  const SizedBox(height: 12),
                  _complaintsCard(context, controller),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _accountsCard(context, controller)),
                const SizedBox(width: 12),
                Expanded(child: _complaintsCard(context, controller)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _accountsCard(BuildContext context, AdminController controller) {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Accounts Management',
            subtitle: 'Approve, edit, delete, and manage user accounts',
          ),
          Obx(() {
            if (controller.isLoadingAccounts.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            if (controller.accountsError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.accountsError.value,
                  style: const TextStyle(color: Color(0xFFCF222E)),
                ),
              );
            }

            return Column(
              children: controller.accounts.map((AdminAccountItem account) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: GithubTheme.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              account.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          GithubBadge(
                            text: account.isApproved ? 'Approved' : 'Pending',
                            textColor: account.isApproved
                                ? const Color(0xFF1A7F37)
                                : const Color(0xFF9A6700),
                            bgColor: account.isApproved
                                ? const Color(0xFFDAFBE1)
                                : const Color(0xFFFFF8C5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.id,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GithubTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 130,
                            child: DropdownButtonFormField<String>(
                              initialValue: account.role,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: 'patient',
                                  child: Text('patient'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'doctor',
                                  child: Text('doctor'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'admin',
                                  child: Text('admin'),
                                ),
                              ],
                              onChanged: (String? value) {
                                if (value != null && value != account.role) {
                                  controller.updateAccountRole(account.id, value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => controller.approveAccount(
                              account.id,
                              !account.isApproved,
                            ),
                            child: Text(
                              account.isApproved ? 'Unapprove' : 'Approve',
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _showEditNameDialog(
                              context,
                              controller,
                              account.id,
                              account.fullName,
                            ),
                            child: const Text('Edit Name'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => controller.deleteAccount(account.id),
                            child: const Text('Delete'),
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

  Widget _complaintsCard(BuildContext context, AdminController controller) {
    return Card(
      child: Column(
        children: <Widget>[
          const GithubSectionHeader(
            title: 'Complaints Review',
            subtitle: 'Review complaints and publish admin responses',
          ),
          Obx(() {
            if (controller.isLoadingComplaints.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            if (controller.complaintsError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.complaintsError.value,
                  style: const TextStyle(color: Color(0xFFCF222E)),
                ),
              );
            }

            return Column(
              children: controller.complaints.map((AdminComplaintItem complaint) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: GithubTheme.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          GithubBadge(
                            text: complaint.status,
                            textColor: const Color(0xFF0969DA),
                            bgColor: const Color(0xFFDDF4FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${complaint.patientName} | Doctor: ${complaint.doctorName ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: GithubTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(complaint.body),
                      if ((complaint.adminResponse ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GithubTheme.border),
                          ),
                          child: Text('Admin response: ${complaint.adminResponse}'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 150,
                            child: DropdownButtonFormField<String>(
                              initialValue: complaint.status,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                if (value != null && value != complaint.status) {
                                  controller.updateComplaintStatus(complaint.id, value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
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
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    AdminController controller,
    String accountId,
    String currentName,
  ) async {
    final TextEditingController textController =
        TextEditingController(text: currentName);

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Account Name'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Full name'),
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
      await controller.updateAccountName(accountId, textController.text);
    }
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
