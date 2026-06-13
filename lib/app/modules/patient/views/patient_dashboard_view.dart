 import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../patient_theme.dart';

import '../controllers/patient_controller.dart';
import '../controllers/doctor_posts_controller.dart';
import '_bottom_nav_icon_button.dart';


class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.put(PatientController());
    // AuthController kept for backward compatibility with other UI parts.
    // Removed settings/edit-profile buttons from this screen.
    Get.find<AuthController>();


    return Scaffold(
      backgroundColor: PatientStyles.navy,
      appBar: AppBar(
        title: const Text('My Health Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: PatientStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: PatientStyles.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        shape: const Border(
          bottom: BorderSide(color: PatientStyles.border, width: 1),
        ),
        actions: const <Widget>[
          SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: PatientStyles.backgroundGradient),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.loadAppointments();
              },
              edgeOffset: 80,
              color: PatientStyles.blue,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _doctorPostsSliver(context),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Colors.white,
                  Color(0xFFF5FFFE),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PatientStyles.blue.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, -12),
                  spreadRadius: 4,
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  BottomNavIconButton(
                    icon: Icons.home_rounded,
                    isSelected: true,
                    onTap: () => Get.offAllNamed(AppRoutes.patient),
                  ),
                  BottomNavIconButton(
                    icon: Icons.search_rounded,
                    isSelected: false,
                    onTap: () => Get.toNamed(AppRoutes.doctorSearch),
                  ),
                  BottomNavIconButton(
                    icon: Icons.chat_rounded,
                    isSelected: false,
                    onTap: () => Get.toNamed(AppRoutes.chat),
                  ),
                  BottomNavIconButton(
                    icon: Icons.person_rounded,
                    isSelected: false,
                    onTap: () => Get.toNamed(AppRoutes.patientProfile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed edit profile dialog from this screen.
  // The dialog is now shown from PatientProfileView.

  Widget _doctorPostsSliver(BuildContext context) {
    // Local controller to avoid touching global Get.find lifecycle too much.
    final DoctorPostsController postsController = Get.put(DoctorPostsController());

    return Obx(() {
      if (postsController.isLoading.value) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: PatientStyles.cardDecoration(borderRadius: 16),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (postsController.error.value.isNotEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: PatientStyles.cardDecoration(borderRadius: 16),
            child: Text(
              postsController.error.value,
              style: const TextStyle(color: GithubTheme.danger),
            ),
          ),
        );
      }

      if (postsController.posts.isEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(60),
            decoration: PatientStyles.cardDecoration(borderRadius: 18),
            child: const Text(
              'No doctor posts yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: PatientStyles.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Doctor Posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PatientStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...postsController.posts.map((post) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: PatientStyles.cardDecoration(borderRadius: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: PatientStyles.blue.withValues(alpha: 0.16),
                    backgroundImage: post.doctorAvatarUrl != null
                        ? NetworkImage(post.doctorAvatarUrl!)
                        : null,
                    child: post.doctorAvatarUrl == null
                        ? Text(
                            (post.doctorName?.isNotEmpty ?? false)
                                ? post.doctorName![0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PatientStyles.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: PatientStyles.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          post.userLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.userLiked ? GithubTheme.danger : PatientStyles.slateLight,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Like',
                        onPressed: () => postsController.toggleLike(post),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        post.likesCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: PatientStyles.slateLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      );
    });
  }

}
