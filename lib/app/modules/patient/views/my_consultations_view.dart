import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../patient_theme.dart';
import '../controllers/patient_controller.dart';

class MyConsultationsView extends StatefulWidget {
  const MyConsultationsView({super.key});

  @override
  State<MyConsultationsView> createState() => _MyConsultationsViewState();
}

class _MyConsultationsViewState extends State<MyConsultationsView> {
  final PatientController controller = Get.find<PatientController>();
  int _currentIndex = 2;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    controller.loadAppointments();
  }

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
      case 3:
        Get.toNamed(AppRoutes.notifications);
        break;
      case 4:
        Get.toNamed(AppRoutes.patientProfile);
        break;
    }
  }

  List<PatientAppointment> get _filteredAppointments {
    final appointments = controller.appointments;
    if (_showActive) {
      return appointments.where((a) => a.chatEnabled).toList();
    }
    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientStyles.surface,
      appBar: AppBar(
        title: Text(
          'My Consultations',
          style: TextStyle(
            color: PatientStyles.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      backgroundColor: PatientStyles.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Toggle Active / All
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PatientStyles.teal,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showActive = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _showActive
                                ? PatientStyles.teal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: _showActive
                                    ? Colors.white
                                    : PatientStyles.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showActive = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_showActive
                                ? PatientStyles.teal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'All',
                              style: TextStyle(
                                color: !_showActive
                                    ? Colors.white
                                    : PatientStyles.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Appointments list
              Expanded(
                child: Obx(() {
                  final appointments = _filteredAppointments;
                  if (appointments.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      return _buildAppointmentCard(appt);
                    },
                  );
                }),
              ),
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
            icon: Icon(Icons.chat_bubble),
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

  Widget _buildAppointmentCard(PatientAppointment appt) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: PatientStyles.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: appt.chatEnabled
            ? () {
                controller.selectChatAppointment(appt.id);
                Get.toNamed(AppRoutes.chat);
              }
            : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: PatientStyles.teal.withValues(alpha: 0.1),
                backgroundImage: appt.doctorAvatarUrl != null
                    ? NetworkImage(appt.doctorAvatarUrl!)
                    : null,
                child: appt.doctorAvatarUrl == null
                    ? Icon(Icons.person, color: PatientStyles.teal)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.doctor,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PatientStyles.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: PatientStyles.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appt.time,
                          style: TextStyle(
                            fontSize: 13,
                            color: PatientStyles.textSecondary,
                          ),
                        ),
                        if (appt.urgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PatientStyles.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Urgent',
                              style: TextStyle(
                                fontSize: 10,
                                color: PatientStyles.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (appt.chatEnabled)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PatientStyles.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: PatientStyles.teal,
                    size: 20,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PatientStyles.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appt.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: PatientStyles.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PatientStyles.teal.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            color: PatientStyles.teal,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _showActive
              ? 'No active consultations'
              : 'You have no consultations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PatientStyles.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connect with a specialist doctor right away or\nbook at a time that suits you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: PatientStyles.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.doctorSearch),
            style: ElevatedButton.styleFrom(
              backgroundColor: PatientStyles.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PatientStyles.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Instant Consultation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Divider(color: PatientStyles.border),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(
                  color: PatientStyles.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: PatientStyles.border),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Get.toNamed(AppRoutes.doctorSearch),
            style: OutlinedButton.styleFrom(
              foregroundColor: PatientStyles.teal,
              side: BorderSide(
                color: PatientStyles.teal,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: const Text(
              'Book an appointment in advance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
