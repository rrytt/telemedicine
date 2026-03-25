import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';

enum AccountType { patient, doctor, admin }

class AuthController extends GetxController {
  final Rxn<AccountType> selectedAccountType = Rxn<AccountType>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSignUpMode = false.obs;
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

  void select(AccountType type) {
    selectedAccountType.value = type;
  }

  void openLoginFor(AccountType type) {
    select(type);
    errorMessage.value = '';
    isSignUpMode.value = false;
    Get.toNamed(AppRoutes.login);
  }

  void toggleMode(bool signUp) {
    isSignUpMode.value = signUp;
    errorMessage.value = '';
  }

  Future<void> handleAppStart() async {
    if (!isSupabaseConfigured) {
      Get.offAllNamed(AppRoutes.accountType);
      return;
    }

    final User? user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.accountType);
      return;
    }

    final Map<String, dynamic> authContext = await _resolveAuthContext(user);
    final String role = authContext['role']?.toString() ?? AccountType.patient.name;
    final bool isApproved = authContext['isApproved'] == true;

    if (role != AccountType.admin.name && !isApproved) {
      await SupabaseService.client.auth.signOut();
      Get.offAllNamed(AppRoutes.accountType);
      return;
    }

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
          data: <String, dynamic>{
            'role': currentAccountType.name,
          },
        );
        user = response.user;

        if (user == null) {
          errorMessage.value =
              'Signup completed. Check your email to verify then login.';
          isSignUpMode.value = false;
          return;
        }

        await _upsertProfile(
          userId: user.id,
          role: currentAccountType.name,
          fullName: email.split('@').first,
        );
      } else {
        final AuthResponse response =
            await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        user = response.user;
      }

      final Map<String, dynamic> authContext = await _resolveAuthContext(user);
      final String role = authContext['role']?.toString() ?? currentAccountType.name;
      final bool isApproved = authContext['isApproved'] == true;

      if (role != AccountType.admin.name && !isApproved) {
        await SupabaseService.client.auth.signOut();
        errorMessage.value =
            'Your account is pending admin approval. Please wait.';
        return;
      }

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

  Future<void> _upsertProfile({
    required String userId,
    required String role,
    String? fullName,
  }) async {
    await SupabaseService.client.from('profiles').upsert(
      <String, dynamic>{
        'id': userId,
        'role': role,
        'full_name': fullName,
        'is_approved': false,
      },
      onConflict: 'id',
    );
  }

  Future<Map<String, dynamic>> _resolveAuthContext(User? user) async {
    if (user == null) {
      return <String, dynamic>{
        'role': currentAccountType.name,
        'isApproved': false,
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
      'isApproved': false,
    };
  }

  Future<void> logout() async {
    if (isSupabaseConfigured) {
      await SupabaseService.client.auth.signOut();
    }
    emailController.clear();
    passwordController.clear();
    Get.offAllNamed(AppRoutes.accountType);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
