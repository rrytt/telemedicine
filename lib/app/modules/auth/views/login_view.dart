import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  LoginView({
    super.key,
    this.hideRoleSelection = false,
    this.adminLoginOnly = false,
  });

  final bool hideRoleSelection;
  final bool adminLoginOnly;
  final RxBool showPassword = false.obs;

  String _titleText({required bool signUp, required bool adminLogin}) {
    if (adminLogin) {
      return 'Admin Sign In';
    }
    if (signUp) {
      return 'Create your Patient account';
    }
    return 'Welcome back';
  }

  String _subtitleText({required bool signUp, required bool adminLogin}) {
    if (adminLogin) {
      return 'Sign in with your administrator credentials.';
    }
    if (signUp) {
      return 'Register as a patient to start your telemedicine care journey.';
    }
    return 'Sign in to continue your care journey.';
  }

  Widget _heroPanel(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: -24,
          top: -24,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -18,
          bottom: -18,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: GithubTheme.heroGradient,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: GithubTheme.primary.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Telemedicine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'A smarter healthcare experience',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Access secure consultations, medical records, and care plans from patients and providers in one polished platform.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _HeroFeature(
                    icon: Icons.security,
                    text: 'Encrypted communication',
                  ),
                  _HeroFeature(
                    icon: Icons.video_call,
                    text: 'Video consultations',
                  ),
                  _HeroFeature(
                    icon: Icons.medical_services,
                    text: 'Medical history at a glance',
                  ),
                  _HeroFeature(
                    icon: Icons.verified,
                    text: 'Trusted and compliant',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _patientRegisterButton({required bool signUp}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: signUp
            ? () => controller.toggleMode(false)
            : () {
                controller.select(AccountType.patient);
                controller.toggleMode(true);
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: GithubTheme.secondary,
          side: const BorderSide(color: GithubTheme.secondary),
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          elevation: 0,
        ),
        child: Text(
          signUp ? 'Back to Sign In' : 'Register Patient',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!adminLoginOnly &&
        controller.currentAccountType != AccountType.patient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.select(AccountType.patient);
        controller.toggleMode(false);
      });
    }

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: GithubTheme.loginBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact = constraints.maxWidth < 900;

                    final Widget formCard = ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Obx(() {
                          final bool loading = controller.isLoading.value;
                          final bool signUp = controller.isSignUpMode.value;
                          final bool isAdmin = controller.isAdminSelected;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (adminLoginOnly || signUp)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: adminLoginOnly
                                          ? Get.back
                                          : () => controller.toggleMode(false),
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        color: GithubTheme.primary,
                                      ),
                                      tooltip: 'Back',
                                    ),
                                  ),
                                ),
                              // Header Section
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: GithubTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      adminLoginOnly
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.person_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          _titleText(
                                            signUp: signUp,
                                            adminLogin: adminLoginOnly,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: GithubTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _subtitleText(
                                            signUp: signUp,
                                            adminLogin: adminLoginOnly,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: GithubTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 24),

                              if (isAdmin) ...<Widget>[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: GithubTheme.warning.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: GithubTheme.warning.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.info_outline,
                                        color: GithubTheme.warning,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Admin accounts are provisioned by the system owner.',
                                          style: TextStyle(
                                            color: GithubTheme.warning,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Email Field
                              TextFormField(
                                controller: controller.emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !loading,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'name@example.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: GithubTheme.textSecondary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              Obx(() {
                                return TextFormField(
                                  controller: controller.passwordController,
                                  obscureText: !showPassword.value,
                                  enabled: !loading,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: signUp
                                        ? 'Create a strong password'
                                        : 'Enter your password',
                                    helperText: signUp
                                        ? 'Use at least 8 characters for better security.'
                                        : null,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: GithubTheme.textSecondary,
                                    ),
                                    suffixIcon: IconButton(
                                      splashRadius: 22,
                                      icon: Icon(
                                        showPassword.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: GithubTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        showPassword.value =
                                            !showPassword.value;
                                      },
                                    ),
                                  ),
                                );
                              }),

                              if (signUp) ...<Widget>[
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: controller.fullNameController,
                                  enabled: !loading,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: GithubTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: controller.phoneController,
                                  enabled: !loading,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: '+966 5XX XXXX XXX',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: GithubTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: controller.bioController,
                                  enabled: !loading,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Health summary (optional)',
                                    hintText:
                                        'Briefly describe your health goals or conditions',
                                    prefixIcon: Icon(
                                      Icons.health_and_safety_outlined,
                                      color: GithubTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],

                              if (signUp) ...<Widget>[
                                const SizedBox(height: 16),
                                Obx(() {
                                  final double strength =
                                      controller.passwordStrength.value;
                                  Color color = GithubTheme.error;
                                  String label = 'Weak';
                                  if (strength >= 0.7) {
                                    color = GithubTheme.success;
                                    label = 'Strong';
                                  } else if (strength >= 0.35) {
                                    color = GithubTheme.warning;
                                    label = 'Medium';
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Password Strength: $label',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: strength,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(3),
                                        backgroundColor: GithubTheme.border,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                      ),
                                    ],
                                  );
                                }),
                              ],

                              const SizedBox(height: 24),

                              // Remember Me
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                  const Expanded(
                                    child: Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: GithubTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Error Message
                              if (controller.errorMessage.value.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: GithubTheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: GithubTheme.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.error_outline,
                                        color: GithubTheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          controller.errorMessage.value,
                                          style: const TextStyle(
                                            color: GithubTheme.error,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Confirmation Button
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: loading
                                      ? null
                                      : controller.submitAuth,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: GithubTheme.secondary,
                                    shadowColor: GithubTheme.secondary.withValues(alpha: 0.25),
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          loading
                                              ? (signUp
                                                    ? 'Creating your account...'
                                                    : 'Signing you in...')
                                              : (signUp
                                                    ? 'Create My Account'
                                                    : 'Sign In Securely'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),


                              const SizedBox(height: 16),
                              if (!adminLoginOnly) ...<Widget>[
                                _patientRegisterButton(signUp: signUp),
                                const SizedBox(height: 16),
                              ],

                              // Footer Text
                              const Center(
                                child: Text(
                                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                                  style: TextStyle(
                                    color: GithubTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  );

                    final Widget animatedFormCard = TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 700),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double value, Widget? child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: formCard,
                    );

                    if (compact) {
                      return Column(
                        children: <Widget>[
                          animatedFormCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: _heroPanel(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        SizedBox(width: 480, child: formCard),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
