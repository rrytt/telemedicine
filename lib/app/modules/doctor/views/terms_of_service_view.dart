import 'package:flutter/material.dart';
import '../doctor_theme.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: DoctorStyles.surface.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: DoctorStyles.glassCard,
              child: ListView(
                children: [
                  Text(
                    'Terms of Service',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DoctorStyles.textPrimary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome to Telemedicine Calls. By using this application, you agree to the following terms and conditions...',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textPrimary),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Use of Service: You may use this application for lawful medical consultations and communication only.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Account Security: You are responsible for keeping your account credentials secure and up to date.',
                    style: TextStyle(fontSize: 16, color: DoctorStyles.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Disclaimer: This application is provided as-is. The developers are not responsible for medical decisions made using this service.',
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
