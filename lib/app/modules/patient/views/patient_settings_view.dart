import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/github_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import '../controllers/patient_settings_controller.dart';
import '../patient_theme.dart';

class PatientSettingsView extends StatelessWidget {
  const PatientSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final PatientSettingsController controller = Get.put(
      PatientSettingsController(),
    );

    return Scaffold(
      backgroundColor: PatientStyles.navy,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: PatientStyles.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: PatientStyles.backgroundGradient),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              const Text(
                'Appearance',
                style: PatientStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: PatientStyles.glassCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PatientStyles.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      return SegmentedButton<ThemeMode>(
                        segments: const <ButtonSegment<ThemeMode>>[
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.settings),
                          ),
                        ],
                        selected: <ThemeMode>{themeController.themeMode.value},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          if (selection.isNotEmpty) {
                            themeController.setThemeMode(selection.first);
                          }
                        },
                        multiSelectionEnabled: false,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Notifications',
                style: PatientStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: PatientStyles.glassCard,
                child: Column(
                  children: <Widget>[
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Appointment reminders'),
                        subtitle: const Text(
                          'Get notified about upcoming appointments and schedules.',
                        ),
                        value: controller.appointmentReminders.value,
                        onChanged: controller.toggleAppointmentReminders,
                      ),
                    ),
                    const Divider(),
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Message notifications'),
                        subtitle: const Text(
                          'Receive alerts when a doctor sends you a message.',
                        ),
                        value: controller.messageNotifications.value,
                        onChanged: controller.toggleMessageNotifications,
                      ),
                    ),
                    const Divider(),
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Health tips'),
                        subtitle: const Text(
                          'Enable personalized health tips and reminders.',
                        ),
                        value: controller.healthTipsNotifications.value,
                        onChanged: controller.toggleHealthTipsNotifications,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Privacy & Account',
                style: PatientStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: PatientStyles.glassCard,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('My Profile'),
                      subtitle: const Text(
                        'Manage your patient profile and medical details.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed(AppRoutes.patientProfile),
                    ),
                    const Divider(),
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Share medical profile'),
                        subtitle: const Text(
                          'Allow doctors to view your health summary and records.',
                        ),
                        value: controller.shareHealthData.value,
                        onChanged: controller.toggleShareHealthData,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showChangePasswordDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text(
                        'Add an extra layer of account protection.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed(AppRoutes.twoFactor),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: GithubTheme.danger),
                      title: const Text('Logout', style: TextStyle(color: GithubTheme.danger)),
                      subtitle: const Text(
                        'Sign out of your account.',
                        style: TextStyle(color: GithubTheme.danger),
                      ),
                      onTap: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: <Widget>[
                              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton(
                                style: PatientStyles.primaryButton,
                                onPressed: () {
                                  Get.back();
                                  Get.find<AuthController>().logout();
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Support',
                style: PatientStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: PatientStyles.glassCard,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: controller.openHelpSupport,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: controller.openTermsOfService,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: controller.openPrivacyPolicy,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.report_problem_outlined),
                      title: const Text('Submit Complaint'),
                      subtitle: const Text('Report an issue or send feedback.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showComplaintDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('App details and version information.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: controller.openAbout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final PatientSettingsController controller =
        Get.find<PatientSettingsController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: PatientStyles.inputDecoration(
                label: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline, color: PatientStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: PatientStyles.inputDecoration(
                label: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline, color: PatientStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: PatientStyles.inputDecoration(
                label: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline, color: PatientStyles.slateLight),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: PatientStyles.primaryButton,
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                controller.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                Get.back();
              } else {
                Get.snackbar('Error', 'Passwords do not match');
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDialog() {
    final PatientController patientController = Get.find<PatientController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Submit Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: patientController.complaintTitleController,
              decoration: PatientStyles.inputDecoration(
                label: 'Complaint title',
                prefixIcon: const Icon(Icons.report_problem_outlined, color: PatientStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: patientController.complaintBodyController,
              maxLines: 4,
              decoration: PatientStyles.inputDecoration(
                label: 'Complaint details',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined, color: PatientStyles.slateLight),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() {
            return ElevatedButton(
              style: PatientStyles.primaryButton,
              onPressed: patientController.isSubmittingComplaint.value
                  ? null
                  : () {
                      patientController.submitComplaint();
                      Get.back();
                    },
              child: Text(
                patientController.isSubmittingComplaint.value
                    ? 'Sending...'
                    : 'Send',
              ),
            );
          }),
        ],
      ),
    );
  }
}
