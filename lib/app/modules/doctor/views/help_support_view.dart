import 'package:flutter/material.dart';
import '../doctor_theme.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need assistance?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DoctorStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'If you are experiencing issues with the app, please contact our support team using one of the channels below.',
                    style: TextStyle(
                      fontSize: 16,
                      color: DoctorStyles.textSecondary,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Email: support@telemedicine.app',
                    style: TextStyle(
                      fontSize: 16,
                      color: DoctorStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Phone: +1 (800) 123-4567',
                    style: TextStyle(
                      fontSize: 16,
                      color: DoctorStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Support hours: Sunday - Thursday, 9:00 AM - 5:00 PM',
                    style: TextStyle(
                      fontSize: 16,
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
