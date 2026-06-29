import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthController controller = Get.find<AuthController>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    controller.emailController.text = _emailController.text.trim();
    controller.passwordController.text = _passwordController.text;
    controller.fullNameController.text = _nameController.text.trim();
    controller.phoneController.text = _phoneController.text.trim();
    controller.isSignUpMode.value = true;
    await controller.submitAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/icon.png', width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Telemedicine',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Get.isDarkMode ? const Color(0xFFF1F5F9) : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Create Account
              Text(
                'Create Account!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign up to start your telemedicine journey.',
                style: TextStyle(
                  fontSize: 15,
                  color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Full Name
              Text(
                'Full Name',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              // Email
              Text(
                'Email',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              // Phone Number
              Text(
                'Phone Number',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              // Password
              Text(
                'Password',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Confirm Password
              Text(
                'Confirm Password',
                style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration(
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Already have an account?
              Center(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: const Color(0xFF4ECDC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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

  InputDecoration _inputDecoration({Widget? suffix}) {
    return InputDecoration(
      hintText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
      ),
    );
  }
}
