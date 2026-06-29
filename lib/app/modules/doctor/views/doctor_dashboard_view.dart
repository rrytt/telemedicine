import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../core/supabase/doctor_posts_service.dart';
import '../../../core/supabase/doctor_reviews_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../controllers/doctor_controller.dart';
import '../doctor_theme.dart';

class DoctorDashboardView extends StatefulWidget {
  const DoctorDashboardView({super.key});

  @override
  State<DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<DoctorDashboardView> {
  final DoctorController controller = Get.find<DoctorController>();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      _posts = await DoctorPostsService.fetchMyPosts();
    } catch (_) {
      _posts = [];
    }
    if (mounted) setState(() => _isLoadingPosts = false);
  }

  Future<void> _deletePost(String postId) async {
    try {
      await DoctorPostsService.deletePost(postId);
      await _loadPosts();
      if (mounted) {
        Get.snackbar('Deleted', 'Post removed successfully.');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to delete post: $e');
      }
    }
  }

  void _showEditPostDialog(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title'] as String? ?? '');
    final bodyController = TextEditingController(text: post['body'] as String? ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: DoctorStyles.inputDecoration(
                label: 'Post title',
                prefixIcon: Icon(Icons.title, color: DoctorStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              maxLines: 5,
              decoration: DoctorStyles.inputDecoration(
                label: 'Post content',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.article_outlined, color: DoctorStyles.slateLight),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () async {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) {
                Get.snackbar('Error', 'Please fill in both fields.');
                return;
              }
              try {
                await DoctorPostsService.updatePost(
                  postId: post['id'] as String,
                  title: title,
                  body: body,
                );
                Get.back();
                await _loadPosts();
                Get.snackbar('Success', 'Post updated successfully.');
              } catch (e) {
                Get.snackbar('Error', 'Failed to update post: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: DoctorStyles.inputDecoration(
                label: 'Post title',
                prefixIcon: Icon(Icons.title, color: DoctorStyles.slateLight),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              maxLines: 5,
              decoration: DoctorStyles.inputDecoration(
                label: 'Post content',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.article_outlined, color: DoctorStyles.slateLight),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: DoctorStyles.primaryButton,
            onPressed: () async {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) {
                Get.snackbar('Error', 'Please fill in both fields.');
                return;
              }
              try {
                await DoctorPostsService.createPost(title: title, body: body);
                Get.back();
                await _loadPosts();
                Get.snackbar('Success', 'Post created successfully.');
              } catch (e) {
                Get.snackbar('Error', 'Failed to create post: $e');
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.navy,
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: DoctorStyles.surface.withValues(alpha: 0.94),
        foregroundColor: DoctorStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: DoctorStyles.border, width: 1),
        ),
        actions: [
          Obx(() {
            final pendingCount =
                controller.queue.where((item) => item.isPending).length;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Appointment requests',
                  onPressed: () => Get.toNamed(AppRoutes.doctorAppointments),
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: DoctorStyles.navy,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        pendingCount > 9 ? '9+' : pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      drawer: GithubDrawer(
        menuTitle: 'Doctor Menu',
        items: <GithubDrawerItem>[
          GithubDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.event_note,
            label: 'Appointments',
            onTap: () => Get.toNamed(AppRoutes.doctorAppointments),
          ),
          GithubDrawerItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => Get.toNamed(AppRoutes.doctorProfile),
          ),
          GithubDrawerItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          GithubDrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: DoctorStyles.backgroundGradient),
          _isLoadingPosts
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: <Widget>[
                  Obx(() {
                    final total = controller.queue.length;
                    final pending =
                        controller.queue.where((item) => item.isPending).length;
                    final active =
                        controller.queue.where((item) => item.canChat).length;
                    return _buildStatsRow(total, pending, active);
                  }),
                  _RatingCard(doctorId: controller.userId),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCreatePostDialog,
                      icon: const Icon(Icons.post_add),
                      label: const Text('Create New Post'),
                      style: DoctorStyles.primaryButton.copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
                        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'My Posts',
                    style: DoctorStyles.sectionHeader,
                  ),
                  const SizedBox(height: 12),
                  if (_posts.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No posts yet. Create your first post above.',
                          style: TextStyle(color: DoctorStyles.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._posts.map((post) => _buildPostCard(post)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int pending, int active) {
    return Row(
      children: <Widget>[
        Expanded(child: _StatCard(label: 'Total', value: total.toString(), color: DoctorStyles.blue)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Pending', value: pending.toString(), color: DoctorStyles.warning)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Active', value: active.toString(), color: DoctorStyles.success)),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final String id = post['id'] as String? ?? '';
    final String title = post['title'] as String? ?? '';
    final String body = post['body'] as String? ?? '';
    final String createdAt = post['created_at'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: DoctorStyles.cardDecoration(borderRadius: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DoctorStyles.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: TextStyle(
                          fontSize: 12,
                          color: DoctorStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: DoctorStyles.slateLight),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditPostDialog(post);
                    } else if (value == 'delete') {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text('Are you sure you want to delete this post?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Get.back();
                                _deletePost(id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DoctorStyles.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                body,
                  style: TextStyle(
                    fontSize: 14,
                    color: DoctorStyles.textPrimary,
                    height: 1.4,
                  ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: DoctorStyles.cardDecoration(borderRadius: 16),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: DoctorStyles.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatefulWidget {
  const _RatingCard({required this.doctorId});

  final String doctorId;

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  double _average = 0.0;
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.doctorId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final avg = await DoctorReviewsService.fetchAverageRating(widget.doctorId);
      setState(() {
        _average = (avg['average'] as num?)?.toDouble() ?? 0.0;
        _count = (avg['count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: DoctorStyles.navy)),
      );
    }
    return Container(
      padding: EdgeInsets.all(16),
      decoration: DoctorStyles.cardDecoration(borderRadius: 16),
      child: Row(
        children: <Widget>[
          Icon(Icons.star_rounded, color: DoctorStyles.ratingStar, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _count > 0 ? '$_average' : 'No ratings yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: DoctorStyles.textPrimary,
                ),
              ),
              Text(
                _count > 0 ? '$_count review${_count == 1 ? '' : 's'}' : 'Be the first to be rated',
                style: TextStyle(fontSize: 12, color: DoctorStyles.slate),
              ),
            ],
          ),
          if (_count > 0) ...[
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Icon(
                  i < _average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  color: DoctorStyles.ratingStar,
                  size: 16,
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
