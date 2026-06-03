import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'modules/admin/views/admin_accounts_view.dart';
import 'modules/admin/views/admin_complaints_view.dart';
import 'modules/admin/views/admin_dashboard_view.dart';
import 'modules/auth/views/account_type_view.dart';
import 'modules/auth/views/login_view.dart';
import 'modules/auth/views/admin_login_view.dart';
import 'modules/auth/views/startup_view.dart';
import 'modules/call/views/agora_call_view.dart';
import 'modules/doctor/views/doctor_chat_view.dart';
import 'modules/doctor/views/doctor_dashboard_view.dart';
import 'modules/doctor/views/settings_view.dart';
import 'modules/doctor/views/two_factor_view.dart';
import 'modules/doctor/views/help_support_view.dart';
import 'modules/doctor/views/terms_of_service_view.dart';
import 'modules/doctor/views/privacy_policy_view.dart';
import 'modules/doctor/views/about_view.dart';
import 'modules/patient/views/chat_view.dart';
import 'modules/patient/views/patient_dashboard_view.dart';
import 'modules/patient/views/patient_profile_view.dart';
import 'modules/profile/views/doctor_profile_view.dart';
import 'modules/profile/views/public_profile_view.dart';
import 'routes/app_pages.dart';
import 'theme/github_theme.dart';
import 'theme/theme_controller.dart';
import 'modules/doctor/doctor_binding.dart';

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
            page: () => LoginView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.adminLogin,
            page: () => const AdminLoginView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.patient,
            page: () => const PatientDashboardView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.patientProfile,
            page: () => const PatientProfileView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.doctorProfile,
            page: () => const DoctorProfileView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.publicProfile,
            page: () => const PublicProfileView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.doctor,
            page: () => const DoctorDashboardView(),
            binding: DoctorBinding(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.admin,
            page: () => const AdminDashboardView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.adminAccounts,
            page: () => const AdminAccountsView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.adminComplaints,
            page: () => const AdminComplaintsView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.call,
            page: () => const AgoraCallView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.chat,
            page: () => const ChatView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.doctorChat,
            page: () => const DoctorChatView(),
            binding: DoctorBinding(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.settings,
            page: () => const SettingsView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.twoFactor,
            page: () => const TwoFactorView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.helpSupport,
            page: () => const HelpSupportView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.terms,
            page: () => const TermsOfServiceView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.privacy,
            page: () => const PrivacyPolicyView(),
          ),
          GetPage<dynamic>(
            name: AppRoutes.about,
            page: () => const AboutView(),
          ),
        ],
      );
    });
  }
}
