import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminReviewsView extends StatelessWidget {
  const AdminReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(child: Obx(() => _buildList(controller))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          Text(
            'Doctor Reviews',
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
    );
  }

  Widget _buildList(AdminController controller) {
    if (controller.isLoadingReviews.value) {
      return Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    if (controller.reviewsError.value.isNotEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminStyles.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            controller.reviewsError.value,
            style: TextStyle(color: AdminStyles.danger, fontSize: 13),
          ),
        ),
      );
    }

    if (controller.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded, size: 56, color: AdminStyles.slateLight),
            SizedBox(height: 12),
            Text('No reviews yet', style: TextStyle(
              color: AdminStyles.slate, fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadReviews(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.reviews.length,
        itemBuilder: (BuildContext context, int index) {
          final review = controller.reviews[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: AdminStyles.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AdminStyles.warning.withValues(alpha: 0.15),
                      backgroundImage: review.patientAvatarUrl != null && review.patientAvatarUrl!.isNotEmpty
                          ? NetworkImage(review.patientAvatarUrl!)
                          : null,
                      child: review.patientAvatarUrl == null || review.patientAvatarUrl!.isEmpty
                          ? Text(
                              (review.patientName?.isNotEmpty ?? false)
                                  ? review.patientName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AdminStyles.warning, fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      review.patientName ?? 'Anonymous',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AdminStyles.textPrimary, fontSize: 13),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: AdminStyles.slateLight),
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AdminStyles.success.withValues(alpha: 0.15),
                      backgroundImage: review.doctorAvatarUrl != null && review.doctorAvatarUrl!.isNotEmpty
                          ? NetworkImage(review.doctorAvatarUrl!)
                          : null,
                      child: review.doctorAvatarUrl == null || review.doctorAvatarUrl!.isEmpty
                          ? Text(
                              (review.doctorName?.isNotEmpty ?? false)
                                  ? review.doctorName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AdminStyles.success, fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        review.doctorName ?? 'Unknown Doctor',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AdminStyles.textPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _ratingBadge(review.rating),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFEA500),
                      size: 18,
                    );
                  }),
                ),
                if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    review.reviewText!,
                    style: TextStyle(color: AdminStyles.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(Icons.schedule_rounded, size: 13, color: AdminStyles.slateLight),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 11, color: AdminStyles.slateLight),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: AdminStyles.slate, size: 20),
                      onSelected: (String value) {
                        if (value == 'delete') {
                          _showDeleteConfirm(context, controller, review);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete Review')),
                      ],
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

  Widget _ratingBadge(int rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEA500).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rating/5',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFEA500),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showDeleteConfirm(
      BuildContext context, AdminController controller, dynamic review) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Review', style: TextStyle(
          fontWeight: FontWeight.w700, color: AdminStyles.textPrimary,
        )),
        content: Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
          style: TextStyle(color: AdminStyles.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteReview(review.id);
            },
            child: Text('Delete', style: TextStyle(color: AdminStyles.danger)),
          ),
        ],
      ),
    );
  }
}
