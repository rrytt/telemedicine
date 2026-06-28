import 'app/app.dart';
import 'app/core/supabase/supabase_service.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase
    await SupabaseService.initialize().timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  // Initialize Theme
  final ThemeController themeController = ThemeController();
  await themeController.initialize();
  Get.put<ThemeController>(themeController, permanent: true);

  // Initialize Auth
  Get.put<AuthController>(AuthController(), permanent: true);

  runApp(const TelemedicineApp());
}
