import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
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
      backgroundColor: GithubTheme.bg,
      appBar: GithubTopBar(
        title: 'Admin Portal',
        onLogout: authController.logout,
      ),
      drawer: GithubDrawer(
        menuTitle: 'Admin Menu',
        items: <GithubDrawerItem>[
          GithubDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.person_outline,
            label: 'Accounts',
            onTap: () => Get.toNamed(AppRoutes.adminAccounts),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const GithubSectionHeader(
              title: 'Admin Overview',
              subtitle:
                  'Quickly access account management and complaint review.',
            ),
            const SizedBox(height: 16),
            Expanded(child: Obx(() => _buildDashboardContent(controller))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required List<Widget> details,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: GithubTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ...details,
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  Widget _accountsSummaryCard(AdminController controller) {
    final int totalAccounts = controller.accounts.length;
    final int totalPatients = controller.patientAccounts.length;
    final int totalDoctors = controller.doctorAccounts.length;
    final int totalAdmins = controller.adminAccounts.length;
    final int pendingApprovals = controller.accounts
        .where((AdminAccountItem account) => !account.isApproved)
        .length;

    return _buildSummaryCard(
      title: 'Accounts Management',
      subtitle: 'Review user roles, approvals, and doctor onboarding.',
      details: <Widget>[
        Text('Total accounts: $totalAccounts'),
        Text('Patients: $totalPatients'),
        Text('Doctors: $totalDoctors'),
        Text('Admins: $totalAdmins'),
        Text('Pending approvals: $pendingApprovals'),
      ],
      actionLabel: 'Open Accounts',
      onAction: () => Get.toNamed(AppRoutes.adminAccounts),
    );
  }

  Widget _complaintsSummaryCard(AdminController controller) {
    final int totalComplaints = controller.complaints.length;
    final int openCount = controller.complaints
        .where((AdminComplaintItem complaint) => complaint.status == 'open')
        .length;
    final int inReviewCount = controller.complaints
        .where(
          (AdminComplaintItem complaint) => complaint.status == 'in_review',
        )
        .length;

    return _buildSummaryCard(
      title: 'Complaints Review',
      subtitle: 'Monitor patient issues and manage responses from one place.',
      details: <Widget>[
        Text('Total complaints: $totalComplaints'),
        Text('Open: $openCount'),
        Text('In review: $inReviewCount'),
      ],
      actionLabel: 'Open Complaints',
      onAction: () => Get.toNamed(AppRoutes.adminComplaints),
    );
  }

  Widget _buildDashboardContent(AdminController controller) {
    if (controller.isLoadingAccounts.value ||
        controller.isLoadingComplaints.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.accountsError.value.isNotEmpty ||
        controller.complaintsError.value.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (controller.accountsError.value.isNotEmpty)
              Card(
                color: GithubTheme.warningSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    controller.accountsError.value,
                    style: const TextStyle(color: GithubTheme.warning),
                  ),
                ),
              ),
            if (controller.complaintsError.value.isNotEmpty)
              Card(
                color: GithubTheme.warningSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    controller.complaintsError.value,
                    style: const TextStyle(color: GithubTheme.warning),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        final Widget content = Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (compact)
              _accountsSummaryCard(controller)
            else
              Expanded(child: _accountsSummaryCard(controller)),
            if (!compact) const SizedBox(width: 12),
            if (compact) const SizedBox(height: 12),
            if (compact)
              _complaintsSummaryCard(controller)
            else
              Expanded(child: _complaintsSummaryCard(controller)),
          ],
        );

        return compact ? SingleChildScrollView(child: content) : content;
      },
    );
  }
}
