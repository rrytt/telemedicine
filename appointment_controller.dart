import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointment_model.dart';

class AppointmentController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var appointments = <AppointmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  // جلب كافة المواعيد المتعلقة بالمستخدم الحالي
  Future<void> fetchAppointments() async {
    try {
      isLoading(true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // جلب المواعيد مع بيانات الطبيب والمريض باستخدام الـ Foreign Key Relationships
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            doctor_profiles:profiles!doctor_id(full_name), 
            patient_profiles:profiles!patient_id(full_name)
          ''')
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .order('scheduled_at', ascending: true);
      appointments.value = (response as List)
          .map((data) => AppointmentModel.fromJson(data))
          .toList();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل المواعيد: $e');
    } finally {
      isLoading(false);
    }
  }

  // إنشاء طلب موعد جديد
  Future<bool> bookAppointment(String doctorId, DateTime date, String? notes) async {
    try {
      isLoading(true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final appointment = AppointmentModel(
        patientId: userId,
        doctorId: doctorId,
        scheduledAt: date,
        notes: notes); // تم إصلاح إغلاق القوس هنا

      await _supabase.from('appointments').insert(appointment.toJson());
      Get.snackbar('نجاح', 'تم إرسال طلب الموعد بنجاح');
      await fetchAppointments();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حجز الموعد: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  // تحديث حالة الموعد (للطبيب أو الإدمن)
  Future<void> updateStatus(String appointmentId, AppointmentStatus status) async {
    try {
      isLoading(true);
      await _supabase
          .from('appointments')
          .update({'status': status.name})
          .eq('id', appointmentId);
      await fetchAppointments();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الحالة: $e');
    } finally {
      isLoading(false);
    }
  }
}