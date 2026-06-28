import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../doctor/doctor_theme.dart';
import '../controllers/profile_controller.dart';

class DoctorProfileView extends StatelessWidget {
  const DoctorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(
      ProfileController(),
      tag: 'doctorProfile',
    );

    return Scaffold(
      body: Container(
        decoration: DoctorStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: DoctorStyles.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    Text(
                      'Doctor Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DoctorStyles.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (profileController.isLoading.value) {
                    return Center(child: CircularProgressIndicator(color: DoctorStyles.navy));
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: DoctorStyles.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: DoctorStyles.navy.withValues(alpha: 0.1),
                                    foregroundImage:
                                        profileController.avatarUrl.value.isNotEmpty
                                        ? NetworkImage(profileController.avatarUrl.value) as ImageProvider<Object>?
                                        : null,
                                    child: profileController.avatarUrl.value.isEmpty
                                        ? Icon(Icons.person, size: 52, color: DoctorStyles.navy.withValues(alpha: 0.5))
                                        : null,
                                  ),
                                  Obx(
                                    () => IconButton(
                                      icon: Icon(Icons.camera_alt, color: DoctorStyles.navy),
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
                                    : profileController.email.value,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: DoctorStyles.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profileController.email.value,
                                style: TextStyle(fontSize: 14, color: DoctorStyles.slate),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Doctor profile image and contact details are shown here for easy updates.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: DoctorStyles.slate),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: DoctorStyles.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextField(
                                controller: profileController.fullNameController,
                                decoration: DoctorStyles.inputDecoration(
                                  label: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline, color: DoctorStyles.slateLight),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: profileController.specialtyController,
                                decoration: DoctorStyles.inputDecoration(
                                  label: 'Specialty',
                                  prefixIcon: Icon(Icons.medical_services_outlined, color: DoctorStyles.slateLight),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: profileController.phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: DoctorStyles.inputDecoration(
                                  label: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined, color: DoctorStyles.slateLight),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: profileController.bioController,
                                maxLines: 3,
                                decoration: DoctorStyles.inputDecoration(
                                  label: 'Doctor Bio',
                                  hint: 'Enter your professional summary',
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 60),
                                    child: Icon(Icons.article_outlined, color: DoctorStyles.slateLight),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: profileController.isSaving.value
                                      ? null
                                      : profileController.saveProfile,
                                  style: DoctorStyles.primaryButton,
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
                              ),
                              if (profileController.statusMessage.value.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    profileController.statusMessage.value,
                                    style: TextStyle(color: DoctorStyles.success),
                                  ),
                                ),
                              if (profileController.errorMessage.value.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    profileController.errorMessage.value,
                                    style: TextStyle(color: DoctorStyles.danger),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.settings),
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('View account settings'),
                            style: DoctorStyles.primaryButton.copyWith(
                              backgroundColor: WidgetStatePropertyAll(DoctorStyles.slate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
