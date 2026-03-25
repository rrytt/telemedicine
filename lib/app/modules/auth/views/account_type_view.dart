import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/github_widgets.dart';
import '../../../theme/github_theme.dart';
import '../controllers/auth_controller.dart';

class AccountTypeView extends GetView<AuthController> {
  const AccountTypeView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool configured = controller.isSupabaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemedicine Portal'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Choose account type',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Patient, doctor, and admin experiences built with GetX and GitHub-like design.',
                    style: TextStyle(color: GithubTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: configured
                          ? const Color(0xFFDAFBE1)
                          : const Color(0xFFFFF8C5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: configured
                            ? const Color(0xFF1A7F37)
                            : const Color(0xFF9A6700),
                      ),
                    ),
                    child: Text(
                      configured
                          ? 'Supabase connected successfully.'
                          : 'Supabase not configured yet. Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: 220,
                        child: GithubFeatureCard(
                          title: 'Patient Account',
                          subtitle: 'Appointments, reports, chat, and uploads',
                          icon: Icons.person_outline,
                          actionText: 'Continue as Patient',
                          onTap: () {
                            controller.openLoginFor(AccountType.patient);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: GithubFeatureCard(
                          title: 'Doctor Account',
                          subtitle: 'Patient queue, consultation, and notes',
                          icon: Icons.medical_services_outlined,
                          actionText: 'Continue as Doctor',
                          onTap: () {
                            controller.openLoginFor(AccountType.doctor);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: GithubFeatureCard(
                          title: 'Admin Account',
                          subtitle: 'Manage accounts, approvals, and complaints',
                          icon: Icons.admin_panel_settings_outlined,
                          actionText: 'Continue as Admin',
                          onTap: () {
                            controller.openLoginFor(AccountType.admin);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
