import 'package:flutter/material.dart';
import '../../../theme/github_theme.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need assistance?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'If you are experiencing issues with the app, please contact our support team using one of the channels below.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Email: support@telemedicine.app',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Phone: +1 (800) 123-4567',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Support hours: Sunday - Thursday, 9:00 AM - 5:00 PM',
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
