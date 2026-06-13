import '../../core/supabase/supabase_service.dart';

class DoctorReview {
  DoctorReview({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    this.patientName,
  });

  final String id;
  final String doctorId;
  final String patientId;
  final int rating;
  final String? reviewText;
  final String createdAt;
  final String? patientName;
}

class DoctorReviewsService {
  DoctorReviewsService._();

  static Future<List<DoctorReview>> fetchDoctorReviews(String doctorId) async {
    final response = await SupabaseService.client
        .from('doctor_reviews')
        .select('''
          id,
          doctor_id,
          patient_id,
          rating,
          review_text,
          created_at,
          patient:patient_id(full_name)
        ''')
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((dynamic row) {
      final map = row as Map<String, dynamic>;
      final patient = map['patient'] as Map<String, dynamic>?;
      return DoctorReview(
        id: map['id']?.toString() ?? '',
        doctorId: map['doctor_id']?.toString() ?? '',
        patientId: map['patient_id']?.toString() ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 5,
        reviewText: map['review_text']?.toString(),
        createdAt: map['created_at']?.toString() ?? '',
        patientName: patient?['full_name']?.toString(),
      );
    }).toList();
  }

  static Future<Map<String, dynamic>> fetchAverageRating(String doctorId) async {
    final response = await SupabaseService.client
        .from('doctor_reviews')
        .select('rating')
        .eq('doctor_id', doctorId);

    final reviews = response as List<dynamic>;
    if (reviews.isEmpty) {
      return <String, dynamic>{'average': 0.0, 'count': 0};
    }

    double total = 0;
    for (final r in reviews) {
      total += ((r as Map<String, dynamic>)['rating'] as num).toDouble();
    }
    final average = total / reviews.length;

    return <String, dynamic>{
      'average': double.parse(average.toStringAsFixed(1)),
      'count': reviews.length,
    };
  }

  static Future<bool> hasPatientReviewed(String doctorId) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;

    final response = await SupabaseService.client
        .from('doctor_reviews')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('patient_id', user.id)
        .maybeSingle();

    return response != null;
  }

  static Future<DoctorReview?> fetchMyReview(String doctorId) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;

    final response = await SupabaseService.client
        .from('doctor_reviews')
        .select('''
          id,
          doctor_id,
          patient_id,
          rating,
          review_text,
          created_at,
          patient:patient_id(full_name)
        ''')
        .eq('doctor_id', doctorId)
        .eq('patient_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    final map = response;
    final patient = map['patient'] as Map<String, dynamic>?;
    return DoctorReview(
      id: map['id']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      reviewText: map['review_text']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
      patientName: patient?['full_name']?.toString(),
    );
  }

  static Future<void> submitReview({
    required String doctorId,
    required int rating,
    String? reviewText,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    await SupabaseService.client.from('doctor_reviews').upsert({
      'doctor_id': doctorId,
      'patient_id': user.id,
      'rating': rating,
      'review_text': reviewText?.trim().isEmpty == true ? null : reviewText?.trim(),
    }, onConflict: 'doctor_id,patient_id');
  }

  static Future<void> deleteReview(String reviewId) async {
    await SupabaseService.client
        .from('doctor_reviews')
        .delete()
        .eq('id', reviewId);
  }
}
