import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';

class ProfileController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var profile = Rxn<ProfileModel>();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  // جلب بيانات البروفايل للمستخدم الحالي
  Future<void> fetchProfile() async {
    try {
      isLoading(true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      profile.value = ProfileModel.fromJson(data);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile: $e');
    } finally {
      isLoading(false);
    }
  }

  // تحديث بيانات البروفايل
  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    try {
      isLoading(true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('profiles')
          .update(updatedProfile.toJson())
          .eq('id', userId);

      profile.value = updatedProfile;
      Get.snackbar('Success', 'Profile updated successfully');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Update failed: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  // رفع الصورة الشخصية وتحديث الرابط في قاعدة البيانات
  Future<void> uploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // تقليل الحجم لسرعة الرفع
    );

    if (image == null) return;

    try {
      isLoading(true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // الرفع إلى Supabase Storage (يجب أن يكون الـ bucket باسم avatars)
      await _supabase.storage.from('avatars').upload(filePath, file);

      // الحصول على الرابط العام للصورة
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // تحديث البروفايل بالرابط الجديد مباشرة
      if (profile.value != null) {
        await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);
        await fetchProfile(); // تحديث البيانات المحلية
      }
    } catch (e) {
      Get.snackbar('Error', 'Upload failed: $e');
    } finally {
      isLoading(false);
    }
  }

  bool get isDoctor => profile.value?.role == UserRole.doctor;
  bool get isPatient => profile.value?.role == UserRole.patient;
}