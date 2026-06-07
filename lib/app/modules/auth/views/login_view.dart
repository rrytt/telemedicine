import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  
  // Custom app name - can be customized
  final String appName = 'Telemedicine';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFFEFF3FC),
              Color(0xFFD9E2EF),
              Color(0xFFC9D5E8),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildGlassCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Obx(() {
              final bool loading = controller.isLoading.value;
              final bool signUp = controller.isSignUpMode.value;
              final bool isAdmin = controller.isAdminSelected;

              return Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button if needed
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
                              color: Color(0xFF3B82F6),
                            ),
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),

                    // App Name with gradient
                    Center(
                      child: Text(
                        appName,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF1F2F4F), Color(0xFF2C4C7C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Welcome text
                    Center(
                      child: Text(
                        signUp ? 'Create your Patient account' : 'Welcome Back!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F3A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A627A),
                            height: 1.4,
                          ),
                          children: [
                            if (!signUp)
                              // ignore: prefer_const_constructors
                              TextSpan(
                                text: 'To sign in, please enter your $appName credentials. ',
                              )
                            else
                              const TextSpan(
                                text: 'Register as a patient to start your telemedicine care journey. ',
                              ),
                            if (!signUp && !adminLoginOnly)
                              TextSpan(
                                text: "Can't remember credentials? ",
                                style: const TextStyle(color: Color(0xFF5B6E82)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (!signUp && !adminLoginOnly)
                      Center(
                        child: GestureDetector(
                          onTap: controller.handleResetPassword,
                          child: const Text(
                            'Reset password',
                            style: TextStyle(
                              color: Color(0xFF2C6E9E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Admin warning
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEA500).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFEA500).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFFEA500),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin accounts are provisioned by the system owner.',
                                style: TextStyle(
                                  color: Color(0xFFFEA500),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email field
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !loading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email or username is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email or Username',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5C6F87),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF8DA0B5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password field
                    Obx(() {
                      return TextFormField(
                        controller: controller.passwordController,
                        obscureText: !showPassword.value,
                        enabled: !loading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (signUp && value.length < 8) {
                            return 'Use at least 8 characters for better security';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5C6F87),
                          ),
                          helperText:
                              signUp ? 'Use at least 8 characters for better security.' : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF8DA0B5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF8DA0B5),
                            ),
                            onPressed: () {
                              showPassword.value = !showPassword.value;
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Reset password link (sign in mode only)
                    if (!signUp && !adminLoginOnly)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.handleResetPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Reset Password',
                            style: TextStyle(
                              color: Color(0xFF2C6E9E),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Sign-up additional fields
                    if (signUp) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: controller.fullNameController,
                        enabled: !loading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5C6F87),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF8DA0B5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.phoneController,
                        enabled: !loading,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+966 5XX XXXX XXX',
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5C6F87),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF8DA0B5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.bioController,
                        enabled: !loading,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Health summary (optional)',
                          hintText: 'Briefly describe your health goals or conditions',
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5C6F87),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.health_and_safety_outlined,
                            color: Color(0xFF8DA0B5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final double strength = controller.passwordStrength.value;
                        Color color = const Color(0xFFEF4444);
                        String label = 'Weak';
                        if (strength >= 0.7) {
                          color = const Color(0xFF10B981);
                          label = 'Strong';
                        } else if (strength >= 0.35) {
                          color = const Color(0xFFFEA500);
                          label = 'Medium';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ],
                        );
                      }),
                    ],

                    const SizedBox(height: 12),

                    // Remember me
                    if (!signUp && !adminLoginOnly)
                      Row(
                        children: [
                          Obx(() {
                            return Checkbox(
                              value: controller.rememberMe.value,
                              onChanged: loading
                                  ? null
                                  : (bool? value) {
                                      controller.setRememberMe(value ?? false);
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
                                color: Color(0xFF5C6F87),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(height: 12),

                    // Error message
                    if (controller.errorMessage.value.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Fingerprint button (login mode only)
                    if (!signUp && !adminLoginOnly) ...[
                      ElevatedButton.icon(
                        onPressed: loading ? null : controller.handleFingerprintLogin,
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: const Text(
                          'Login using fingerprint or face recognition',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          foregroundColor: const Color(0xFF1F3A4B),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Primary button
                    ElevatedButton(
                      onPressed: loading ? null : controller.submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        loading
                            ? (signUp ? 'Creating your account...' : 'Signing you in...')
                            : (signUp ? 'Create My Account' : 'Log in'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Don't have an account / Back to login
                    if (!adminLoginOnly)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              signUp
                                  ? 'Already have an account?'
                                  : "Don't have an account?",
                              style: const TextStyle(
                                color: Color(0xFF5B6E82),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: loading
                                  ? null
                                  : () => controller.toggleMode(!signUp),
                              child: Text(
                                signUp ? 'Sign in' : 'Sign up',
                                style: const TextStyle(
                                  color: Color(0xFF1E5A7D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Footer
                    const Center(
                      child: Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
