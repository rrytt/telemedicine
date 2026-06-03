import 'package:flutter/material.dart';
import '../../../theme/github_theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            child: ListView(
              children: const [
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'We respect your privacy and are committed to protecting your personal information.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Information Collected: We collect account data, appointment details, and support feedback to deliver the service.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use of Data: Data is used to personalize your experience, manage appointments, and improve the application.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Data Sharing: Your data is not shared with unauthorized third parties. We may use service providers for hosting and analytics.',
                  style: TextStyle(
                    fontSize: 16,
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
}
