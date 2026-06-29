import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import '../../../routes/app_pages.dart';
import '../../profile/controllers/profile_controller.dart';
import '../patient_theme.dart';

class PatientProfileView extends StatefulWidget {
  const PatientProfileView({super.key});

  @override
  State<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends State<PatientProfileView> {
  int _currentIndex = 4;

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Get.offAllNamed(AppRoutes.patient);
        break;
      case 1:
        Get.toNamed(AppRoutes.doctorSearch);
        break;
      case 2:
        Get.toNamed(AppRoutes.myConsultations);
        break;
      case 3:
        Get.toNamed(AppRoutes.notifications);
        break;
    }
  }

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
      backgroundColor: PatientStyles.surface,
      appBar: AppBar(
        title: const Text(
          'Me',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Get.toNamed(AppRoutes.editProfile),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Get.toNamed(AppRoutes.patientSettings),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
        elevation: 0,
        backgroundColor: PatientStyles.teal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // صورة الملف الشخصية
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PatientStyles.border,
                      ),
                      child: Obx(() {
                        if (profileController.avatarUrl.value.isNotEmpty) {
                          return ClipOval(
                            child: Image.network(
                              profileController.avatarUrl.value,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return Icon(
                          Icons.person,
                          size: 60,
                          color: PatientStyles.textSecondary,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      email ?? '@249962366722',
                      style: TextStyle(
                        fontSize: 16,
                        color: PatientStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // إحصائيات 2x2
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      value: acceptedAppointments.toString(),
                      label: 'Total Consultations',
                    ),
                    _StatCard(
                      value: pendingAppointments.toString(),
                      label: 'Favourites',
                    ),
                    _StatCard(
                      value: otherAppointments.toString(),
                      label: 'Instant Consultations',
                    ),
                    _StatCard(
                      value: '0',
                      label: 'Specialized Consultations',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Profile Info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Info.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PatientStyles.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoField(
                      label: 'Full name',
                      value: profileController.fullNameController.text.isNotEmpty
                          ? profileController.fullNameController.text
                          : '',
                    ),
                    const Divider(height: 1),
                    _buildInfoField(
                      label: 'Mobile number',
                      value: profileController.phoneController.text.isNotEmpty
                          ? profileController.phoneController.text
                          : '+249962366722',
                    ),
                    const Divider(height: 1),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                            label: 'Gender',
                            value: '',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                        color: PatientStyles.border,
                        ),
                        Expanded(
                          child: _buildInfoField(
                            label: 'Age',
                            value: '',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    _buildInfoField(
                      label: 'Country',
                      value: 'Sudan',
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PatientStyles.teal,
        unselectedItemColor: PatientStyles.textSecondary,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icon.png', width: 24, height: 24, fit: BoxFit.contain),
            label: 'Telemedicine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'My Consults',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: PatientStyles.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: PatientStyles.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: PatientStyles.border,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PatientStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: PatientStyles.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
