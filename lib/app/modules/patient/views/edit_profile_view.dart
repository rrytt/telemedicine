import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../profile/controllers/profile_controller.dart';
import '../patient_theme.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController ctrl = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: PatientStyles.surface,
      appBar: AppBar(
        title: const Text('Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: PatientStyles.teal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: PatientStyles.teal));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => ctrl.uploadAvatar(),
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PatientStyles.border,
                      ),
                      child: ClipOval(
                        child: ctrl.avatarUrl.value.isNotEmpty
                            ? Image.network(ctrl.avatarUrl.value, fit: BoxFit.cover)
                            : Icon(Icons.person, size: 60, color: PatientStyles.textSecondary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PatientStyles.teal,
                          shape: BoxShape.circle,
                        ),
                        child: ctrl.isUploading.value
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Full Name
              TextField(
                controller: ctrl.fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Phone
              TextField(
                controller: ctrl.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Blood Type
              TextField(
                controller: ctrl.bloodTypeController,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Medical Record
              TextField(
                controller: ctrl.medicalRecordController,
                decoration: InputDecoration(
                  labelText: 'Medical Record',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Bio
              TextField(
                controller: ctrl.bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: ctrl.isSaving.value ? null : () => ctrl.saveProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatientStyles.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: PatientStyles.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: ctrl.isSaving.value
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
