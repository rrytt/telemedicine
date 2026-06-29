import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/supabase/doctor_reviews_service.dart';
import '../../patient/controllers/patient_controller.dart';
import '../../patient/patient_theme.dart';

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PatientStyles.teal, PatientStyles.surface],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: PatientStyles.teal))
                    : error.isNotEmpty
                        ? _buildError()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              children: [
                                _buildHeaderCard(),
                                const SizedBox(height: 20),
                                if (isDoctor) _buildBookButton(),
                                if (isDoctor) const SizedBox(height: 20),
                                if ((profile?['bio'] ?? '').toString().isNotEmpty)
                                  _buildSectionCard(
                                    'About',
                                    Text(
                                      profile!['bio'].toString(),
                                      style: TextStyle(fontSize: 14, color: PatientStyles.textPrimary, height: 1.5),
                                    ),
                                  ),
                                if ((profile?['phone_number'] ?? '').toString().isNotEmpty ||
                                    (profile?['blood_type'] ?? '').toString().isNotEmpty ||
                                    (profile?['medical_record'] ?? '').toString().isNotEmpty)
                                  _buildInfoSection(),
                                if (isDoctor) ...[
                                  const SizedBox(height: 20),
                                  _buildRatingCard(),
                                ],
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
        decoration: BoxDecoration(
          color: PatientStyles.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PatientStyles.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          error,
          style: TextStyle(color: PatientStyles.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: PatientStyles.border.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PatientStyles.textPrimary),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    if (profile == null) return const SizedBox.shrink();
    final name = profile?['full_name']?.toString() ?? 'Unknown';
    final specialty = profile?['specialty']?.toString();
    final role = profile?['role']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: PatientStyles.border.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: PatientStyles.teal.withValues(alpha: 0.15),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 32, color: PatientStyles.teal, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: PatientStyles.textPrimary),
          ),
          if (specialty != null && specialty.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: PatientStyles.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                specialty,
                style: TextStyle(fontSize: 14, color: PatientStyles.teal, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          if (role.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              role[0].toUpperCase() + role.substring(1),
              style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary),
            ),
          ],
          if (averageRating > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < averageRating.round() ? Icons.star : Icons.star_border,
                    color: PatientStyles.ratingStar,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '$averageRating ($reviewCount)',
                      style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final doctorId = profile?['id']?.toString() ?? '';
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _pickDateTime(doctorId),
        icon: const Icon(Icons.calendar_today, color: Colors.white),
        label: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: PatientStyles.teal,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _pickDateTime(String doctorId) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final ctrl = Get.find<PatientController>();
    ctrl.selectedDoctorId.value = doctorId;
    ctrl.selectedDateTime.value = dt;
    await ctrl.bookAppointment();
  }

  Widget _buildInfoSection() {
    final phone = profile?['phone_number']?.toString() ?? '';
    final bloodType = profile?['blood_type']?.toString() ?? '';
    final medicalRecord = profile?['medical_record']?.toString() ?? '';

    return _buildSectionCard(
      'Information',
      Column(
        children: [
          if (phone.isNotEmpty)
            _infoRow(Icons.phone, 'Phone', phone),
          if (phone.isNotEmpty && (bloodType.isNotEmpty || medicalRecord.isNotEmpty))
            const Divider(height: 24),
          if (bloodType.isNotEmpty)
            _infoRow(Icons.bloodtype, 'Blood Type', bloodType),
          if (bloodType.isNotEmpty && medicalRecord.isNotEmpty)
            const Divider(height: 24),
          if (medicalRecord.isNotEmpty)
            _infoRow(Icons.description, 'Medical Record', medicalRecord),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: PatientStyles.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: PatientStyles.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: PatientStyles.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    final doctorId = profile?['id']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: PatientStyles.border.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratings & Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PatientStyles.textPrimary),
          ),
          const SizedBox(height: 16),
          if (isLoadingReviews)
            Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: PatientStyles.teal),
            ))
          else ...[
            Row(
              children: [
                Text(
                  averageRating > 0 ? '$averageRating' : '-',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: PatientStyles.textPrimary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < averageRating.round() ? Icons.star : Icons.star_border,
                          color: PatientStyles.ratingStar,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            if (currentUserId.isNotEmpty && currentUserId != doctorId) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDialog(doctorId),
                  icon: Icon(hasReviewed ? Icons.edit_rounded : Icons.star_border_rounded, size: 18),
                  label: Text(hasReviewed ? 'Edit Your Rating' : 'Rate This Doctor'),
                  style: OutlinedButton.styleFrom(
                  foregroundColor: PatientStyles.teal,
                  side: BorderSide(color: PatientStyles.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              ...reviews.take(5).map((review) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: PatientStyles.teal.withValues(alpha: 0.1),
                      child: Text(
                        (review.patientName?.isNotEmpty ?? false)
                            ? review.patientName![0].toUpperCase()
                            : 'A',
                        style: TextStyle(fontSize: 14, color: PatientStyles.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.patientName ?? 'Anonymous',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PatientStyles.textPrimary),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.rating ? Icons.star : Icons.star_border,
                                    color: PatientStyles.ratingStar,
                                    size: 12,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              review.reviewText!,
                              style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (reviews.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text('No reviews yet.', style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary)),
              ),
            ],
          ],
        ],
      ),
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
        decoration: BoxDecoration(
          color: PatientStyles.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: PatientStyles.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    myReview != null ? 'Edit Your Rating' : 'Rate This Doctor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PatientStyles.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final starNum = i + 1;
                        return IconButton(
                          icon: Icon(
                            starNum <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: PatientStyles.ratingStar,
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
                    decoration: InputDecoration(
                      labelText: 'Review (optional)',
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
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
                      style: ElevatedButton.styleFrom(
        backgroundColor: PatientStyles.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Submit Rating', style: TextStyle(fontSize: 16)),
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
}
