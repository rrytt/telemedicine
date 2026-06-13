import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/supabase/doctor_reviews_service.dart';
import '../../admin/admin_theme.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  Map<String, dynamic>? profile;
  String avatarUrl = '';
  bool isLoading = true;
  String error = '';

  List<DoctorReview> reviews = [];
  double averageRating = 0.0;
  int reviewCount = 0;
  bool isLoadingReviews = true;
  bool hasReviewed = false;
  DoctorReview? myReview;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final Map<String, dynamic> args =
        Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final String id = args['id']?.toString() ?? '';

    if (id.isEmpty) {
      setState(() {
        error = 'Invalid profile id.';
        isLoading = false;
      });
      return;
    }

    currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';

    try {
      final dynamic res = await SupabaseService.client
          .from('profiles')
          .select(
            'id, full_name, role, specialty, phone_number, bio, avatar_url, blood_type, medical_record',
          )
          .eq('id', id)
          .maybeSingle();

      if (res is Map<String, dynamic>) {
        profile = res;
        final String path = profile?['avatar_url']?.toString() ?? '';
        if (path.isNotEmpty) {
          try {
            final String signed = await SupabaseService.client.storage
                .from('avatars')
                .createSignedUrl(path, 3600);
            avatarUrl = signed;
          } catch (_) {
            avatarUrl = '';
          }
        }
      } else {
        error = 'Profile not found.';
      }
    } catch (e) {
      error = 'Failed to load profile: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    await _loadReviews(id);
  }

  Future<void> _loadReviews(String doctorId) async {
    setState(() => isLoadingReviews = true);
    try {
      final results = await DoctorReviewsService.fetchDoctorReviews(doctorId);
      final avg = await DoctorReviewsService.fetchAverageRating(doctorId);
      final reviewed = await DoctorReviewsService.hasPatientReviewed(doctorId);
      DoctorReview? mine;
      if (reviewed) {
        mine = await DoctorReviewsService.fetchMyReview(doctorId);
      }

      setState(() {
        reviews = results;
        averageRating = (avg['average'] as num?)?.toDouble() ?? 0.0;
        reviewCount = (avg['count'] as num?)?.toInt() ?? 0;
        hasReviewed = reviewed;
        myReview = mine;
      });
    } catch (_) {
      // silently fail reviews
    } finally {
      setState(() => isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = profile?['role']?.toString() ?? '';
    final isDoctor = role == 'doctor';

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    const Text(
                      'Profile',
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
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AdminStyles.navy))
                    : error.isNotEmpty
                        ? _buildError()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                _buildHeaderCard(),
                                const SizedBox(height: 16),
                                if (isDoctor) ..._buildRatingSection(),
                                if ((profile?['phone_number'] ?? '').toString().isNotEmpty)
                                  _buildInfoRow('Phone', profile!['phone_number'] ?? ''),
                                if ((profile?['blood_type'] ?? '').toString().isNotEmpty)
                                  _buildInfoRow('Blood Type', profile!['blood_type'] ?? ''),
                                if ((profile?['medical_record'] ?? '').toString().isNotEmpty)
                                  _buildInfoRow('Medical Record', profile!['medical_record'] ?? ''),
                                if ((profile?['bio'] ?? '').toString().isNotEmpty)
                                  _buildInfoRow('Bio', profile!['bio'] ?? ''),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: AdminStyles.cardDecoration(),
        child: Text(
          error,
          style: const TextStyle(color: AdminStyles.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    if (profile == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminStyles.cardDecoration(),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 44,
            backgroundColor: AdminStyles.navy.withValues(alpha: 0.1),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    (profile?['full_name']?.toString().isNotEmpty ?? false)
                        ? profile!['full_name'][0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 28, color: AdminStyles.navy, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile?['full_name']?.toString() ?? 'Unknown',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminStyles.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Role: ${profile?['role'] ?? '-'}',
            style: const TextStyle(color: AdminStyles.slate),
          ),
          if ((profile?['specialty'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Specialty: ${profile!['specialty']}',
              style: const TextStyle(color: AdminStyles.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRatingSection() {
    final doctorId = profile?['id']?.toString() ?? '';

    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: AdminStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.star_rounded, color: Color(0xFFFEA500), size: 22),
                const SizedBox(width: 8),
                Text('Rating', style: AdminStyles.sectionHeader),
                const Spacer(),
                if (isLoadingReviews)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AdminStyles.navy),
                  )
                else ...[
                  Text(
                    averageRating > 0 ? '$averageRating' : '-',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AdminStyles.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviewCount)',
                    style: const TextStyle(color: AdminStyles.slate, fontSize: 13),
                  ),
                ],
              ],
            ),
            if (!isLoadingReviews && reviewCount > 0) ...[
              const SizedBox(height: 10),
              _starRow(averageRating),
            ],
            if (!isLoadingReviews && currentUserId.isNotEmpty && currentUserId != doctorId) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(doctorId),
                  icon: Icon(hasReviewed ? Icons.edit_rounded : Icons.star_border_rounded, size: 18),
                  label: Text(hasReviewed ? 'Edit Your Rating' : 'Rate This Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminStyles.navy,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      if (!isLoadingReviews && reviews.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Patient Reviews', style: AdminStyles.sectionHeader),
        const SizedBox(height: 10),
        ...reviews.take(10).map((review) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AdminStyles.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      review.patientName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AdminStyles.textPrimary),
                    ),
                  ),
                  _starRowSmall(review.rating),
                ],
              ),
              if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.reviewText!, style: const TextStyle(color: AdminStyles.textSecondary, fontSize: 13)),
              ],
            ],
          ),
        )),
      ],
      if (!isLoadingReviews && reviews.isEmpty) ...[
        const SizedBox(height: 12),
        const Center(
          child: Text('No reviews yet.', style: TextStyle(color: AdminStyles.slate, fontSize: 13)),
        ),
      ],
    ];
  }

  Widget _starRow(double rating) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFEA500),
          size: 20,
        );
      }),
    );
  }

  Widget _starRowSmall(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFEA500),
          size: 16,
        );
      }),
    );
  }

  void _showRatingDialog(String doctorId) {
    int selectedRating = myReview?.rating ?? 5;
    final TextEditingController reviewCtrl = TextEditingController(
      text: myReview?.reviewText ?? '',
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return SingleChildScrollView(
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
                  Text(
                    myReview != null ? 'Edit Your Rating' : 'Rate This Doctor',
                    style: AdminStyles.sectionHeader,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final starNum = i + 1;
                        return IconButton(
                          icon: Icon(
                            starNum <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFEA500),
                            size: 40,
                          ),
                          onPressed: () => setDialogState(() => selectedRating = starNum),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewCtrl,
                    maxLines: 3,
                    decoration: AdminStyles.inputDecoration(
                      label: 'Review (optional)',
                      hint: 'Share your experience...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await DoctorReviewsService.submitReview(
                          doctorId: doctorId,
                          rating: selectedRating,
                          reviewText: reviewCtrl.text,
                        );
                        Get.back();
                        await _loadReviews(doctorId);
                      },
                      style: AdminStyles.primaryButton,
                      child: const Text('Submit Rating'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AdminStyles.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AdminStyles.textSecondary)),
        ],
      ),
    );
  }
}
