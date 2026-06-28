import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

Color get _navy => Get.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1A3A5C);
const Color _teal = Color(0xFF4ECDC4);
const Color _green = Color(0xFF10B981);
const Color _amber = Color(0xFFFEA500);
Color get _slate => Get.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF5C6F87);
Color get _border => Get.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

class AccountTypeView extends GetView<AuthController> {
  const AccountTypeView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool configured = controller.isSupabaseConfigured;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: Get.isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF162033)]
                : [const Color(0xFFEFF3FC), const Color(0xFFD9E2EF), const Color(0xFFC9D5E8)],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Get.isDarkMode ? const Color(0xFF1E293B).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Get.isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                          if (!Get.isDarkMode)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, -1),
                            ),
                        ],
                        border: Border.all(
                          color: _border.withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: _navy.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              image: DecorationImage(
                                image: AssetImage('assets/images/icon.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome to Telemedicine',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _navy,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Choose your account type to get started with secure healthcare communication.',
                            style: TextStyle(
                              fontSize: 16,
                              color: _slate,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!configured)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _amber.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(Icons.warning_amber_rounded, color: _amber, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Supabase not configured yet. Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                                style: TextStyle(color: _amber, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (configured)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(Icons.check_circle, color: _green, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Supabase connected successfully.',
                                style: TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Doctor accounts are created and managed by the admin only. Please register here as a patient or ask your administrator for access.',
                        style: TextStyle(color: _slate, fontSize: 14, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final bool isWide = constraints.maxWidth > 600;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: isWide ? 320 : double.infinity,
                              child: _AccountTypeCard(
                                title: 'Patient Account',
                                subtitle: 'Book appointments, chat with doctors, and join secure video calls.',
                                icon: Icons.person_outline,
                                color: _teal,
                                features: const <String>[
                                  'Schedule appointments',
                                  'Secure messaging',
                                  'Video consultations',
                                  'Medical records access',
                                ],
                                onTap: () => controller.openLoginFor(AccountType.patient),
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 320 : double.infinity,
                              child: _AccountTypeCard(
                                title: 'Doctor Login',
                                subtitle: 'Sign in with your doctor account. Registration is managed by the admin.',
                                icon: Icons.medical_services_outlined,
                                color: _green,
                                features: const <String>[
                                  'Secure doctor login',
                                  'Patient consultation tools',
                                  'Appointment management',
                                  'Medical record access',
                                ],
                                onTap: () => controller.openLoginFor(AccountType.doctor),
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 320 : double.infinity,
                              child: _AccountTypeCard(
                                title: 'Admin Account',
                                subtitle: 'Manage system access, users, and platform operations.',
                                icon: Icons.admin_panel_settings_outlined,
                                color: _amber,
                                features: const <String>[
                                  'User management',
                                  'System monitoring',
                                  'Complaint handling',
                                  'Platform analytics',
                                ],
                                onTap: () => controller.openLoginFor(AccountType.admin),
                                isAdmin: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Secure . Private . HIPAA Compliant',
                      style: TextStyle(color: _slate, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
    required this.onTap,
    this.isAdmin = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Get.isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: _border.withValues(alpha: 0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _navy,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Restricted Access',
                                style: TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: TextStyle(color: _slate, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                ...features.map((String feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle, color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(color: _slate, fontSize: 13),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _navy.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Continue as ${title.split(' ')[0]}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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

