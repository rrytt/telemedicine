import 'package:flutter/material.dart';
import '../../../theme/github_theme.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                  'Terms of Service',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome to Telemedicine Calls. By using this application, you agree to the following terms and conditions...',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Use of Service: You may use this application for lawful medical consultations and communication only.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '2. Account Security: You are responsible for keeping your account credentials secure and up to date.',
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '3. Disclaimer: This application is provided as-is. The developers are not responsible for medical decisions made using this service.',
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
