import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../doctor_theme.dart';

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
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: DoctorStyles.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1F2F4F), Color(0xFF2C4C7C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                      color: DoctorStyles.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version ($_buildNumber)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: DoctorStyles.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'A patient-friendly telemedicine platform that connects you with trusted healthcare professionals through secure video visits and messaging.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: DoctorStyles.textSecondary,
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
                        color: DoctorStyles.textPrimary,
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
                      color: DoctorStyles.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '© 2026 Telemedicine Inc.\nAll rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: DoctorStyles.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
