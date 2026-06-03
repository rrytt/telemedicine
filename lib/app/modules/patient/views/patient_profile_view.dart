import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../theme/github_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import 'package:telemedicine/app/modules/profile/controllers/profile_controller.dart';

class PatientProfileView extends StatelessWidget {
  const PatientProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PatientController patientController = Get.find<PatientController>();
    final ProfileController profileController = Get.put(ProfileController());

    final String? email =
        SupabaseService.client.auth.currentUser?.email ??
        (authController.emailController.text.isNotEmpty
            ? authController.emailController.text
            : null);

    final int acceptedAppointments = patientController.appointments
        .where((item) => item.chatEnabled)
        .length;
    final int pendingAppointments = patientController.appointments
        .where((item) => item.status == 'Pending')
        .length;
    final int otherAppointments = patientController.appointments
        .where((item) => item.status != 'Pending' && !item.chatEnabled)
        .length;

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                color: GithubTheme.surface,
                elevation: 2,
                shadowColor: GithubTheme.textPrimary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: GithubTheme.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: <Widget>[
                          Obx(
                            () => CircleAvatar(
                              radius: 30,
                              backgroundColor: GithubTheme.primary,
                              foregroundImage:
                                  profileController.avatarUrl.value.isNotEmpty
                                  ? NetworkImage(
                                          profileController.avatarUrl.value,
                                        )
                                        as ImageProvider<Object>?
                                  : null,
                              child: profileController.avatarUrl.value.isEmpty
                                  ? Text(
                                      email?.isNotEmpty == true
                                          ? email![0].toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: profileController.isUploading.value
                                ? null
                                : profileController.uploadAvatar,
                            tooltip: 'Change profile image',
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profileController
                                      .fullNameController
                                      .text
                                      .isNotEmpty
                                  ? profileController.fullNameController.text
                                  : (email ?? 'Patient'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: profileController.fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Full name',
                                filled: true,
                                fillColor: GithubTheme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: GithubTheme.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: profileController.phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                filled: true,
                                fillColor: GithubTheme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: GithubTheme.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  profileController
                                      .bloodTypeController
                                      .text
                                      .isNotEmpty
                                  ? profileController.bloodTypeController.text
                                  : null,
                              items:
                                  <String>[
                                        'A+',
                                        'A-',
                                        'B+',
                                        'B-',
                                        'AB+',
                                        'AB-',
                                        'O+',
                                        'O-',
                                      ]
                                      .map(
                                        (String v) => DropdownMenuItem<String>(
                                          value: v,
                                          child: Text(v),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (String? v) {
                                if (v != null) {
                                  profileController.bloodTypeController.text =
                                      v;
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Blood Type',
                                filled: true,
                                fillColor: GithubTheme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: GithubTheme.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller:
                                  profileController.medicalRecordController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Medical Record',
                                filled: true,
                                fillColor: GithubTheme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: GithubTheme.border,
                                  ),
                                ),
                                hintText: 'Detailed medical history or notes',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: profileController.bioController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Medical notes',
                                filled: true,
                                fillColor: GithubTheme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: GithubTheme.border,
                                  ),
                                ),
                                hintText:
                                    'Optional: share health goals or conditions',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GithubTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: profileController.isSaving.value
                                  ? null
                                  : profileController.saveProfile,
                              child: profileController.isSaving.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Profile'),
                            ),
                            if (profileController
                                .statusMessage
                                .value
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  profileController.statusMessage.value,
                                  style: const TextStyle(
                                    color: GithubTheme.success,
                                  ),
                                ),
                              ),
                            if (profileController.errorMessage.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  profileController.errorMessage.value,
                                  style: const TextStyle(
                                    color: GithubTheme.danger,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Appointment Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _ProfileStatCard(
                label: 'Active Consultations',
                value: acceptedAppointments,
                color: GithubTheme.success,
              ),
              const SizedBox(height: 12),
              _ProfileStatCard(
                label: 'Pending requests',
                value: pendingAppointments,
                color: GithubTheme.warning,
              ),
              const SizedBox(height: 12),
              _ProfileStatCard(
                label: 'Other appointments',
                value: otherAppointments,
                color: GithubTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: GithubTheme.textPrimary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: GithubTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: GithubTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
