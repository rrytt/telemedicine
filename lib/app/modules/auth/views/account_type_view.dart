import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../controllers/auth_controller.dart';

class AccountTypeView extends GetView<AuthController> {
  const AccountTypeView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool configured = controller.isSupabaseConfigured;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GithubTheme.bg,
              GithubTheme.bgAlt,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: GithubTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: GithubTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          // Logo/Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: GithubTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: GithubTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          const Text(
                            'Welcome to Telemedicine',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: GithubTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          const Text(
                            'Choose your account type to get started with secure healthcare communication.',
                            style: TextStyle(
                              fontSize: 16,
                              color: GithubTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Status Card
                    if (!configured)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GithubTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GithubTheme.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(
                              Icons.warning_amber_rounded,
                              color: GithubTheme.warning,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Supabase not configured yet. Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                                style: TextStyle(
                                  color: GithubTheme.warning,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (configured)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GithubTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GithubTheme.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(
                              Icons.check_circle,
                              color: GithubTheme.success,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Supabase connected successfully.',
                                style: TextStyle(
                                  color: GithubTheme.success,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Doctor accounts are created and managed by the admin only. Please register here as a patient or ask your administrator for access.',
                        style: TextStyle(
                          color: GithubTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account Type Cards
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
                                color: GithubTheme.primary,
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
                                color: GithubTheme.secondary,
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
                                color: GithubTheme.accent,
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

                    // Footer
                    const Text(
                      'Secure • Private • HIPAA Compliant',
                      style: TextStyle(
                        color: GithubTheme.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: GithubTheme.textPrimary,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: GithubTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Restricted Access',
                              style: TextStyle(
                                color: GithubTheme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                subtitle,
                style: const TextStyle(
                  color: GithubTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Features
              ...features.map((String feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(
                        color: GithubTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue as ${title.split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

