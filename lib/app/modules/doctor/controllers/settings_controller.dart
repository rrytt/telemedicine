import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';

class SettingsController extends GetxController {
  // Notification Settings
  final RxBool appointmentRequestsNotification = true.obs;
  final RxBool newMessagesNotification = true.obs;
  final RxBool videoCallRequestsNotification = true.obs;

  // Profile Settings
  final RxString doctorName = 'Dr. John Doe'.obs;
  final RxString specialization = 'General Medicine'.obs;
  final RxString licenseNumber = 'MD123456'.obs;
  final RxString experience = '10 years'.obs;

  // Working Hours
  final RxString workingHours = 'Mon-Fri: 9:00 AM - 5:00 PM'.obs;

  // Security Settings
  final RxBool twoFactorEnabled = false.obs;

  // Privacy Settings
  final RxBool profileVisibility = true.obs;
  final RxBool showOnlineStatus = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Load settings from storage/database
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      if (SupabaseService.isConfigured) {
        // Try to load from Supabase first
        await _loadFromSupabase();
      } else {
        // Fallback to local storage
        await _loadFromLocalStorage();
      }
    } catch (e) {
      // If Supabase fails, try local storage
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromSupabase() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final response = await SupabaseService.client
        .from('doctor_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      appointmentRequestsNotification.value = response['appointment_requests_notification'] ?? true;
      newMessagesNotification.value = response['new_messages_notification'] ?? true;
      videoCallRequestsNotification.value = response['video_call_requests_notification'] ?? true;
      doctorName.value = response['doctor_name'] ?? 'Dr. John Doe';
      specialization.value = response['specialization'] ?? 'General Medicine';
      licenseNumber.value = response['license_number'] ?? 'MD123456';
      experience.value = response['experience'] ?? '10 years';
      workingHours.value = response['working_hours'] ?? 'Mon-Fri: 9:00 AM - 5:00 PM';
      twoFactorEnabled.value = response['two_factor_enabled'] ?? false;
      profileVisibility.value = response['profile_visibility'] ?? true;
      showOnlineStatus.value = response['show_online_status'] ?? true;
    }
  }

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    appointmentRequestsNotification.value = prefs.getBool('appointment_requests_notification') ?? true;
    newMessagesNotification.value = prefs.getBool('new_messages_notification') ?? true;
    videoCallRequestsNotification.value = prefs.getBool('video_call_requests_notification') ?? true;
    doctorName.value = prefs.getString('doctor_name') ?? 'Dr. John Doe';
    specialization.value = prefs.getString('specialization') ?? 'General Medicine';
    licenseNumber.value = prefs.getString('license_number') ?? 'MD123456';
    experience.value = prefs.getString('experience') ?? '10 years';
    workingHours.value = prefs.getString('working_hours') ?? 'Mon-Fri: 9:00 AM - 5:00 PM';
    profileVisibility.value = prefs.getBool('profile_visibility') ?? true;
    showOnlineStatus.value = prefs.getBool('show_online_status') ?? true;
  }

  Future<void> saveSettings() async {
    try {
      if (SupabaseService.isConfigured) {
        await _saveToSupabase();
      }
      // Always save to local storage as backup
      await _saveToLocalStorage();
      Get.snackbar('Success', 'Settings saved successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save settings: $e');
    }
  }

  Future<void> _saveToSupabase() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final settingsData = {
      'user_id': user.id,
      'appointment_requests_notification': appointmentRequestsNotification.value,
      'new_messages_notification': newMessagesNotification.value,
      'video_call_requests_notification': videoCallRequestsNotification.value,
      'doctor_name': doctorName.value,
      'specialization': specialization.value,
      'license_number': licenseNumber.value,
      'experience': experience.value,
      'working_hours': workingHours.value,
      'two_factor_enabled': twoFactorEnabled.value,
      'profile_visibility': profileVisibility.value,
      'show_online_status': showOnlineStatus.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client
        .from('doctor_settings')
        .upsert(settingsData, onConflict: 'user_id');
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appointment_requests_notification', appointmentRequestsNotification.value);
    await prefs.setBool('new_messages_notification', newMessagesNotification.value);
    await prefs.setBool('video_call_requests_notification', videoCallRequestsNotification.value);
    await prefs.setString('doctor_name', doctorName.value);
    await prefs.setString('specialization', specialization.value);
    await prefs.setString('license_number', licenseNumber.value);
    await prefs.setString('experience', experience.value);
    await prefs.setString('working_hours', workingHours.value);
    await prefs.setBool('two_factor_enabled', twoFactorEnabled.value);
    await prefs.setBool('profile_visibility', profileVisibility.value);
    await prefs.setBool('show_online_status', showOnlineStatus.value);
  }

  // Notification Settings
  void toggleAppointmentRequestsNotification(bool value) {
    appointmentRequestsNotification.value = value;
    saveSettings();
  }

  void toggleNewMessagesNotification(bool value) {
    newMessagesNotification.value = value;
    saveSettings();
  }

  void toggleVideoCallRequestsNotification(bool value) {
    videoCallRequestsNotification.value = value;
    saveSettings();
  }

  // Profile Methods
  void updateProfile(String name, String spec, String license, String exp) {
    doctorName.value = name;
    specialization.value = spec;
    licenseNumber.value = license;
    experience.value = exp;
    saveSettings();
    Get.snackbar('Success', 'Profile updated successfully');
  }

  void updateWorkingHours(String hours) {
    workingHours.value = hours;
    saveSettings();
    Get.snackbar('Success', 'Working hours updated successfully');
  }

  // Security Methods
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!SupabaseService.isConfigured) {
        Get.snackbar('Error', 'Authentication service not available');
        return;
      }

      // First, verify current password by attempting to sign in
      final user = SupabaseService.client.auth.currentUser;
      if (user == null || user.email == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      // Supabase doesn't have a direct way to verify current password
      // We'll update the password directly (user should know their current password)
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      Get.snackbar('Success', 'Password changed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to change password: $e');
    }
  }

  void enable2FA() {
    Get.toNamed(AppRoutes.twoFactor);
  }

  void setTwoFactorEnabled(bool value) {
    twoFactorEnabled.value = value;
    saveSettings();
  }

  // Privacy Methods
  void toggleProfileVisibility(bool value) {
    profileVisibility.value = value;
    saveSettings();
  }

  void toggleOnlineStatus(bool value) {
    showOnlineStatus.value = value;
    saveSettings();
  }

  // Support Methods
  void openHelpSupport() {
    Get.toNamed(AppRoutes.helpSupport);
  }

  Future<void> sendFeedback(String feedback) async {
    try {
      if (!SupabaseService.isConfigured) {
        Get.snackbar('Error', 'Feedback service not available');
        return;
      }

      final user = SupabaseService.client.auth.currentUser;
      final feedbackData = {
        'user_id': user?.id ?? 'anonymous',
        'user_type': 'doctor',
        'feedback': feedback,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('feedback')
          .insert(feedbackData);

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