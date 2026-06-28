import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminAdminsView extends StatelessWidget {
  const AdminAdminsView({super.key});

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
    );
  }

  Widget _buildHeader(AdminController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
                onPressed: () => Get.back(),
              ),
              const Spacer(),
              Text(
                'Manage Admins',
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
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: AdminStyles.inputDecoration(
                label: 'Search admins...',
                prefixIcon: Icon(Icons.search_rounded, color: AdminStyles.slate),
              ).copyWith(
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      return Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    final results = controller.searchAdmins(controller.searchQuery.value);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 48, color: AdminStyles.slateLight),
            SizedBox(height: 12),
            Text('No admins found', style: TextStyle(color: AdminStyles.slate, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadAccounts(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          final account = results[index];
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: AdminStyles.cardDecoration(),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AdminStyles.warning.withValues(alpha: 0.15),
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
                          color: AdminStyles.warning,
                        ),
                      )
                    : null,
              ),
              title: Text(
                account.fullName,
                style: TextStyle(fontWeight: FontWeight.w600, color: AdminStyles.textPrimary),
              ),
              subtitle: Text(
                account.email ?? account.id,
                style: TextStyle(color: AdminStyles.slate, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AdminStyles.slate),
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
              onTap: () => _showDetailDialog(context, controller, account),
            ),
          );
        },
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, AdminController controller, dynamic account) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminStyles.surface,
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
            Text('Admin Details', style: AdminStyles.sectionHeader),
            const SizedBox(height: 20),
            _detailRow('Name', account.fullName),
            _detailRow('Email', account.email ?? 'Not provided'),
            _detailRow('ID', account.id),
            _detailRow('Role', account.role),
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
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(
              color: AdminStyles.slate, fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
          Expanded(
            child: Text(value, style: TextStyle(
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

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminStyles.surface,
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
              Text('Edit Admin', style: AdminStyles.sectionHeader),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: AdminStyles.inputDecoration(label: 'Full Name'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.updateAccountName(account.id, nameController.text);
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
        title: Text('Delete Account', style: TextStyle(
          fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
        )),
        content: Text(
          'Are you sure you want to delete "${account.fullName}"? This action cannot be undone.',
          style: TextStyle(color: AdminStyles.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAccount(account.id);
            },
            child: Text('Delete', style: TextStyle(color: AdminStyles.danger)),
          ),
        ],
      ),
    );
  }
}
