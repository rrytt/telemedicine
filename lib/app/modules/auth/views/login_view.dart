import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Obx(() {
                final bool loading = controller.isLoading.value;
                final bool signUp = controller.isSignUpMode.value;
                final bool isAdmin = controller.isAdminSelected;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      signUp ? 'Create ${controller.currentAccountLabel} Account' : 'Login as ${controller.currentAccountLabel}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Supabase authentication with role-based routing.',
                      style: TextStyle(color: GithubTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: GithubTheme.bg,
                        borderRadius: BorderRadius.circular(6),
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
                                'Login',
                                style: TextStyle(
                                  color: signUp
                                      ? GithubTheme.textSecondary
                                      : GithubTheme.textPrimary,
                                  fontWeight:
                                      signUp ? FontWeight.w400 : FontWeight.w700,
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
                                'Sign Up',
                                style: TextStyle(
                                  color: signUp
                                      ? GithubTheme.textPrimary
                                      : GithubTheme.textSecondary,
                                  fontWeight:
                                      signUp ? FontWeight.w700 : FontWeight.w400,
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
                          'Admin accounts are created manually by system owner.',
                          style: TextStyle(
                            color: GithubTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !loading,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      enabled: !loading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.errorMessage.value.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBE9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCF222E)),
                        ),
                        child: Text(
                          controller.errorMessage.value,
                          style: const TextStyle(
                            color: Color(0xFFCF222E),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : controller.submitAuth,
                        child: Text(loading
                            ? 'Please wait...'
                            : signUp
                                ? 'Create Account'
                                : 'Login'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: loading ? null : Get.back,
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
