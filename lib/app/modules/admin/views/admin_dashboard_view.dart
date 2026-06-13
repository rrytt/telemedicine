import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      drawer: _buildDrawer(authController),
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(context, authController),
              Expanded(
                child: Obx(() => _buildBody(controller)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthController authController) {
    return Drawer(
      child: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: const Text(
                  'Admin Menu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AdminStyles.textPrimary,
                  ),
                ),
              ),
              _drawerItem(Icons.dashboard_rounded, 'Dashboard', () {}),
              _drawerItem(Icons.person_rounded, 'Manage Patients', () => Get.toNamed(AppRoutes.adminPatients)),
              _drawerItem(Icons.medical_services_rounded, 'Manage Doctors', () => Get.toNamed(AppRoutes.adminDoctors)),
              _drawerItem(Icons.admin_panel_settings_rounded, 'Manage Admins', () => Get.toNamed(AppRoutes.adminAdmins)),
              _drawerItem(Icons.article_rounded, 'Manage Posts', () => Get.toNamed(AppRoutes.adminPosts)),
              _drawerItem(Icons.star_rounded, 'Reviews', () => Get.toNamed(AppRoutes.adminReviews)),
              _drawerItem(Icons.report_rounded, 'Complaints', () => Get.toNamed(AppRoutes.adminComplaints)),
              const Spacer(),
              const Divider(height: 1, color: AdminStyles.border),
              _drawerItem(Icons.logout_rounded, 'Logout', () => authController.logout()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AdminStyles.navy),
      title: Text(label, style: const TextStyle(
        fontWeight: FontWeight.w600, color: AdminStyles.textPrimary,
      )),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildHeader(BuildContext context, AuthController authController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: <Widget>[
          Builder(
            builder: (BuildContext ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AdminStyles.textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const Spacer(),
          const Text(
            'Admin Portal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AdminStyles.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AdminStyles.textPrimary),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdminController controller) {
    if (controller.isLoadingStats.value) {
      return const Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadStats();
        await controller.loadAccounts();
        await controller.loadComplaints();
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 600;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildSectionHeader('Full Site Statistics'),
                const SizedBox(height: 16),
                if (compact)
                  _buildStatsGridCompact(controller)
                else
                  _buildStatsGridWide(controller),
                if (controller.statsError.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminStyles.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.info_outline, color: AdminStyles.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.statsError.value,
                            style: const TextStyle(color: AdminStyles.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                _buildSectionHeader('Quick Access'),
                const SizedBox(height: 16),
                _buildQuickAccessRow(controller, compact),
                const SizedBox(height: 28),
                _buildSectionHeader('Account Overview'),
                const SizedBox(height: 16),
                _buildAccountOverview(controller),
                const SizedBox(height: 16),
                _buildComplaintsOverview(controller),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AdminStyles.sectionHeader);
  }

  Widget _buildStatsGridCompact(AdminController controller) {
    final s = controller.stats.value;
    if (s == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Total Users', '${s.totalUsers}', Icons.people_rounded, AdminStyles.navy)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Patients', '${s.totalPatients}', Icons.person_rounded, AdminStyles.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Doctors', '${s.totalDoctors}', Icons.medical_services_rounded, AdminStyles.success)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Admins', '${s.totalAdmins}', Icons.admin_panel_settings_rounded, AdminStyles.warning)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Appointments', '${s.totalAppointments}', Icons.calendar_month_rounded, AdminStyles.slate)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Posts', '${s.totalPosts}', Icons.article_rounded, AdminStyles.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Complaints', '${s.totalComplaints}', Icons.report_rounded, s.openComplaints > 0 ? AdminStyles.danger : AdminStyles.slate)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Open', '${s.openComplaints}', Icons.priority_high_rounded, AdminStyles.danger)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGridWide(AdminController controller) {
    final s = controller.stats.value;
    if (s == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(width: 160, child: _statCard('Total Users', '${s.totalUsers}', Icons.people_rounded, AdminStyles.navy)),
        SizedBox(width: 160, child: _statCard('Patients', '${s.totalPatients}', Icons.person_rounded, AdminStyles.blue)),
        SizedBox(width: 160, child: _statCard('Doctors', '${s.totalDoctors}', Icons.medical_services_rounded, AdminStyles.success)),
        SizedBox(width: 160, child: _statCard('Admins', '${s.totalAdmins}', Icons.admin_panel_settings_rounded, AdminStyles.warning)),
        SizedBox(width: 160, child: _statCard('Appointments', '${s.totalAppointments}', Icons.calendar_month_rounded, AdminStyles.slate)),
        SizedBox(width: 160, child: _statCard('Posts', '${s.totalPosts}', Icons.article_rounded, AdminStyles.textSecondary)),
        SizedBox(width: 160, child: _statCard('Complaints', '${s.totalComplaints}', Icons.report_rounded, AdminStyles.danger)),
        SizedBox(width: 160, child: _statCard('Open', '${s.openComplaints}', Icons.priority_high_rounded, AdminStyles.danger)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: AdminStyles.statValue),
          const SizedBox(height: 2),
          Text(label, style: AdminStyles.statLabel),
        ],
      ),
    );
  }

  Widget _buildQuickAccessRow(AdminController controller, bool compact) {
    final cards = [
      _quickAccessCard('Patients', Icons.person_rounded, AdminStyles.blue, () => Get.toNamed(AppRoutes.adminPatients)),
      _quickAccessCard('Doctors', Icons.medical_services_rounded, AdminStyles.success, () => Get.toNamed(AppRoutes.adminDoctors)),
      _quickAccessCard('Admins', Icons.admin_panel_settings_rounded, AdminStyles.warning, () => Get.toNamed(AppRoutes.adminAdmins)),
      _quickAccessCard('Posts', Icons.article_rounded, AdminStyles.textSecondary, () => Get.toNamed(AppRoutes.adminPosts)),
      _quickAccessCard('Complaints', Icons.report_rounded, AdminStyles.danger, () => Get.toNamed(AppRoutes.adminComplaints)),
    ];
    if (compact) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: c,
        )).toList(),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards.map((c) => SizedBox(
        width: 180,
        child: c,
      )).toList(),
    );
  }

  Widget _quickAccessCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: AdminStyles.cardDecoration(),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminStyles.textPrimary,
              )),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOverview(AdminController controller) {
    if (controller.isLoadingAccounts.value) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: AdminStyles.navy),
      ));
    }
    final int total = controller.accounts.length;
    final int pending = controller.accounts.where((a) => !a.isApproved).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.people_rounded, color: AdminStyles.navy, size: 20),
              const SizedBox(width: 8),
              const Text('Registered Accounts', style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AdminStyles.textPrimary,
              )),
              const Spacer(),
              Text('$total total', style: const TextStyle(
                color: AdminStyles.slate,
                fontSize: 13,
              )),
            ],
          ),
          const SizedBox(height: 14),
          _overviewRow('Patients', '${controller.patientAccounts.length}', AdminStyles.blue),
          _overviewRow('Doctors', '${controller.doctorAccounts.length}', AdminStyles.success),
          _overviewRow('Admins', '${controller.adminAccountsList.length}', AdminStyles.warning),
          if (pending > 0) ...[
            const Divider(height: 20),
            _overviewRow('Pending Approval', '$pending', AdminStyles.danger),
          ],
        ],
      ),
    );
  }

  Widget _overviewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(width: 8, height: 8, decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
          )),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AdminStyles.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AdminStyles.textPrimary,
            fontSize: 14,
          )),
        ],
      ),
    );
  }

  Widget _buildComplaintsOverview(AdminController controller) {
    if (controller.isLoadingComplaints.value) {
      return const SizedBox.shrink();
    }
    final int total = controller.complaints.length;
    final int open = controller.complaints.where((c) => c.status == 'open').length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminStyles.cardDecoration(),
      child: Row(
        children: <Widget>[
          const Icon(Icons.report_rounded, color: AdminStyles.danger, size: 20),
          const SizedBox(width: 8),
          const Text('Complaints', style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AdminStyles.textPrimary,
          )),
          const Spacer(),
          Text('$total total', style: const TextStyle(color: AdminStyles.slate, fontSize: 13)),
          if (open > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AdminStyles.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$open open', style: const TextStyle(
                color: AdminStyles.danger, fontSize: 12, fontWeight: FontWeight.w600,
              )),
            ),
          ],
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AdminStyles.slateLight),
        ],
      ),
    );
  }
}
