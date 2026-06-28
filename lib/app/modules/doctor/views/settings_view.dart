import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/theme_controller.dart';
import '../controllers/settings_controller.dart';
import '../doctor_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final SettingsController settingsController = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: DoctorStyles.surface.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Text(
                'Appearance',
                style: DoctorStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: DoctorStyles.glassCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DoctorStyles.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      return SegmentedButton<ThemeMode>(
                        segments: const [
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
                        selected: {themeController.themeMode.value},
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

              Text(
                'Notifications',
                style: DoctorStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4),
                decoration: DoctorStyles.glassCard,
                child: Column(
                  children: [
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Appointment Requests'),
                        subtitle: const Text(
                          'Get notified when patients request appointments',
                        ),
                        value: settingsController
                            .appointmentRequestsNotification
                            .value,
                        onChanged: settingsController
                            .toggleAppointmentRequestsNotification,
                      ),
                    ),
                    const Divider(),
                    Obx(
                      () => SwitchListTile(
                        title: const Text('New Messages'),
                        subtitle: const Text(
                          'Get notified when patients send messages',
                        ),
                        value: settingsController.newMessagesNotification.value,
                        onChanged: settingsController.toggleNewMessagesNotification,
                      ),
                    ),
                    const Divider(),
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Video Call Requests'),
                        subtitle: const Text(
                          'Get notified when patients request video calls',
                        ),
                        value:
                            settingsController.videoCallRequestsNotification.value,
                        onChanged:
                            settingsController.toggleVideoCallRequestsNotification,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Privacy & Security',
                style: DoctorStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4),
                decoration: DoctorStyles.glassCard,
                child: Column(
                  children: [
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
                      subtitle: Obx(
                        () => Text(
                          settingsController.twoFactorEnabled.value
                              ? 'Enabled for your account'
                              : 'Add an extra layer of security',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: settingsController.enable2FA,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Settings'),
                      subtitle: const Text('Control your data and privacy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPrivacySettingsDialog(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Account',
                style: DoctorStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4),
                decoration: DoctorStyles.glassCard,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile Information'),
                      subtitle: const Text('Update your personal information'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showProfileDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Working Hours'),
                      subtitle: const Text('Set your availability schedule'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showWorkingHoursDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.medical_services),
                      title: const Text('Specializations'),
                      subtitle: const Text('Update your medical specializations'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSpecializationsDialog(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'About',
                style: DoctorStyles.sectionHeader,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4),
                decoration: DoctorStyles.glassCard,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('App Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      subtitle: const Text(
                        'Contact support if you need assistance',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: settingsController.openHelpSupport,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('Send Feedback'),
                      subtitle: const Text('Help us improve the app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showFeedbackDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: settingsController.openTermsOfService,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: settingsController.openPrivacyPolicy,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('App information and version'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: settingsController.openAbout,
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

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: DoctorStyles.inputDecoration(
                label: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline, color: DoctorStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: DoctorStyles.inputDecoration(
                label: 'New Password',
                prefixIcon: Icon(Icons.lock_outline, color: DoctorStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: DoctorStyles.inputDecoration(
                label: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline, color: DoctorStyles.slateLight),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () {
              final settingsController = Get.find<SettingsController>();
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                settingsController.changePassword(
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

  void _showPrivacySettingsDialog() {
    final settingsController = Get.find<SettingsController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => SwitchListTile(
                title: const Text('Profile Visibility'),
                subtitle: const Text('Make your profile visible to patients'),
                value: settingsController.profileVisibility.value,
                onChanged: settingsController.toggleProfileVisibility,
              ),
            ),
            Obx(
              () => SwitchListTile(
                title: const Text('Online Status'),
                subtitle: const Text('Show when you are online'),
                value: settingsController.showOnlineStatus.value,
                onChanged: settingsController.toggleOnlineStatus,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final settingsController = Get.find<SettingsController>();
    final TextEditingController nameController = TextEditingController(
      text: settingsController.doctorName.value,
    );
    final TextEditingController specializationController =
        TextEditingController(text: settingsController.specialization.value);
    final TextEditingController licenseController = TextEditingController(
      text: settingsController.licenseNumber.value,
    );
    final TextEditingController experienceController = TextEditingController(
      text: settingsController.experience.value,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: DoctorStyles.inputDecoration(
                  label: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, color: DoctorStyles.slateLight),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specializationController,
                decoration: DoctorStyles.inputDecoration(
                  label: 'Specialization',
                  prefixIcon: Icon(Icons.medical_services_outlined, color: DoctorStyles.slateLight),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: DoctorStyles.inputDecoration(
                  label: 'License Number',
                  prefixIcon: Icon(Icons.badge_outlined, color: DoctorStyles.slateLight),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: experienceController,
                decoration: DoctorStyles.inputDecoration(
                  label: 'Years of Experience',
                  prefixIcon: Icon(Icons.timeline_outlined, color: DoctorStyles.slateLight),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () {
              settingsController.updateProfile(
                nameController.text,
                specializationController.text,
                licenseController.text,
                experienceController.text,
              );
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog() {
    final settingsController = Get.find<SettingsController>();
    final TextEditingController hoursController = TextEditingController(
      text: settingsController.workingHours.value,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Working Hours'),
        content: TextField(
          controller: hoursController,
          maxLines: 3,
          decoration: DoctorStyles.inputDecoration(
            label: 'Working Hours',
            hint: 'e.g., Mon-Fri: 9:00 AM - 5:00 PM',
            prefixIcon: Icon(Icons.schedule, color: DoctorStyles.slateLight),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () {
              settingsController.updateWorkingHours(hoursController.text);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSpecializationsDialog() {
    final settingsController = Get.find<SettingsController>();
    final TextEditingController specializationController =
        TextEditingController(text: settingsController.specialization.value);

    Get.dialog(
      AlertDialog(
        title: const Text('Medical Specializations'),
        content: TextField(
          controller: specializationController,
          maxLines: 2,
          decoration: DoctorStyles.inputDecoration(
            label: 'Specializations',
            hint: 'e.g., Cardiology, Neurology',
            prefixIcon: Icon(Icons.medical_services_outlined, color: DoctorStyles.slateLight),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () {
              settingsController.updateProfile(
                settingsController.doctorName.value,
                specializationController.text,
                settingsController.licenseNumber.value,
                settingsController.experience.value,
              );
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          decoration: DoctorStyles.inputDecoration(
            label: 'Your Feedback',
            hint: 'Tell us how we can improve...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.feedback_outlined, color: DoctorStyles.slateLight),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () {
              final settingsController = Get.find<SettingsController>();
              settingsController.sendFeedback(feedbackController.text);
              Get.back();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
