import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminAccountsView extends StatelessWidget {
  const AdminAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(child: Obx(() => _buildBody(controller, context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          const Text(
            'Account Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AdminStyles.textPrimary,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AdminStyles.textPrimary),
            onSelected: (String value) {
              switch (value) {
                case 'patients':
                  Get.toNamed(AppRoutes.adminPatients);
                  break;
                case 'doctors':
                  Get.toNamed(AppRoutes.adminDoctors);
                  break;
                case 'admins':
                  Get.toNamed(AppRoutes.adminAdmins);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'patients', child: Text('Manage Patients')),
              const PopupMenuItem(value: 'doctors', child: Text('Manage Doctors')),
              const PopupMenuItem(value: 'admins', child: Text('Manage Admins')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdminController controller, BuildContext context) {
    if (controller.isLoadingAccounts.value) {
      return const Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    if (controller.accountsError.value.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminStyles.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            controller.accountsError.value,
            style: const TextStyle(color: AdminStyles.danger, fontSize: 13),
          ),
        ),
      );
    }

    final doctors = controller.doctorAccounts;
    final patients = controller.patientAccounts;
    final admins = controller.adminAccountsList;

    if (doctors.isEmpty && patients.isEmpty && admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.people_outline_rounded, size: 56, color: AdminStyles.slateLight),
            SizedBox(height: 12),
            Text('No accounts available', style: TextStyle(
              color: AdminStyles.slate, fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadAccounts(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          if (patients.isNotEmpty)
            _buildRoleSection('Patients', patients, AdminStyles.blue, controller, context),
          if (doctors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRoleSection('Doctors', doctors, AdminStyles.success, controller, context),
          ],
          if (admins.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRoleSection('Admins', admins, AdminStyles.warning, controller, context),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoleSection(String title, List<dynamic> accounts, Color color, AdminController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
                )),
                const Spacer(),
                Text('${accounts.length}', style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13,
                )),
              ],
            ),
          ),
          ...accounts.map((account) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: AdminStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: color.withValues(alpha: 0.15),
                        backgroundImage: account.avatarUrl != null && account.avatarUrl!.isNotEmpty
                            ? NetworkImage(account.avatarUrl!)
                            : null,
                        child: account.avatarUrl == null || account.avatarUrl!.isEmpty
                            ? Text(
                                account.fullName.isNotEmpty
                                    ? account.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          account.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AdminStyles.textPrimary,
                          ),
                        ),
                      ),
                      _statusChip(account.isApproved),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.id,
                    style: const TextStyle(
                      fontSize: 11, color: AdminStyles.slate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          initialValue: account.role,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AdminStyles.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AdminStyles.border),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(value: 'patient', child: Text('patient', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'doctor', child: Text('doctor', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'admin', child: Text('admin', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (String? value) {
                            if (value != null && value != account.role) {
                              controller.updateAccountRole(account.id, value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _smallButton(
                              account.isApproved ? 'Unapprove' : 'Approve',
                              account.isApproved ? AdminStyles.warning : AdminStyles.success,
                              () => controller.approveAccount(account.id, !account.isApproved),
                            ),
                            const SizedBox(width: 4),
                            _smallButton('Edit', AdminStyles.navy, () => _showEditNameDialog(context, controller, account.id, account.fullName)),
                            const SizedBox(width: 4),
                            _smallButton('Delete', AdminStyles.danger, () => controller.deleteAccount(account.id)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusChip(bool approved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: approved
            ? AdminStyles.success.withValues(alpha: 0.12)
            : AdminStyles.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        approved ? 'Approved' : 'Pending',
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: approved ? AdminStyles.success : AdminStyles.warning,
        ),
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    AdminController controller,
    String accountId,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);

    final bool? save = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Name', style: TextStyle(
          fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
        )),
        content: TextField(
          controller: textController,
          decoration: AdminStyles.inputDecoration(label: 'Full name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyles.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true) {
      await controller.updateAccountName(accountId, textController.text);
    }
  }
}
