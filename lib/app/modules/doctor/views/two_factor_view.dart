import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/github_theme.dart';
import '../controllers/settings_controller.dart';

class TwoFactorView extends StatelessWidget {
  const TwoFactorView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController =
        Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Two-factor authentication adds an extra security layer to your account. '
                  'When enabled, you will need an additional verification step during login.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  return SwitchListTile(
                    tileColor: GithubTheme.mutedSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: const Text('Enable two-factor authentication'),
                    subtitle: Text(
                      settingsController.twoFactorEnabled.value
                          ? 'Two-factor authentication is enabled.'
                          : 'Add an extra layer of security to your account.',
                    ),
                    value: settingsController.twoFactorEnabled.value,
                    onChanged: (value) {
                      if (value) {
                        _showEnableTwoFactorDialog(settingsController);
                      } else {
                        settingsController.setTwoFactorEnabled(false);
                        Get.snackbar(
                          '2FA Disabled',
                          'Two-factor authentication has been turned off.',
                        );
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'This screen allows you to enable or disable two-factor authentication for your account. '
                  'A real implementation would use a secure verification flow with an authentication app or SMS code.',
                  style: TextStyle(
                    fontSize: 15,
                    color: GithubTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnableTwoFactorDialog(SettingsController settingsController) {
    final String verificationCode = List.generate(
      6,
      (_) => Random().nextInt(10),
    ).join();
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the verification code shown below to confirm enabling two-factor authentication.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GithubTheme.mutedSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                verificationCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim() == verificationCode) {
                settingsController.setTwoFactorEnabled(true);
                Get.back();
                Get.snackbar(
                  '2FA Enabled',
                  'Two-factor authentication has been enabled.',
                );
              } else {
                Get.snackbar(
                  'Invalid Code',
                  'The verification code is incorrect.',
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
