import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController controller = Get.find<AuthController>();
  bool _obscurePassword = true;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    controller.emailController.addListener(_onInputChanged);
    controller.passwordController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    setState(() {
      _canSubmit = controller.emailController.text.trim().isNotEmpty &&
          controller.passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    controller.emailController.removeListener(_onInputChanged);
    controller.passwordController.removeListener(_onInputChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/icon.png', width: 40, height: 40, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Text('Telemedicine',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Get.isDarkMode ? const Color(0xFFF1F5F9) : Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text('Welcome Back!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Get.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF4ECDC4)),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 15, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54, height: 1.5),
                  children: const [
                    TextSpan(text: "To Sign in, please enter your Telemedicine credentials. Can't remember credentials? "),
                    TextSpan(text: 'Reset password',
                      style: TextStyle(color: Color(0xFF4ECDC4), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Email or Username',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4ECDC4))),
                ),
              ),
              const SizedBox(height: 20),
              Text('Password',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.grey, size: 20),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4ECDC4))),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: controller.handleResetPassword,
                  child: Text('Reset Password',
                    style: TextStyle(color: const Color(0xFF4ECDC4), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submitAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFF4ECDC4)
                        : (Get.isDarkMode ? const Color(0xFF334155) : const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Obx(() => controller.isLoading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Log in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.register),
                  child: Text("Don't have an account?",
                    style: TextStyle(color: const Color(0xFF4ECDC4), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
