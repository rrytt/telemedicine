import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorSearchItem {
  DoctorSearchItem({
    required this.id,
    required this.name,
    this.specialty,
    this.avatarUrl,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  final String id;
  final String name;
  final String? specialty;
  final String? avatarUrl;
  final double averageRating;
  final int reviewCount;
}

class DoctorSearchController extends GetxController {
  final RxList<DoctorSearchItem> doctors = <DoctorSearchItem>[].obs;
  final RxList<DoctorSearchItem> filteredDoctors = <DoctorSearchItem>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void searchDoctors(String query) {
    if (query.isEmpty) {
      filteredDoctors.assignAll(doctors);
    } else {
      filteredDoctors.assignAll(
        doctors.where(
          (DoctorSearchItem d) =>
              d.name.toLowerCase().contains(query.toLowerCase()) ||
              (d.specialty?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        ),
      );
    }
  }

  Future<String> _signedAvatarUrl(String path) async {
    try {
      return await SupabaseService.client.storage
          .from('avatars')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return '';
    }
  }

  Future<void> loadDoctors() async {
    error.value = '';
    if (!SupabaseService.isConfigured) return;

    try {
      isLoading.value = true;

      final profiles = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, specialty, avatar_url')
          .eq('role', 'doctor')
          .order('full_name', ascending: true);

      final List<dynamic> allRatings = await SupabaseService.client
          .from('doctor_reviews')
          .select('doctor_id, rating');

      final Map<String, List<int>> ratingsByDoctor = {};
      for (final r in allRatings) {
        final map = r as Map<String, dynamic>;
        final docId = map['doctor_id']?.toString() ?? '';
        final rating = (map['rating'] as num?)?.toInt() ?? 0;
        ratingsByDoctor.putIfAbsent(docId, () => []).add(rating);
      }

      final list = await Future.wait(
        (profiles as List<dynamic>).map((dynamic row) async {
          final map = row as Map<String, dynamic>;
          final id = map['id'].toString();
          final avatarPath = map['avatar_url']?.toString() ?? '';
          final avatarUrl =
              avatarPath.isNotEmpty ? await _signedAvatarUrl(avatarPath) : '';

          final ratings = ratingsByDoctor[id] ?? [];
          final avg = ratings.isEmpty
              ? 0.0
              : ratings.reduce((a, b) => a + b) / ratings.length;

          return DoctorSearchItem(
            id: id,
            name: map['full_name']?.toString() ?? 'Doctor',
            specialty: map['specialty']?.toString(),
            avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            averageRating: double.parse(avg.toStringAsFixed(1)),
            reviewCount: ratings.length,
          );
        }),
      );

      doctors.assignAll(list);
      filteredDoctors.assignAll(list);

      if (list.isEmpty) {
        error.value = 'No registered doctors found yet.';
      }
    } catch (e) {
      error.value = 'Failed to load doctors. Please try again later.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendConsultationRequest(String doctorId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      await SupabaseService.client.from('appointments').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': 'Pending',
      });

      Get.snackbar('Request Sent', 'Consultation request sent to doctor');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    }
  }
}
