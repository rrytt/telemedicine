import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminPostsView extends StatelessWidget {
  const AdminPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(controller),
              Expanded(child: Obx(() => _buildList(controller))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AdminController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
                onPressed: () => Get.back(),
              ),
              const Spacer(),
              const Text(
                'Manage Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AdminStyles.textPrimary,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: AdminStyles.inputDecoration(
                label: 'Search posts...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminStyles.slate),
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildList(AdminController controller) {
    if (controller.isLoadingPosts.value) {
      return const Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    if (controller.postsError.value.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminStyles.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            controller.postsError.value,
            style: const TextStyle(color: AdminStyles.danger, fontSize: 13),
          ),
        ),
      );
    }

    final results = controller.searchPosts(controller.searchQuery.value);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.article_outlined, size: 56, color: AdminStyles.slateLight),
            SizedBox(height: 12),
            Text('No posts found', style: TextStyle(
              color: AdminStyles.slate, fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          final post = results[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: AdminStyles.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AdminStyles.success.withValues(alpha: 0.15),
                      backgroundImage: post.doctorAvatarUrl != null && post.doctorAvatarUrl!.isNotEmpty
                          ? NetworkImage(post.doctorAvatarUrl!)
                          : null,
                      child: post.doctorAvatarUrl == null || post.doctorAvatarUrl!.isEmpty
                          ? Text(
                              (post.doctorName?.isNotEmpty ?? false)
                                  ? post.doctorName![0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AdminStyles.success,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AdminStyles.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.doctorName ?? 'Unknown Doctor',
                            style: const TextStyle(
                              color: AdminStyles.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AdminStyles.slate),
                      onSelected: (String value) {
                        switch (value) {
                          case 'view':
                            _showDetailDialog(context, controller, post);
                            break;
                          case 'delete':
                            _showDeleteConfirm(context, controller, post);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'view', child: Text('View Details')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.body,
                  style: const TextStyle(color: AdminStyles.textPrimary, fontSize: 13),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(Icons.schedule_rounded, size: 14, color: AdminStyles.slateLight),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: AdminStyles.slateLight),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${post.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11, color: AdminStyles.slateLight),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showDetailDialog(
      BuildContext context, AdminController controller, dynamic post) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AdminStyles.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Post Details', style: AdminStyles.sectionHeader),
              const SizedBox(height: 20),
              _detailRow('Title', post.title),
              _detailRow('Author', post.doctorName ?? 'Unknown'),
              _detailRow('Post ID', post.id),
              _detailRow('Doctor ID', post.doctorId),
              _detailRow('Created', _formatDate(post.createdAt)),
              const SizedBox(height: 16),
              const Text('Body', style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminStyles.textPrimary,
                fontSize: 14,
              )),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminStyles.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminStyles.border),
                ),
                child: Text(
                  post.body,
                  style: const TextStyle(
                    color: AdminStyles.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: AdminStyles.primaryButton.copyWith(
                    backgroundColor: WidgetStatePropertyAll(AdminStyles.navy),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(
              color: AdminStyles.slate, fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(
              color: AdminStyles.textPrimary, fontWeight: FontWeight.w500, fontSize: 13,
            )),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, AdminController controller, dynamic post) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Post', style: TextStyle(
          fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
        )),
        content: Text(
          'Are you sure you want to delete "${post.title}" by ${post.doctorName ?? 'Unknown'}? This action cannot be undone.',
          style: const TextStyle(color: AdminStyles.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deletePost(post.id);
            },
            child: const Text('Delete', style: TextStyle(color: AdminStyles.danger)),
          ),
        ],
      ),
    );
  }
}
