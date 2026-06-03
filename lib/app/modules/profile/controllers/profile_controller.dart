import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';

class ProfileController extends GetxController {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bloodTypeController = TextEditingController();
  final TextEditingController medicalRecordController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final RxString email = ''.obs;
  final RxString role = ''.obs;
  final RxnString avatarPath = RxnString();
  final RxString avatarUrl = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploading = false.obs;
  final RxString statusMessage = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  String? get currentUserId => SupabaseService.client.auth.currentUser?.id;

  Future<void> loadProfile() async {
    errorMessage.value = '';
    statusMessage.value = '';
    isLoading.value = true;

    final String? userId = currentUserId;
    final String? userEmail = SupabaseService.client.auth.currentUser?.email;

    if (userId == null) {
      errorMessage.value = 'Please sign in to manage your profile.';
      isLoading.value = false;
      return;
    }

    email.value = userEmail ?? '';

    try {
        final dynamic profile = await SupabaseService.client
          .from('profiles')
          .select('role, full_name, avatar_url, phone_number, specialty, bio, blood_type, medical_record')
          .eq('id', userId)
          .maybeSingle();

      if (profile is Map<String, dynamic>) {
        hasProfile.value = true;
        role.value = profile['role']?.toString() ?? '';
        final String fullName = profile['full_name']?.toString() ?? '';
        fullNameController.text = fullName.isNotEmpty
            ? fullName
            : (userEmail ?? '');
        final String avatar = profile['avatar_url']?.toString() ?? '';
        avatarPath.value = avatar.isNotEmpty ? avatar : null;
        if (avatarPath.value != null) {
          avatarUrl.value = await _createSignedAvatarUrl(avatarPath.value!);
        } else {
          avatarUrl.value = '';
        }
        phoneController.text = profile['phone_number']?.toString() ?? '';
        bloodTypeController.text = profile['blood_type']?.toString() ?? '';
        medicalRecordController.text = profile['medical_record']?.toString() ?? '';
        specialtyController.text = profile['specialty']?.toString() ?? '';
        bioController.text = profile['bio']?.toString() ?? '';
      } else {
        hasProfile.value = false;
        role.value = '';
        fullNameController.text = userEmail ?? '';
        phoneController.text = '';
        bloodTypeController.text = '';
        medicalRecordController.text = '';
        specialtyController.text = '';
        bioController.text = '';
        avatarPath.value = null;
        avatarUrl.value = '';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load profile. ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    errorMessage.value = '';
    statusMessage.value = '';

    final String? userId = currentUserId;
    if (userId == null) {
      errorMessage.value = 'Please sign in to save your profile.';
      return;
    }

    final String fullName = fullNameController.text.trim();
    if (fullName.isEmpty) {
      errorMessage.value = 'Please enter your full name.';
      return;
    }

    isSaving.value = true;
    try {
      await _saveProfileFields(userId, <String, dynamic>{
        'full_name': fullName,
        'avatar_url': avatarPath.value,
        'phone_number': phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        'blood_type': bloodTypeController.text.trim().isNotEmpty
          ? bloodTypeController.text.trim()
          : null,
        'medical_record': medicalRecordController.text.trim().isNotEmpty
          ? medicalRecordController.text.trim()
          : null,
        'specialty': specialtyController.text.trim().isNotEmpty
            ? specialtyController.text.trim()
            : null,
        'bio': bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : null,
      });

      statusMessage.value = 'Profile updated successfully.';
      Get.snackbar('Saved', 'Your profile has been updated.');
      await loadProfile();
    } catch (e) {
      errorMessage.value = 'Unable to save profile. ${e.toString()}';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> uploadAvatar() async {
    errorMessage.value = '';
    statusMessage.value = '';

    final String? userId = currentUserId;
    if (userId == null) {
      errorMessage.value = 'Please sign in to upload a profile image.';
      return;
    }

    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final PlatformFile file = picked.files.first;
    final Uint8List? fileBytes = file.bytes;
    if (fileBytes == null || fileBytes.isEmpty) {
      errorMessage.value = 'Unable to read the selected image file.';
      return;
    }

    final String safeName = file.name.replaceAll(' ', '_');
    final String fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final String uploadPath = '$userId/$fileName';

    isUploading.value = true;
    try {
      await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(uploadPath, fileBytes);

      await _saveProfileFields(userId, <String, dynamic>{
        'avatar_url': uploadPath,
      });

      avatarPath.value = uploadPath;
      avatarUrl.value = await _createSignedAvatarUrl(uploadPath);
      statusMessage.value = 'Profile image uploaded successfully.';
      Get.snackbar('Uploaded', 'Profile image updated.');
    } catch (e) {
      errorMessage.value = 'Failed to upload image. ${e.toString()}';
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> _saveProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'id': userId,
      'role': _resolveRole(),
      'is_approved': true,
      ...fields,
    };

    await SupabaseService.client
        .from('profiles')
        .upsert(data, onConflict: 'id');
  }

  String _resolveRole() {
    if (role.value.isNotEmpty) {
      return role.value;
    }

    final dynamic metadataRole =
        SupabaseService.client.auth.currentUser?.userMetadata?['role'];
    if (metadataRole is String && metadataRole.isNotEmpty) {
      return metadataRole;
    }

    return 'patient';
  }

  Future<String> _createSignedAvatarUrl(String path) async {
    try {
          final String signedUrl = await SupabaseService.client.storage
            .from('avatars')
            .createSignedUrl(path, 3600);
          return signedUrl;
    } catch (_) {
      return '';
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    bloodTypeController.dispose();
    medicalRecordController.dispose();
    specialtyController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
