import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'login_view.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final AuthController controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.select(AccountType.admin);
      controller.toggleMode(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      hideRoleSelection: true,
      adminLoginOnly: true,
    );
  }
}
