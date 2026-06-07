import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';

class PatientSettingsController extends GetxController {
  final RxBool appointmentReminders = true.obs;
  final RxBool messageNotifications = true.obs;
  final RxBool healthTipsNotifications = true.obs;
  final RxBool shareHealthData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      appointmentReminders.value =
          prefs.getBool('patient_appointment_reminders') ?? true;
      messageNotifications.value =
          prefs.getBool('patient_message_notifications') ?? true;
      healthTipsNotifications.value =
          prefs.getBool('patient_health_tips_notifications') ?? true;
      shareHealthData.value =
          prefs.getBool('patient_share_health_data') ?? true;
    } catch (e) {
      Get.snackbar('Error', 'Unable to load settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          'patient_appointment_reminders', appointmentReminders.value);
      await prefs.setBool(
          'patient_message_notifications', messageNotifications.value);
      await prefs.setBool(
          'patient_health_tips_notifications', healthTipsNotifications.value);
      await prefs.setBool('patient_share_health_data', shareHealthData.value);
    } catch (e) {
      Get.snackbar('Error', 'Unable to save settings: $e');
    }
  }

  void toggleAppointmentReminders(bool value) {
    appointmentReminders.value = value;
    saveSettings();
  }

  void toggleMessageNotifications(bool value) {
    messageNotifications.value = value;
    saveSettings();
  }

  void toggleHealthTipsNotifications(bool value) {
    healthTipsNotifications.value = value;
    saveSettings();
  }

  void toggleShareHealthData(bool value) {
    shareHealthData.value = value;
    saveSettings();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!SupabaseService.isConfigured) {
        Get.snackbar('Error', 'Authentication service not available');
        return;
      }

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      Get.snackbar('Success', 'Password changed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to change password: $e');
    }
  }

  void openHelpSupport() {
    Get.toNamed(AppRoutes.helpSupport);
  }

  Future<void> sendFeedback(String feedback) async {
    try {
      if (!SupabaseService.isConfigured) {
        Get.snackbar('Error', 'Feedback service not available');
        return;
      }

      final String? userId = SupabaseService.client.auth.currentUser?.id;
      final Map<String, dynamic> feedbackData = {
        'user_id': userId ?? 'anonymous',
        'user_type': 'patient',
        'feedback': feedback,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from('feedback').insert(feedbackData);
      Get.snackbar('Success', 'Feedback sent successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send feedback: $e');
    }
  }

  void openTermsOfService() {
    Get.toNamed(AppRoutes.terms);
  }

  void openPrivacyPolicy() {
    Get.toNamed(AppRoutes.privacy);
  }

  void openAbout() {
    Get.toNamed(AppRoutes.about);
  }
}
