import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';

class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<AuthController>()
      ..select(AccountType.admin)
      ..toggleMode(false);
    return const LoginView();
  }
}
