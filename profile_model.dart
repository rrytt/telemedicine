enum UserRole { patient, doctor, admin }

class ProfileModel {
  final String id;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? phoneNumber;
  // حقول خاصة بالطبيب
  final String? specialty;
  final String? bio;
  final double? consultationFee;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.specialty,
    this.bio,
    this.consultationFee,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      fullName: json['full_name'] ?? 'No Name',
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'patient'),
        orElse: () => UserRole.patient,
      ),
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      specialty: json['specialty'],
      bio: json['bio'],
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'role': role.name,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      if (role == UserRole.doctor) 'specialty': specialty,
      if (role == UserRole.doctor) 'bio': bio,
      if (role == UserRole.doctor) 'consultation_fee': consultationFee,
    };
  }
}