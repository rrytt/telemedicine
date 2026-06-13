import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminDoctorsView extends StatelessWidget {
  const AdminDoctorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(controller),
              Expanded(child: Obx(() => _buildList(controller))),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, controller),
        backgroundColor: AdminStyles.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Doctor'),
      ),
    );
  }

  Widget _buildHeader(AdminController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
                onPressed: () => Get.back(),
              ),
              const Spacer(),
              const Text(
                'Manage Doctors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AdminStyles.textPrimary,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: AdminStyles.inputDecoration(
                label: 'Search doctors...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminStyles.slate),
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildList(AdminController controller) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, color: AdminStyles.danger, size: 40),
              const SizedBox(height: 12),
              Text(
                controller.accountsError.value,
                style: const TextStyle(color: AdminStyles.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final results = controller.searchDoctors(controller.searchQuery.value);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.person_off_rounded, size: 48, color: AdminStyles.slateLight),
            SizedBox(height: 12),
            Text('No doctors found', style: TextStyle(color: AdminStyles.slate, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadAccounts(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          final account = results[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: AdminStyles.cardDecoration(),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AdminStyles.success.withValues(alpha: 0.15),
                backgroundImage: account.avatarUrl != null && account.avatarUrl!.isNotEmpty
                    ? NetworkImage(account.avatarUrl!)
                    : null,
                child: account.avatarUrl == null || account.avatarUrl!.isEmpty
                    ? Text(
                        account.fullName.isNotEmpty
                            ? account.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminStyles.success,
                        ),
                      )
                    : null,
              ),
              title: Text(
                account.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AdminStyles.textPrimary),
              ),
              subtitle: Text(
                account.email ?? account.id,
                style: const TextStyle(color: AdminStyles.slate, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _statusChip(account.isApproved),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AdminStyles.slate),
                    onSelected: (String value) {
                      switch (value) {
                        case 'view':
                          _showDetailDialog(context, controller, account);
                          break;
                        case 'edit':
                          _showEditDialog(context, controller, account);
                          break;
                        case 'delete':
                          _showDeleteConfirm(context, controller, account);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              onTap: () => _showDetailDialog(context, controller, account),
            ),
          );
        },
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: approved ? AdminStyles.success : AdminStyles.warning,
        ),
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, AdminController controller, dynamic account) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AdminStyles.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Doctor Details', style: AdminStyles.sectionHeader),
            const SizedBox(height: 20),
            _detailRow('Name', account.fullName),
            _detailRow('Email', account.email ?? 'Not provided'),
            _detailRow('ID', account.id),
            _detailRow('Role', account.role),
            _detailRow('Status', account.isApproved ? 'Approved' : 'Pending'),
            if (account.createdAt != null)
              _detailRow('Joined', account.createdAt!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: AdminStyles.primaryButton,
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(
              color: AdminStyles.slate, fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(
              color: AdminStyles.textPrimary, fontWeight: FontWeight.w500, fontSize: 13,
            )),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, AdminController controller, dynamic account) {
    final nameController = TextEditingController(text: account.fullName);
    final isApproved = account.isApproved.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AdminStyles.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Doctor', style: AdminStyles.sectionHeader),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: AdminStyles.inputDecoration(label: 'Full Name'),
              ),
              const SizedBox(height: 14),
              Obx(() => Row(
                children: <Widget>[
                  const Text('Approved', style: TextStyle(
                    color: AdminStyles.textPrimary, fontWeight: FontWeight.w500,
                  )),
                  const Spacer(),
                  Switch(
                    value: isApproved.value,
                    activeTrackColor: AdminStyles.success,
                    onChanged: (v) => isApproved.value = v,
                  ),
                ],
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.updateAccountName(account.id, nameController.text);
                    if (isApproved.value != account.isApproved) {
                      controller.approveAccount(account.id, isApproved.value);
                    }
                    Get.back();
                  },
                  style: AdminStyles.primaryButton,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, AdminController controller, dynamic account) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account', style: TextStyle(
          fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
        )),
        content: Text(
          'Are you sure you want to delete "${account.fullName}"? This action cannot be undone.',
          style: const TextStyle(color: AdminStyles.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAccount(account.id);
            },
            child: const Text('Delete', style: TextStyle(color: AdminStyles.danger)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AdminController controller) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AdminStyles.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Register New Doctor', style: AdminStyles.sectionHeader),
              const SizedBox(height: 4),
              const Text(
                'A verification email may be required.',
                style: TextStyle(color: AdminStyles.slate, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: AdminStyles.inputDecoration(label: 'Full Name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                decoration: AdminStyles.inputDecoration(label: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                decoration: AdminStyles.inputDecoration(label: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.createDoctorAccount(
                      email: emailController.text,
                      password: passwordController.text,
                      fullName: nameController.text,
                    );
                    Get.back();
                  },
                  style: AdminStyles.primaryButton,
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
