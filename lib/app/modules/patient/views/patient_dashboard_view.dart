import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/patient_controller.dart';
import '../controllers/doctor_posts_controller.dart';
import '../patient_theme.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  bool _showGreeting = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _showGreeting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.put(PatientController());
    final DoctorPostsController postsController = Get.put(DoctorPostsController());

    return Scaffold(
      backgroundColor: PatientStyles.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                color: PatientStyles.teal,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/icon.png', width: 24, height: 24, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Telemedicine',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    if (_showGreeting) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Hi , How can I help you?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consult doctors, order medication, or get care at home.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.skynewsarabia.com/images/v4/2021/02/24/1417556/800/450/1-1417556.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xCCB71C1C),
                            Color(0x99C0392B),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Get Help Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video or chat with a licensed doctor - prescriptions & sick leave included.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Get.toNamed(AppRoutes.doctorSearch),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PatientStyles.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Consult Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Obx(() {
              if (postsController.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )),
                );
              }
              if (postsController.error.value.isNotEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (postsController.posts.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor Posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PatientStyles.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...postsController.posts.map((post) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PatientStyles.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PatientStyles.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: post.doctorAvatarUrl != null
                                      ? NetworkImage(post.doctorAvatarUrl!)
                                      : null,
                                  child: post.doctorAvatarUrl == null
                                      ? Text(
                                          (post.doctorName?.isNotEmpty ?? false)
                                              ? post.doctorName![0].toUpperCase()
                                              : 'D',
                                          style: TextStyle(
                                            color: PatientStyles.teal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    post.doctorName ?? 'Doctor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: PatientStyles.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  _timeAgo(post.createdAt),
                                  style: TextStyle(fontSize: 11, color: PatientStyles.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: PatientStyles.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    post.userLiked ? Icons.favorite : Icons.favorite_border,
                                    color: post.userLiked ? Colors.red : PatientStyles.textSecondary,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => postsController.toggleLike(post),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${post.likesCount}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PatientStyles.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.chat_bubble_outline, size: 18, color: PatientStyles.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.comments.length}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PatientStyles.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PatientStyles.blueAccent,
        onPressed: () => _showComplaintDialog(context, controller),
        child: const Icon(Icons.report_problem, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PatientStyles.teal,
        unselectedItemColor: PatientStyles.textSecondary,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          switch (index) {
            case 1:
              Get.toNamed(AppRoutes.doctorSearch);
            case 2:
              Get.toNamed(AppRoutes.myConsultations);
            case 3:
              Get.toNamed(AppRoutes.notifications);
            case 4:
              Get.toNamed(AppRoutes.patientProfile);
          }
        },
        items: [
          BottomNavigationBarItem(icon: Image.asset('assets/images/icon.png', width: 24, height: 24, fit: BoxFit.contain), label: 'Telemedicine'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'My Consults'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }

  void _showComplaintDialog(BuildContext context, PatientController controller) {
    controller.complaintTitleController.clear();
    controller.complaintBodyController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit a Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.complaintTitleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.complaintBodyController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.submitComplaint();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: PatientStyles.teal),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
