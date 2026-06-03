enum AppointmentStatus { pending, accepted, rejected, completed }

class AppointmentModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final DateTime scheduledAt; // توحيد المسمى مع قاعدة البيانات والـ Dashboard
  final AppointmentStatus status;
  final String? notes;
  final String? doctorName;
  final String? patientName;

  AppointmentModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.scheduledAt,
    this.status = AppointmentStatus.pending,
    this.notes,
    this.doctorName,
    this.patientName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? json['appointment_date'] as String),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => AppointmentStatus.pending,
      ),
      notes: json['notes'] as String?,
      doctorName: json['doctor_profiles']?['full_name'] as String?,
      patientName: json['patient_profiles']?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }
}