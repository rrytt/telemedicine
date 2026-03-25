import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'modules/admin/views/admin_dashboard_view.dart';
import 'modules/auth/views/account_type_view.dart';
import 'modules/auth/views/login_view.dart';
import 'modules/auth/views/startup_view.dart';
import 'modules/call/views/agora_call_view.dart';
import 'modules/doctor/views/doctor_dashboard_view.dart';
import 'modules/patient/views/patient_dashboard_view.dart';
import 'routes/app_pages.dart';
import 'theme/github_theme.dart';
import 'theme/theme_controller.dart';

class TelemedicineApp extends StatelessWidget {
  const TelemedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Telemedicine Calls',
        theme: GithubTheme.light,
        darkTheme: GithubTheme.dark,
        themeMode: themeController.themeMode.value,
        initialRoute: AppRoutes.splash,
        getPages: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: AppRoutes.splash,
            page: () => const StartupView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.accountType,
            page: () => const AccountTypeView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.login,
            page: () => const LoginView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.patient,
            page: () => const PatientDashboardView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.doctor,
            page: () => const DoctorDashboardView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.admin,
            page: () => const AdminDashboardView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.call,
            page: () => const AgoraCallView(),
          ),
        ],
      );
    });
  }
}
