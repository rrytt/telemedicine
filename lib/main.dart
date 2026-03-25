import 'app/app.dart';
import 'app/core/supabase/supabase_service.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  final ThemeController themeController = ThemeController();
  await themeController.initialize();
  Get.put<ThemeController>(themeController, permanent: true);
  Get.put<AuthController>(AuthController(), permanent: true);

  runApp(const TelemedicineApp());
}
