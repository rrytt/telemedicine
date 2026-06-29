import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/supabase/doctor_reviews_service.dart';
import '../controllers/patient_controller.dart';
import '../patient_theme.dart';

class DoctorDetailsView extends StatefulWidget {
  const DoctorDetailsView({super.key});

  @override
  State<DoctorDetailsView> createState() => _DoctorDetailsViewState();
}

class _DoctorDetailsViewState extends State<DoctorDetailsView> {
  late String doctorId;
  String doctorName = '';
  String specialty = '';
  String avatarUrl = '';
  String bio = '';
  String phone = '';
  String bloodType = '';
  String medicalRecord = '';
  double rating = 0.0;
  int reviewCount = 0;

  List<DoctorReview> reviews = [];
  bool isLoading = true;
  bool isLoadingReviews = true;
  bool hasReviewed = false;
  DoctorReview? myReview;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    doctorId = args['id']?.toString() ?? '';
    currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';
    _loadProfile();
    _loadReviews();
  }

  Future<void> _loadProfile() async {
    if (doctorId.isEmpty) return;
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select('full_name, specialty, avatar_url, bio, phone_number, blood_type, medical_record')
          .eq('id', doctorId)
          .maybeSingle();
      if (res is Map<String, dynamic>) {
        final path = res['avatar_url']?.toString() ?? '';
        String signed = '';
        if (path.isNotEmpty) {
          try {
            signed = await SupabaseService.client.storage
                .from('avatars')
                .createSignedUrl(path, 3600);
          } catch (_) {}
        }
        setState(() {
          doctorName = res['full_name']?.toString() ?? 'Doctor';
          specialty = res['specialty']?.toString() ?? '';
          avatarUrl = signed;
          bio = res['bio']?.toString() ?? '';
          phone = res['phone_number']?.toString() ?? '';
          bloodType = res['blood_type']?.toString() ?? '';
          medicalRecord = res['medical_record']?.toString() ?? '';
        });
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> _loadReviews() async {
    setState(() => isLoadingReviews = true);
    try {
      final results = await DoctorReviewsService.fetchDoctorReviews(doctorId);
      final avg = await DoctorReviewsService.fetchAverageRating(doctorId);
      final reviewed = await DoctorReviewsService.hasPatientReviewed(doctorId);
      DoctorReview? mine;
      if (reviewed) mine = await DoctorReviewsService.fetchMyReview(doctorId);

      setState(() {
        reviews = results;
        rating = (avg['average'] as num?)?.toDouble() ?? 0.0;
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
    return Scaffold(
      backgroundColor: PatientStyles.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: PatientStyles.surface, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: Text(doctorName, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PatientStyles.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Container(height: 3, color: PatientStyles.navy),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: PatientStyles.teal))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Doctor info card
                          _buildDoctorCard(),
                          const SizedBox(height: 20),
                          // Rating & Reviews
                          _buildRatingCard(),
                          // Bio
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildInfoSection('About', bio),
                          ],
                          // Contact & medical info
                          if (phone.isNotEmpty || bloodType.isNotEmpty || medicalRecord.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildContactSection(),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final ctrl = Get.find<PatientController>();
                ctrl.selectedDoctorId.value = doctorId;
                _pickBookingDateTime(context, doctorId, ctrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientStyles.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: const Text(
                'Consult Now (expect a response within 6 hours)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PatientStyles.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: avatarUrl.isNotEmpty
                ? Image.network(avatarUrl, width: 100, height: 100, fit: BoxFit.cover)
                : Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: PatientStyles.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                        style: TextStyle(fontSize: 36, color: PatientStyles.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(doctorName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PatientStyles.textPrimary),
          ),
          if (specialty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: PatientStyles.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(specialty,
                style: TextStyle(fontSize: 14, color: PatientStyles.teal, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientStyles.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: PatientStyles.textPrimary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: PatientStyles.ratingStar,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoadingReviews ? 'Loading...' : '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary),
                  ),
                ],
              ),
              if (isLoadingReviews)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Spacer(),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: PatientStyles.teal)),
                ]),
            ],
          ),
          if (currentUserId.isNotEmpty && currentUserId != doctorId) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(),
                icon: Icon(hasReviewed ? Icons.edit_rounded : Icons.star_border_rounded, size: 18),
                label: Text(hasReviewed ? 'Edit Your Rating' : 'Rate This Doctor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PatientStyles.teal,
                  side: BorderSide(color: PatientStyles.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          if (!isLoadingReviews && reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: PatientStyles.border),
            ...reviews.take(5).map((review) => Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: PatientStyles.teal.withValues(alpha: 0.1),
                    child: Text(
                      (review.patientName?.isNotEmpty ?? false) ? review.patientName![0].toUpperCase() : 'A',
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
                            Text(review.patientName ?? 'Anonymous',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PatientStyles.textPrimary),
                            ),
                            const Spacer(),
                            Row(children: List.generate(5, (i) {
                              return Icon(i < review.rating ? Icons.star : Icons.star_border, color: PatientStyles.ratingStar, size: 12);
                            })),
                          ],
                        ),
                        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(review.reviewText!, style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary, height: 1.3)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (!isLoadingReviews && reviews.isEmpty) ...[
            const SizedBox(height: 16),
            Center(child: Text('No reviews yet.', style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary))),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: PatientStyles.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(content, style: TextStyle(fontSize: 14, color: PatientStyles.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: PatientStyles.textPrimary),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow(Icons.phone, 'Phone', phone),
          ],
          if (bloodType.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow(Icons.bloodtype, 'Blood Type', bloodType),
          ],
          if (medicalRecord.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow(Icons.description, 'Medical Record', medicalRecord),
          ],
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

  void _showRatingDialog() {
    int selectedRating = myReview?.rating ?? 5;
    final TextEditingController reviewCtrl = TextEditingController(text: myReview?.reviewText ?? '');

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PatientStyles.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: PatientStyles.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(myReview != null ? 'Edit Your Rating' : 'Rate This Doctor',
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
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await DoctorReviewsService.submitReview(
                          doctorId: doctorId,
                          rating: selectedRating,
                          reviewText: reviewCtrl.text,
                        );
                        Get.back();
                        await _loadReviews();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PatientStyles.teal,
                        foregroundColor: Colors.white,
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

  Future<void> _pickBookingDateTime(BuildContext context, String doctorId, PatientController ctrl) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !context.mounted) return;
    ctrl.selectedDateTime.value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ctrl.bookAppointment();
  }
}
