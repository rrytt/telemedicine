import 'package:get/get.dart';

import '../../../core/supabase/doctor_posts_service.dart';
import 'patient_controller.dart';


class DoctorPostComment {
  DoctorPostComment({
    required this.id,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.userName,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String? userName;
  final String? avatarUrl;
}

class DoctorPost {
  DoctorPost({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.doctorName,
    this.doctorAvatarUrl,
    this.likesCount = 0,
    this.userLiked = false,
    this.comments = const <DoctorPostComment>[],
  });

  final String id;
  final String doctorId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? doctorName;
  final String? doctorAvatarUrl;

  int likesCount;
  bool userLiked;
  List<DoctorPostComment> comments;
}

class DoctorPostsController extends GetxController {
  final RxList<DoctorPost> posts = <DoctorPost>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Patient controller already provides avatar signed url logic.
  final PatientController _patientController = Get.find<PatientController>();

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    error.value = '';
    isLoading.value = true;

    try {
      final rows = await DoctorPostsService.fetchDoctorPosts(limit: 30);

      final List<DoctorPost> list = await Future.wait(
        rows.map((row) async {
          final String id = row['id']?.toString() ?? '';
          final String doctorId = row['doctor_id']?.toString() ?? '';
          final String title = row['title']?.toString() ?? '';
          final String body = row['body']?.toString() ?? '';
          final DateTime createdAt =
              DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now();

          final Map<String, dynamic>? doctor =
              row['doctor'] as Map<String, dynamic>?;

          final String? avatarPath = doctor?['avatar_url']?.toString();
          final String? avatarUrl =
              avatarPath != null && avatarPath.isNotEmpty
                  ? await _patientController.createSignedAvatarUrl(avatarPath)
                  : null;

          final int likesCount =
              await DoctorPostsService.fetchPostLikesCount(id);
          final bool userLiked = await DoctorPostsService.checkIfUserLiked(id);

          return DoctorPost(
            id: id,
            doctorId: doctorId,
            title: title,
            body: body,
            createdAt: createdAt,
            doctorName: doctor?['full_name']?.toString(),
            doctorAvatarUrl: avatarUrl,
            likesCount: likesCount,
            userLiked: userLiked,
          );
        }).toList(),
      );

      posts.assignAll(list);
    } catch (e) {
      error.value = 'Failed to load doctor posts.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(DoctorPost post) async {
    try {
      final bool currentlyLiked = post.userLiked;
      final bool next = await DoctorPostsService.toggleLike(
        post.id,
        currentlyLiked: currentlyLiked,
      );

      if (next == currentlyLiked) return;

      post.userLiked = next;
      post.likesCount = (post.likesCount + (next ? 1 : -1))
          .clamp(0, 1 << 31);
      posts.refresh();
    } catch (_) {
      Get.snackbar('Error', 'Failed to update like.');
    }
  }

  Future<void> fetchCommentsFor(DoctorPost post) async {
    try {
      final rows = await DoctorPostsService.fetchPostComments(
        postId: post.id,
        limit: 50,
      );

      final comments = await Future.wait(
        rows.map((row) async {
          final String id = row['id']?.toString() ?? '';
          final String userId = row['user_id']?.toString() ?? '';
          final String body = row['body']?.toString() ?? '';
          final DateTime createdAt =
              DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now();

          final Map<String, dynamic>? user = row['user'] as Map<String, dynamic>?;

          final String? avatarPath = user?['avatar_url']?.toString();
          final String? avatarUrl =
              avatarPath != null && avatarPath.isNotEmpty
                  ? await _patientController.createSignedAvatarUrl(avatarPath)
                  : null;

          return DoctorPostComment(
            id: id,
            userId: userId,
            body: body,
            createdAt: createdAt,
            userName: user?['full_name']?.toString(),
            avatarUrl: avatarUrl,
          );
        }).toList(),
      );

      post.comments = comments;
      posts.refresh();
    } catch (_) {
      Get.snackbar('Error', 'Failed to load comments.');
    }
  }
}

