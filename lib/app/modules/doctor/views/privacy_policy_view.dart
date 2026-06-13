import 'package:flutter/material.dart';
import '../doctor_theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: DoctorStyles.glassCard,
              child: ListView(
                children: const [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DoctorStyles.textPrimary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'We respect your privacy and are committed to protecting your personal information.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textPrimary),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Information Collected: We collect account data, appointment details, and support feedback to deliver the service.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use of Data: Data is used to personalize your experience, manage appointments, and improve the application.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data Sharing: Your data is not shared with unauthorized third parties. We may use service providers for hosting and analytics.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textSecondary),
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
