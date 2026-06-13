import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/doctor_posts_service.dart';
import '../../../core/supabase/doctor_reviews_service.dart';
import '../../../core/supabase/supabase_service.dart';

class AdminAccountItem {
  const AdminAccountItem({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isApproved,
    this.email,
    this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String role;
  final bool isApproved;
  final String? email;
  final String? createdAt;
  final String? avatarUrl;
}

class AdminComplaintItem {
  const AdminComplaintItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.patientName,
    this.doctorName,
    this.adminResponse,
  });

  final String id;
  final String title;
  final String body;
  final String status;
  final String patientName;
  final String? doctorName;
  final String? adminResponse;
}

class AdminPostItem {
  const AdminPostItem({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.doctorName,
    this.doctorAvatarUrl,
  });

  final String id;
  final String doctorId;
  final String title;
  final String body;
  final String createdAt;
  final String? doctorName;
  final String? doctorAvatarUrl;
}

class AdminReviewItem {
  const AdminReviewItem({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    this.doctorName,
    this.patientName,
    this.doctorAvatarUrl,
    this.patientAvatarUrl,
  });

  final String id;
  final String doctorId;
  final String patientId;
  final int rating;
  final String? reviewText;
  final String createdAt;
  final String? doctorName;
  final String? patientName;
  final String? doctorAvatarUrl;
  final String? patientAvatarUrl;
}

class AdminStats {
  const AdminStats({
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalAdmins,
    required this.totalAppointments,
    required this.totalComplaints,
    required this.openComplaints,
    required this.totalPosts,
  });

  final int totalPatients;
  final int totalDoctors;
  final int totalAdmins;
  final int totalAppointments;
  final int totalComplaints;
  final int openComplaints;
  final int totalPosts;

  int get totalUsers => totalPatients + totalDoctors + totalAdmins;
}

class AdminController extends GetxController {
  final RxList<AdminAccountItem> accounts = <AdminAccountItem>[].obs;
  final RxList<AdminComplaintItem> complaints = <AdminComplaintItem>[].obs;
  final RxList<AdminPostItem> posts = <AdminPostItem>[].obs;
  final RxList<AdminReviewItem> reviews = <AdminReviewItem>[].obs;

  final RxBool isLoadingAccounts = false.obs;
  final RxBool isLoadingComplaints = false.obs;
  final RxBool isLoadingPosts = false.obs;
  final RxBool isLoadingReviews = false.obs;
  final RxString accountsError = ''.obs;
  final RxString complaintsError = ''.obs;
  final RxString postsError = ''.obs;
  final RxString reviewsError = ''.obs;

  final Rx<AdminStats?> stats = Rx<AdminStats?>(null);
  final RxBool isLoadingStats = false.obs;
  final RxString statsError = ''.obs;

  final RxString searchQuery = ''.obs;

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadAccounts();
    loadComplaints();
    loadPosts();
    loadReviews();
  }

  String _friendlyError(Object error, String fallback) {
    final String message = error.toString();
    final String lower = message.toLowerCase();
    if (lower.contains('permission denied') || lower.contains('row-level security')) {
      return '$fallback You do not have admin permissions (RLS).';
    }
    if (lower.contains('jwt') || lower.contains('auth')) {
      return '$fallback Session/auth issue. Please login again.';
    }
    if (lower.contains('stack depth limit exceeded') || lower.contains('54001')) {
      return '$fallback Database RLS recursion detected (Postgres 54001).';
    }
    if (message.isEmpty) return fallback;
    return '$fallback $message';
  }

  List<AdminAccountItem> get patientAccounts =>
      accounts.where((a) => a.role == 'patient').toList();
  List<AdminAccountItem> get doctorAccounts =>
      accounts.where((a) => a.role == 'doctor').toList();
  List<AdminAccountItem> get adminAccountsList =>
      accounts.where((a) => a.role == 'admin').toList();

  List<AdminAccountItem> searchPatients(String query) {
    if (query.isEmpty) return patientAccounts;
    final q = query.toLowerCase();
    return patientAccounts.where((a) =>
        a.fullName.toLowerCase().contains(q) ||
        a.id.toLowerCase().contains(q)).toList();
  }

  List<AdminAccountItem> searchDoctors(String query) {
    if (query.isEmpty) return doctorAccounts;
    final q = query.toLowerCase();
    return doctorAccounts.where((a) =>
        a.fullName.toLowerCase().contains(q) ||
        a.id.toLowerCase().contains(q)).toList();
  }

  List<AdminAccountItem> searchAdmins(String query) {
    if (query.isEmpty) return adminAccountsList;
    final q = query.toLowerCase();
    return adminAccountsList.where((a) =>
        a.fullName.toLowerCase().contains(q) ||
        a.id.toLowerCase().contains(q)).toList();
  }

  static Future<String> _createSignedAvatarUrl(String path) async {
    if (path.isEmpty) return '';
    try {
      return await SupabaseService.client.storage
          .from('avatars')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return '';
    }
  }

  Future<void> loadStats() async {
    if (!SupabaseService.isConfigured) {
      statsError.value = 'Supabase is not configured.';
      return;
    }
    try {
      isLoadingStats.value = true;
      statsError.value = '';

      final profiles = await SupabaseService.client
          .from('profiles').select('role').limit(500) as List<dynamic>;
      final appointments = await SupabaseService.client
          .from('appointments').select('id').limit(500) as List<dynamic>;
      final complaintsRaw = await SupabaseService.client
          .from('complaints').select('status').limit(300) as List<dynamic>;
      final posts = await SupabaseService.client
          .from('doctor_posts').select('id').limit(500) as List<dynamic>;

      final appointmentCount = appointments.length;
      final postCount = posts.length;

      int patients = 0, doctors = 0, admins = 0;
      for (final row in profiles) {
        final role = (row as Map<String, dynamic>)['role']?.toString() ?? '';
        if (role == 'patient') {
          patients++;
        } else if (role == 'doctor') {
          doctors++;
        } else if (role == 'admin') {
          admins++;
        }
      }

      int openComplaints = 0;
      for (final row in complaintsRaw) {
        final status = (row as Map<String, dynamic>)['status']?.toString() ?? '';
        if (status == 'open') openComplaints++;
      }

      stats.value = AdminStats(
        totalPatients: patients,
        totalDoctors: doctors,
        totalAdmins: admins,
        totalAppointments: appointmentCount,
        totalComplaints: complaintsRaw.length,
        openComplaints: openComplaints,
        totalPosts: postCount,
      );
    } catch (e) {
      statsError.value = _friendlyError(e, 'Failed to load stats.');
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> loadAccounts() async {
    accountsError.value = '';
    if (!SupabaseService.isConfigured) {
      accountsError.value = 'Supabase is not configured.';
      return;
    }
    try {
      isLoadingAccounts.value = true;
      final userId = _currentUserId;
      if (userId == null) {
        accountsError.value = 'No active session. Please login again.';
        return;
      }

      final response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, role, is_approved, avatar_url, created_at')
          .order('created_at', ascending: false)
          .limit(300);

      final rawItems = (response as List<dynamic>).map((dynamic row) {
        final map = row as Map<String, dynamic>;
        return (
          id: map['id']?.toString() ?? '',
          fullName: map['full_name']?.toString() ?? 'Unknown',
          role: map['role']?.toString() ?? 'patient',
          isApproved: map['is_approved'] == true,
          email: map['email']?.toString(),
          createdAt: map['created_at']?.toString(),
          avatarPath: map['avatar_url']?.toString() ?? '',
        );
      }).toList();

      final signedUrls = await Future.wait(
        rawItems.map((item) => _createSignedAvatarUrl(item.avatarPath)),
      );

      accounts.assignAll(List<AdminAccountItem>.generate(rawItems.length, (int i) {
        final item = rawItems[i];
        return AdminAccountItem(
          id: item.id,
          fullName: item.fullName,
          role: item.role,
          isApproved: item.isApproved,
          email: item.email,
          createdAt: item.createdAt,
          avatarUrl: signedUrls[i],
        );
      }));
    } catch (e) {
      accountsError.value = _friendlyError(e, 'Failed to load accounts.');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  Future<void> approveAccount(String accountId, bool approved) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'is_approved': approved}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', approved ? 'Account approved.' : 'Approval revoked.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account approval.');
    }
  }

  Future<void> updateAccountRole(String accountId, String role) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'role': role}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', 'Account role updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account role.');
    }
  }

  Future<void> updateAccountName(String accountId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'full_name': trimmed}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', 'Account name updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account name.');
    }
  }

  Future<void> createDoctorAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = fullName.trim();
    if (trimmedEmail.isEmpty || password.isEmpty || trimmedName.isEmpty) {
      Get.snackbar('Validation', 'Email, full name, and password are required.');
      return;
    }
    if (!SupabaseService.isConfigured) {
      Get.snackbar('Configuration', 'Supabase is not configured.');
      return;
    }
    try {
      isLoadingAccounts.value = true;
      final response = await SupabaseService.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'role': 'doctor'},
      );
      final user = response.user;
      if (user != null) {
        await SupabaseService.client.from('profiles').upsert({
          'id': user.id,
          'role': 'doctor',
          'full_name': trimmedName,
          'is_approved': true,
        }, onConflict: 'id');
      }
      await loadAccounts();
      Get.snackbar('Doctor Registered',
          user != null ? 'Doctor account created.' : 'Confirm email if required.');
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (_) {
      Get.snackbar('Error', 'Failed to create doctor account.');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (accountId == _currentUserId) {
      Get.snackbar('Blocked', 'You cannot delete your own admin account.');
      return;
    }
    try {
      await SupabaseService.client.from('profiles').delete().eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Deleted', 'Account removed.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete account.');
    }
  }

  Future<void> loadComplaints() async {
    complaintsError.value = '';
    if (!SupabaseService.isConfigured) {
      complaintsError.value = 'Supabase is not configured.';
      return;
    }
    try {
      isLoadingComplaints.value = true;
      final response = await SupabaseService.client
          .from('complaints')
          .select('id, title, body, status, admin_response, patient:patient_id(full_name), doctor:doctor_id(full_name)')
          .order('created_at', ascending: false)
          .limit(200);

      complaints.assignAll(response.map((dynamic row) {
        final map = row as Map<String, dynamic>;
        final patient = map['patient'] as Map<String, dynamic>?;
        final doctor = map['doctor'] as Map<String, dynamic>?;
        return AdminComplaintItem(
          id: map['id']?.toString() ?? '',
          title: map['title']?.toString() ?? '-',
          body: map['body']?.toString() ?? '-',
          status: map['status']?.toString() ?? 'open',
          patientName: patient?['full_name']?.toString() ?? 'Patient',
          doctorName: doctor?['full_name']?.toString(),
          adminResponse: map['admin_response']?.toString(),
        );
      }).toList());
    } catch (e) {
      complaintsError.value = _friendlyError(e, 'Failed to load complaints.');
    } finally {
      isLoadingComplaints.value = false;
    }
  }

  Future<void> updateComplaintStatus(String complaintId, String status) async {
    try {
      await SupabaseService.client
          .from('complaints')
          .update({'status': status}).eq('id', complaintId);
      await loadComplaints();
      Get.snackbar('Updated', 'Complaint status updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update complaint status.');
    }
  }

  Future<void> respondToComplaint(String complaintId, String responseText) async {
    if (responseText.trim().isEmpty) return;
    try {
      await SupabaseService.client.from('complaints').update({
        'admin_response': responseText.trim(),
        'status': 'in_review',
      }).eq('id', complaintId);
      await loadComplaints();
      Get.snackbar('Saved', 'Admin response saved.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to save response.');
    }
  }

  List<AdminPostItem> searchPosts(String query) {
    if (query.isEmpty) return posts;
    final q = query.toLowerCase();
    return posts.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.body.toLowerCase().contains(q) ||
        (p.doctorName?.toLowerCase().contains(q) ?? false)).toList();
  }

  Future<void> loadPosts() async {
    postsError.value = '';
    if (!SupabaseService.isConfigured) {
      postsError.value = 'Supabase is not configured.';
      return;
    }
    try {
      isLoadingPosts.value = true;
      final response = await DoctorPostsService.fetchDoctorPosts(limit: 100);
      final rawItems = response.map((dynamic row) {
        final map = row as Map<String, dynamic>;
        final doctor = map['doctor'] as Map<String, dynamic>?;
        return (
          id: map['id']?.toString() ?? '',
          doctorId: map['doctor_id']?.toString() ?? '',
          title: map['title']?.toString() ?? '',
          body: map['body']?.toString() ?? '',
          createdAt: map['created_at']?.toString() ?? '',
          doctorName: doctor?['full_name']?.toString(),
          avatarPath: doctor?['avatar_url']?.toString() ?? '',
        );
      }).toList();

      final signedUrls = await Future.wait(
        rawItems.map((item) => _createSignedAvatarUrl(item.avatarPath)),
      );

      posts.assignAll(List<AdminPostItem>.generate(rawItems.length, (int i) {
        final item = rawItems[i];
        return AdminPostItem(
          id: item.id,
          doctorId: item.doctorId,
          title: item.title,
          body: item.body,
          createdAt: item.createdAt,
          doctorName: item.doctorName,
          doctorAvatarUrl: signedUrls[i],
        );
      }));
    } catch (e) {
      postsError.value = _friendlyError(e, 'Failed to load posts.');
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await DoctorPostsService.deletePost(postId);
      await loadPosts();
      Get.snackbar('Deleted', 'Post removed.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete post.');
    }
  }

  Future<void> loadReviews() async {
    reviewsError.value = '';
    if (!SupabaseService.isConfigured) {
      reviewsError.value = 'Supabase is not configured.';
      return;
    }
    try {
      isLoadingReviews.value = true;
      final response = await SupabaseService.client
          .from('doctor_reviews')
          .select('''
            id,
            doctor_id,
            patient_id,
            rating,
            review_text,
            created_at,
            doctor:doctor_id(full_name, avatar_url),
            patient:patient_id(full_name, avatar_url)
          ''')
          .order('created_at', ascending: false)
          .limit(200);

      final rawItems = (response as List<dynamic>).map((dynamic row) {
        final map = row as Map<String, dynamic>;
        final doctor = map['doctor'] as Map<String, dynamic>?;
        final patient = map['patient'] as Map<String, dynamic>?;
        return (
          id: map['id']?.toString() ?? '',
          doctorId: map['doctor_id']?.toString() ?? '',
          patientId: map['patient_id']?.toString() ?? '',
          rating: (map['rating'] as num?)?.toInt() ?? 5,
          reviewText: map['review_text']?.toString(),
          createdAt: map['created_at']?.toString() ?? '',
          doctorName: doctor?['full_name']?.toString(),
          patientName: patient?['full_name']?.toString(),
          doctorAvatarPath: doctor?['avatar_url']?.toString() ?? '',
          patientAvatarPath: patient?['avatar_url']?.toString() ?? '',
        );
      }).toList();

      final doctorUrls = await Future.wait(
        rawItems.map((item) => _createSignedAvatarUrl(item.doctorAvatarPath)),
      );
      final patientUrls = await Future.wait(
        rawItems.map((item) => _createSignedAvatarUrl(item.patientAvatarPath)),
      );

      reviews.assignAll(List<AdminReviewItem>.generate(rawItems.length, (int i) {
        final item = rawItems[i];
        return AdminReviewItem(
          id: item.id,
          doctorId: item.doctorId,
          patientId: item.patientId,
          rating: item.rating,
          reviewText: item.reviewText,
          createdAt: item.createdAt,
          doctorName: item.doctorName,
          patientName: item.patientName,
          doctorAvatarUrl: doctorUrls[i],
          patientAvatarUrl: patientUrls[i],
        );
      }));
    } catch (e) {
      reviewsError.value = _friendlyError(e, 'Failed to load reviews.');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await DoctorReviewsService.deleteReview(reviewId);
      await loadReviews();
      Get.snackbar('Deleted', 'Review removed.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete review.');
    }
  }
}
