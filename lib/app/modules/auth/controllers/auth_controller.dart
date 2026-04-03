import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';

enum AccountType { patient, doctor, admin }

class AuthController extends GetxController {
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _rememberedEmailKey = 'auth_remembered_email';
  static const String _rememberedRoleKey = 'auth_remembered_role';

  final Rxn<AccountType> selectedAccountType = Rxn<AccountType>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSignUpMode = false.obs;
  final RxBool rememberMe = false.obs;
  final RxDouble passwordStrength = 0.0.obs;
  final RxString errorMessage = ''.obs;

  bool get isSupabaseConfigured => SupabaseService.isConfigured;

  AccountType get currentAccountType =>
      selectedAccountType.value ?? AccountType.patient;

  String get currentAccountLabel {
    if (currentAccountType == AccountType.patient) {
      return 'Patient';
    }
    if (currentAccountType == AccountType.doctor) {
      return 'Doctor';
    }
    return 'Admin';
  }

  bool get isAdminSelected => currentAccountType == AccountType.admin;

  String get passwordStrengthLabel {
    final double score = passwordStrength.value;
    if (score < 0.35) {
      return 'Weak';
    }
    if (score < 0.7) {
      return 'Medium';
    }
    return 'Strong';
  }

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_handlePasswordChanged);
    _restoreRememberedAuthState();
  }

  void select(AccountType type) {
    selectedAccountType.value = type;
    if (type == AccountType.admin && isSignUpMode.value) {
      isSignUpMode.value = false;
    }
    errorMessage.value = '';
  }

  void openLoginFor(AccountType type) {
    select(type);
    errorMessage.value = '';
    isSignUpMode.value = false;
    Get.toNamed(AppRoutes.login);
  }

  void toggleMode(bool signUp) {
    if (signUp && isAdminSelected) {
      errorMessage.value =
          'Admin accounts are created manually by system owner.';
      return;
    }
    isSignUpMode.value = signUp;
    errorMessage.value = '';
  }

  Future<void> handleAppStart() async {
    if (!isSupabaseConfigured) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final User? user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final Map<String, dynamic> authContext = await _resolveAuthContext(user);
    final String role =
        authContext['role']?.toString() ?? AccountType.patient.name;

    if (role == AccountType.admin.name) {
      Get.offAllNamed(AppRoutes.admin);
    } else if (role == AccountType.doctor.name) {
      Get.offAllNamed(AppRoutes.doctor);
    } else {
      Get.offAllNamed(AppRoutes.patient);
    }
  }

  Future<void> submitAuth() async {
    errorMessage.value = '';

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Email and password are required.';
      return;
    }

    if (isSignUpMode.value && passwordStrength.value < 0.35) {
      errorMessage.value = 'Choose a stronger password to continue.';
      return;
    }

    if (!isSupabaseConfigured) {
      errorMessage.value =
          'Supabase is not configured. Use SUPABASE_URL and SUPABASE_ANON_KEY.';
      return;
    }

    try {
      isLoading.value = true;

      User? user;
      if (isSignUpMode.value) {
        if (isAdminSelected) {
          errorMessage.value =
              'Admin account is special and must be created by system owner.';
          return;
        }

        final AuthResponse response = await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
          data: <String, dynamic>{'role': currentAccountType.name},
        );
        user = response.user;

        if (user != null) {
          await _upsertProfile(
            userId: user.id,
            role: currentAccountType.name,
            fullName: email.split('@').first,
          );
        }

        if (response.session == null) {
          final AuthResponse signInResponse = await SupabaseService.client.auth
              .signInWithPassword(email: email, password: password);
          user = signInResponse.user;
        }
      } else {
        final AuthResponse response = await SupabaseService.client.auth
            .signInWithPassword(email: email, password: password);
        user = response.user;
      }

      final Map<String, dynamic> authContext = await _resolveAuthContext(user);
      final String role =
          authContext['role']?.toString() ?? currentAccountType.name;

      if (user == null) {
        errorMessage.value =
            'Signup succeeded but session was not created. Disable email confirmation in Supabase Auth settings.';
        isSignUpMode.value = false;
        return;
      }

      if (role != currentAccountType.name) {
        await SupabaseService.client.auth.signOut();
        errorMessage.value =
            'Selected role does not match this account. Please choose the correct role.';
        return;
      }

      await _saveRememberedAuthState();

      if (role == AccountType.admin.name) {
        Get.offAllNamed(AppRoutes.admin);
      } else if (role == AccountType.doctor.name) {
        Get.offAllNamed(AppRoutes.doctor);
      } else {
        Get.offAllNamed(AppRoutes.patient);
      }
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Unexpected error happened during authentication.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetLink() async {
    errorMessage.value = '';
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      errorMessage.value = 'Enter your email first to reset password.';
      return;
    }

    if (!isSupabaseConfigured) {
      errorMessage.value =
          'Supabase is not configured. Use SUPABASE_URL and SUPABASE_ANON_KEY.';
      return;
    }

    try {
      isLoading.value = true;
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      Get.snackbar(
        'Reset Link Sent',
        'Check your inbox for password reset instructions.',
      );
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Unable to send reset link right now.';
    } finally {
      isLoading.value = false;
    }
  }

  void setRememberMe(bool value) {
    rememberMe.value = value;
  }

  Future<void> _upsertProfile({
    required String userId,
    required String role,
    String? fullName,
  }) async {
    await SupabaseService.client.from('profiles').upsert(<String, dynamic>{
      'id': userId,
      'role': role,
      'full_name': fullName,
      'is_approved': true,
    }, onConflict: 'id');
  }

  Future<Map<String, dynamic>> _resolveAuthContext(User? user) async {
    if (user == null) {
      return <String, dynamic>{
        'role': currentAccountType.name,
        'isApproved': true,
      };
    }

    try {
      final dynamic profile = await SupabaseService.client
          .from('profiles')
          .select('role, is_approved')
          .eq('id', user.id)
          .maybeSingle();

      if (profile is Map<String, dynamic>) {
        final dynamic roleValue = profile['role'];
        if (roleValue is String && roleValue.isNotEmpty) {
          return <String, dynamic>{
            'role': roleValue,
            'isApproved': profile['is_approved'] == true,
          };
        }
      }
    } catch (_) {
      // Fallback below.
    }

    final dynamic metadataRole = user.userMetadata?['role'];
    if (metadataRole is String && metadataRole.isNotEmpty) {
      return <String, dynamic>{
        'role': metadataRole,
        'isApproved': metadataRole == AccountType.admin.name,
      };
    }

    return <String, dynamic>{
      'role': currentAccountType.name,
      'isApproved': true,
    };
  }

  void _handlePasswordChanged() {
    passwordStrength.value = _calculatePasswordStrength(
      passwordController.text,
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return 0;
    }

    double score = 0;
    if (password.length >= 8) {
      score += 0.3;
    } else if (password.length >= 6) {
      score += 0.15;
    }
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 0.2;
    }
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 0.2;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 0.15;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score += 0.15;
    }

    return score.clamp(0, 1);
  }

  Future<void> _restoreRememberedAuthState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool shouldRemember = prefs.getBool(_rememberMeKey) ?? false;
    rememberMe.value = shouldRemember;

    if (!shouldRemember) {
      return;
    }

    emailController.text = prefs.getString(_rememberedEmailKey) ?? '';
    final String? storedRole = prefs.getString(_rememberedRoleKey);
    if (storedRole == null) {
      return;
    }

    for (final AccountType type in AccountType.values) {
      if (type.name == storedRole) {
        selectedAccountType.value = type;
        break;
      }
    }
  }

  Future<void> _saveRememberedAuthState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe.value);

    if (rememberMe.value) {
      await prefs.setString(_rememberedEmailKey, emailController.text.trim());
      await prefs.setString(_rememberedRoleKey, currentAccountType.name);
      return;
    }

    await prefs.remove(_rememberedEmailKey);
    await prefs.remove(_rememberedRoleKey);
  }

  Future<void> logout() async {
    if (isSupabaseConfigured) {
      await SupabaseService.client.auth.signOut();
    }
    if (!rememberMe.value) {
      emailController.clear();
    }
    passwordController.clear();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    passwordController.removeListener(_handlePasswordChanged);
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
