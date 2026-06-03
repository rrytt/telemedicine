import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_service.dart';

class DoctorDashboardController extends GetxController {
  final RxList<Map<String, dynamic>> pendingAppointments = <Map<String, dynamic>>[].obs; 
  final RxList<Map<String, dynamic>> acceptedAppointments = <Map<String, dynamic>>[].obs;
  final RxInt selectedIndex = 1.obs; // 0 للطلبات، 1 للمواعيد المقبولة
  final RxBool isLoading = false.obs;
  final RxBool isApproved = false.obs;

  RealtimeChannel? _channel;
  RealtimeChannel? _profileChannel;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
    _setupRealtime();
    _listenToApprovalStatus();
  }

  Future<void> fetchAppointments() async {
    try {
      isLoading.value = true;
      final String? doctorId = SupabaseService.client.auth.currentUser?.id;
      if (doctorId == null) return;

      // التحقق من حالة تفعيل حساب الطبيب من جدول profiles
      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select('is_approved')
          .eq('id', doctorId)
          .maybeSingle();

      if (profileResponse == null) {
        Get.snackbar('تنبيه', 'لم يتم العثور على ملفك الشخصي، يرجى التواصل مع الدعم.');
        return;
      }

      isApproved.value = profileResponse['is_approved'] ?? false;

      if (!isApproved.value) return; // توقف إذا كان الحساب غير مفعل

      // جلب المواعيد مع بيانات المريض المرتبطة
      final response = await SupabaseService.client
          .from('appointments')
          .select('''
            id, patient_id, doctor_id, status, scheduled_at, created_at, notes,
            patient:profiles!patient_id(full_name, avatar_url, email)
          ''')
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // استخدام toLowerCase() لتجنب أخطاء حالة الأحرف (Pending vs pending)
      pendingAppointments.assignAll(data.where((e) => e['status']?.toString().toLowerCase() == 'pending').toList());
      acceptedAppointments.assignAll(data.where((e) => e['status']?.toString().toLowerCase() == 'accepted').toList());
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch appointments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectAppointment(String appointmentId) async {
    try {
      await SupabaseService.client
          .from('appointments')
          .update({'status': 'Rejected'})
          .eq('id', appointmentId);
      fetchAppointments(); // تحديث القوائم
    } catch (e) {
      Get.snackbar('Error', 'Could not reject appointment: $e');
    }
  }

  Future<void> acceptAppointment(String appointmentId) async {
    try {
      await SupabaseService.client
          .from('appointments')
          .update({'status': 'Accepted'})
          .eq('id', appointmentId);
      fetchAppointments(); // تحديث القوائم
    } catch (e) {
      Get.snackbar('Error', 'Could not accept appointment: $e');
    }
  }

  void _setupRealtime() {
    final String? doctorId = SupabaseService.client.auth.currentUser?.id;
    if (doctorId == null) return;

    _channel = SupabaseService.client
        .channel('doctor_appointments_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (PostgresChangePayload payload) {
            fetchAppointments(); // إعادة جلب البيانات فور حدوث إضافة أو تعديل
          },
        )
        .subscribe();
  }

  void _listenToApprovalStatus() {
    final String? userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _profileChannel = SupabaseService.client
        .channel('public:profiles:id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final approved = payload.newRecord['is_approved'] as bool?;
            if (approved != null && approved != isApproved.value) {
              isApproved.value = approved;
              if (approved) {
                fetchAppointments();
                Get.snackbar('تم التفعيل', 'تم تفعيل حسابك بنجاح، يمكنك الآن استقبال المواعيد.');
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    _profileChannel?.unsubscribe();
    super.onClose();
  }
}