import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import 'profile_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: Obx(() {
        final p = controller.profile.value;
        if (p == null) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // عرض الصورة الشخصية مع زر التعديل
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: p.avatarUrl != null 
                        ? NetworkImage(p.avatarUrl!) 
                        : null,
                      child: p.avatarUrl == null ? const Icon(Icons.person, size: 65) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: controller.uploadAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // الحقول الأساسية
              TextFormField(
                initialValue: p.fullName,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (val) => controller.profile.update((profile) {
                  if (profile != null) profile = ProfileModel.fromJson({...profile.toJson(), 'full_name': val});
                }),
              ),
              const SizedBox(height: 15),
              
              // حقول خاصة بالطبيب فقط
              if (controller.isDoctor) ...[
                TextFormField(
                  initialValue: p.specialty,
                  decoration: const InputDecoration(labelText: 'التخصص الطبي', border: OutlineInputBorder()),
                  onChanged: (val) => controller.profile.value = ProfileModel.fromJson({...p.toJson(), 'specialty': val}),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: p.bio,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'نبذة مهنية', border: OutlineInputBorder()),
                  onChanged: (val) => controller.profile.value = ProfileModel.fromJson({...p.toJson(), 'bio': val}),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: p.consultationFee?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الكشفية (\$)', border: OutlineInputBorder()),
                  onChanged: (val) => controller.profile.value = ProfileModel.fromJson({...p.toJson(), 'consultation_fee': double.tryParse(val)}),
                ),
                const SizedBox(height: 15),
              ],

              TextFormField(
                initialValue: p.phoneNumber,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                onChanged: (val) => controller.profile.value = ProfileModel.fromJson({...p.toJson(), 'phone_number': val}),
              ),
              
              const SizedBox(height: 40),
              
              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value 
                    ? null 
                    : () => controller.updateProfile(controller.profile.value!),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value 
                    ? const CircularProgressIndicator() 
                    : const Text('حفظ التغييرات', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}