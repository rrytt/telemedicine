import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../theme/github_theme.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _version = 'Loading...';
  String _buildNumber = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = 'Unknown';
        _buildNumber = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: GithubTheme.heroGradient,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Telemedicine Calls',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_version ($_buildNumber)',
                  style: const TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'A comprehensive telemedicine platform connecting patients with healthcare professionals through secure video calls and messaging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Features:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GithubTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Secure video consultations\n'
                  '• Real-time messaging\n'
                  '• Appointment scheduling\n'
                  '• Medical file sharing\n'
                  '• Doctor profiles and reviews',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    color: GithubTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '© 2026 Telemedicine Inc.\nAll rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
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
