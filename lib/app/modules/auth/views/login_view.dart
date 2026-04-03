import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  String _roleLabel(AccountType type) {
    if (type == AccountType.patient) {
      return 'Patient';
    }
    if (type == AccountType.doctor) {
      return 'Doctor';
    }
    return 'Admin';
  }

  String _roleDescription(AccountType type) {
    if (type == AccountType.patient) {
      return 'Book appointments, chat with doctors, and join secure calls.';
    }
    if (type == AccountType.doctor) {
      return 'Review patient requests, chat, and start consultations.';
    }
    return 'Manage system access, users, and platform operations.';
  }

  String _titleText({required bool signUp, required String role}) {
    if (signUp) {
      return 'Create your $role account';
    }
    return 'Welcome back, $role';
  }

  String _subtitleText({required bool signUp, required bool isAdmin}) {
    if (isAdmin) {
      return 'Admin access is available only for pre-approved accounts.';
    }
    if (signUp) {
      return 'Create a secure profile to start telemedicine sessions.';
    }
    return 'Sign in to continue your care journey.';
  }

  Widget _heroPanel(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: dark
            ? const LinearGradient(
                colors: <Color>[Color(0xFF0F4D45), Color(0xFF1E2E3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFF1B7F58), Color(0xFF0F6E8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.local_hospital_outlined, color: Colors.white),
          ),
          SizedBox(height: 14),
          Text(
            'Telemedicine Platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Secure communication between patients and doctors in one place.',
            style: TextStyle(color: Color(0xFFE8F2FF), height: 1.4),
          ),
          SizedBox(height: 16),
          _HeroPoint(text: 'One account flow for patient, doctor, and admin'),
          SizedBox(height: 8),
          _HeroPoint(
            text: 'Protected chat, file sharing, and video consultation',
          ),
          SizedBox(height: 8),
          _HeroPoint(text: 'Fast role switching for testing and onboarding'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemedicine Platform'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 760;

                  final Widget formCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Obx(() {
                        final bool loading = controller.isLoading.value;
                        final bool signUp = controller.isSignUpMode.value;
                        final bool isAdmin = controller.isAdminSelected;
                        final AccountType role = controller.currentAccountType;
                        final String roleLabel = controller.currentAccountLabel;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // App Name
                            const Center(
                              child: Text(
                                'Telemedicine Platform',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: GithubTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title and Subtitle
                            Text(
                              _titleText(signUp: signUp, role: roleLabel),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _subtitleText(signUp: signUp, isAdmin: isAdmin),
                              style: const TextStyle(
                                color: GithubTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Account Type Selection
                            DropdownButtonFormField<AccountType>(
                              initialValue: role,
                              decoration: InputDecoration(
                                labelText: 'Account Type',
                                helperText: _roleDescription(role),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: AccountType.values
                                  .map(
                                    (AccountType type) =>
                                        DropdownMenuItem<AccountType>(
                                          value: type,
                                          child: Text(_roleLabel(type)),
                                        ),
                                  )
                                  .toList(),
                              onChanged: loading
                                  ? null
                                  : (AccountType? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      controller.select(value);
                                      if (value == AccountType.admin &&
                                          signUp) {
                                        controller.toggleMode(false);
                                      }
                                    },
                            ),
                            const SizedBox(height: 16),
                            // Sign In / Create Account Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: GithubTheme.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: GithubTheme.border),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => controller.toggleMode(false),
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: signUp
                                              ? GithubTheme.textSecondary
                                              : GithubTheme.textPrimary,
                                          fontWeight: signUp
                                              ? FontWeight.w400
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: loading || isAdmin
                                          ? null
                                          : () => controller.toggleMode(true),
                                      child: Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: signUp
                                              ? GithubTheme.textPrimary
                                              : GithubTheme.textSecondary,
                                          fontWeight: signUp
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Admin accounts are provisioned by the system owner.',
                                  style: TextStyle(
                                    color: GithubTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Email Field
                            TextFormField(
                              controller: controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !loading,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'name@example.com',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            TextFormField(
                              controller: controller.passwordController,
                              obscureText: true,
                              enabled: !loading,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: signUp
                                    ? 'Create a strong password'
                                    : 'Enter your password',
                                helperText: signUp
                                    ? 'Use at least 8 characters for better security.'
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (signUp) ...<Widget>[
                              const SizedBox(height: 8),
                              Obx(() {
                                final double strength =
                                    controller.passwordStrength.value;
                                Color color = const Color(0xFFCF222E);
                                if (strength >= 0.7) {
                                  color = const Color(0xFF1A7F37);
                                } else if (strength >= 0.35) {
                                  color = const Color(0xFF9A6700);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    LinearProgressIndicator(
                                      value: strength,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(6),
                                      backgroundColor: const Color(0xFFEAEFF3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Password strength: ${controller.passwordStrengthLabel}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                            const SizedBox(height: 20),
                            // Remember Me and Forgot Password
                            Row(
                              children: <Widget>[
                                Obx(() {
                                  return Checkbox(
                                    value: controller.rememberMe.value,
                                    onChanged: loading
                                        ? null
                                        : (bool? value) {
                                            controller.setRememberMe(
                                              value ?? false,
                                            );
                                          },
                                  );
                                }),
                                const Text('Remember me'),
                                const Spacer(),
                                TextButton(
                                  onPressed: loading || signUp
                                      ? null
                                      : controller.sendPasswordResetLink,
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Error Message
                            if (controller.errorMessage.value.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBE9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFCF222E),
                                  ),
                                ),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                    color: Color(0xFFCF222E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // Confirmation Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: loading
                                    ? null
                                    : controller.submitAuth,
                                child: Text(
                                  loading
                                      ? (signUp
                                            ? 'Creating your account...'
                                            : 'Signing you in...')
                                      : (signUp
                                            ? 'Create My Account'
                                            : 'Sign In Securely'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: <Widget>[
                        formCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _heroPanel(context)),
                      const SizedBox(width: 14),
                      SizedBox(width: 430, child: formCard),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFF5FAFF), height: 1.35),
          ),
        ),
      ],
    );
  }
}
