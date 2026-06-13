import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../theme/github_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import 'package:telemedicine/app/modules/profile/controllers/profile_controller.dart';
import '../../../routes/app_pages.dart';
import '../patient_theme.dart';





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
      backgroundColor: PatientStyles.navy,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Get.toNamed(AppRoutes.patientSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: PatientStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: PatientStyles.border, width: 1),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: PatientStyles.backgroundGradient),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: PatientStyles.glassCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: <Widget>[
                            Obx(
                              () => CircleAvatar(
                                radius: 48,
                                backgroundColor: PatientStyles.blue,
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
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Obx(
                              () => IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: PatientStyles.navy),
                                onPressed: profileController.isUploading.value
                                    ? null
                                    : profileController.uploadAvatar,
                                tooltip: 'Change profile image',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileController.fullNameController.text.isNotEmpty
                              ? profileController.fullNameController.text
                              : (email ?? 'Patient'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: PatientStyles.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email ?? 'No email available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: PatientStyles.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Update your profile picture and medical details for better care coordination.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: PatientStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: PatientStyles.glassCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: profileController.fullNameController,
                          decoration: PatientStyles.inputDecoration(
                            label: 'Full name',
                            prefixIcon: const Icon(Icons.person_outline, color: PatientStyles.slateLight),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: profileController.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: PatientStyles.inputDecoration(
                            label: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined, color: PatientStyles.slateLight),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              profileController.bloodTypeController.text = v;
                            }
                          },
                          decoration: PatientStyles.inputDecoration(
                            label: 'Blood Type',
                            prefixIcon: const Icon(Icons.bloodtype_outlined, color: PatientStyles.slateLight),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: profileController.medicalRecordController,
                          maxLines: 5,
                          decoration: PatientStyles.inputDecoration(
                            label: 'Medical Record',
                            hint: 'Detailed medical history or notes',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Icon(Icons.folder_outlined, color: PatientStyles.slateLight),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: profileController.bioController,
                          maxLines: 3,
                          decoration: PatientStyles.inputDecoration(
                            label: 'Medical notes',
                            hint: 'Optional: share health goals or conditions',
                            prefixIcon: const Icon(Icons.health_and_safety_outlined, color: PatientStyles.slateLight),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: PatientStyles.primaryButton,
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
                        if (profileController.statusMessage.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              profileController.statusMessage.value,
                              style: const TextStyle(color: GithubTheme.success),
                            ),
                          ),
                        if (profileController.errorMessage.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              profileController.errorMessage.value,
                              style: const TextStyle(color: GithubTheme.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Appointment Summary',
                    style: PatientStyles.sectionHeader,
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
        ],
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
    return Container(
      decoration: PatientStyles.cardDecoration(borderRadius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: PatientStyles.textPrimary,
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
