import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/admin_controller.dart';

class AdminAccountsView extends StatelessWidget {
  const AdminAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: GithubTopBar(
        title: 'Accounts Management',
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
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.report_outlined,
            label: 'Complaints',
            onTap: () => Get.toNamed(AppRoutes.adminComplaints),
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
          if (controller.isLoadingAccounts.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.accountsError.value.isNotEmpty) {
            return Card(
              color: GithubTheme.warningSurface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  controller.accountsError.value,
                  style: const TextStyle(color: GithubTheme.warning),
                ),
              ),
            );
          }

          final List<AdminAccountItem> doctors = controller.doctorAccounts;
          final List<AdminAccountItem> patients = controller.patientAccounts;
          final List<AdminAccountItem> admins = controller.adminAccounts;

          if (doctors.isEmpty && patients.isEmpty && admins.isEmpty) {
            return const Center(
              child: Text('No accounts are currently available.'),
            );
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const GithubSectionHeader(
                title: 'Admin Accounts',
                subtitle: 'Approve, update, or delete accounts by role.',
              ),
              const SizedBox(height: 16),
              if (doctors.isNotEmpty)
                _buildRoleSection(
                  context,
                  'Doctor Accounts',
                  doctors,
                  controller,
                ),
              if (patients.isNotEmpty)
                _buildRoleSection(
                  context,
                  'Patient Accounts',
                  patients,
                  controller,
                ),
              if (admins.isNotEmpty)
                _buildRoleSection(
                  context,
                  'Admin Accounts',
                  admins,
                  controller,
                ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDoctorDialog(context, controller),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Register Doctor'),
      ),
    );
  }

  Widget _buildRoleSection(
    BuildContext context,
    String title,
    List<AdminAccountItem> accounts,
    AdminController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        ...accounts.map((AdminAccountItem account) {
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
                    Expanded(
                      child: Text(
                        account.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    GithubBadge(
                      text: account.isApproved ? 'Approved' : 'Pending',
                      textColor: account.isApproved
                          ? GithubTheme.success
                          : GithubTheme.warning,
                      bgColor: account.isApproved
                          ? GithubTheme.successSurface
                          : GithubTheme.warningSurface,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<String>(
                        initialValue: account.role,
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
                    FilledButton(
                      onPressed: () => controller.approveAccount(
                        account.id,
                        !account.isApproved,
                      ),
                      child: Text(account.isApproved ? 'Unapprove' : 'Approve'),
                    ),
                    OutlinedButton(
                      onPressed: () => _showEditNameDialog(
                        context,
                        controller,
                        account.id,
                        account.fullName,
                      ),
                      child: const Text('Edit Name'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.deleteAccount(account.id),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showRegisterDoctorDialog(
    BuildContext context,
    AdminController controller,
  ) async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register Doctor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (save == true) {
      await controller.createDoctorAccount(
        email: emailController.text,
        password: passwordController.text,
        fullName: nameController.text,
      );
    }
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    AdminController controller,
    String accountId,
    String currentName,
  ) async {
    final TextEditingController textController = TextEditingController(
      text: currentName,
    );

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
}
