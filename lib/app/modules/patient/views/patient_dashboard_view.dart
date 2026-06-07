import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/widgets/github_widgets.dart';
import '../controllers/patient_controller.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.put(PatientController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('My Health Dashboard'),
        elevation: 0,
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: GithubTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      drawer: GithubDrawer(
        menuTitle: 'Patient Menu',
        items: <GithubDrawerItem>[
          GithubDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {},
          ),
          GithubDrawerItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => Get.toNamed(AppRoutes.patientProfile),
          ),
          GithubDrawerItem(
            icon: Icons.calendar_month,
            label: 'Book Appointment',
            onTap: () => _showBookAppointmentDialog(context, controller),
          ),
          GithubDrawerItem(
            icon: Icons.search,
            label: 'Search Doctors',
            onTap: () => _showSearchDoctorsDialog(context, controller),
          ),
          GithubDrawerItem(
            icon: Icons.report_problem_outlined,
            label: 'Submit Complaint',
            onTap: () => _showComplaintDialog(context, controller),
          ),
          GithubDrawerItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Get.toNamed(AppRoutes.patientSettings),
          ),
          GithubDrawerItem(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () => Get.toNamed(AppRoutes.about),
          ),
          GithubDrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.loadAppointments();
          },
          edgeOffset: 80,
          color: GithubTheme.primary,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Welcome Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: GithubTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: GithubTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Welcome back!',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Your health is our priority',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: GithubTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.search,
                              title: 'Find Doctor',
                              subtitle: 'Search specialists',
                              color: GithubTheme.primary,
                              onTap: () =>
                                  _showSearchDoctorsDialog(context, controller),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.report_problem_outlined,
                              title: 'Report Issue',
                              subtitle: 'Submit complaint',
                              color: GithubTheme.warning,
                              onTap: () =>
                                  _showComplaintDialog(context, controller),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Appointments Section
                      Row(
                        children: <Widget>[
                          const Text(
                            'My Appointments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: GithubTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => controller.loadAppointments(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: GithubTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _appointmentsSliver(context, controller),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentsSliver(
    BuildContext context,
    PatientController controller,
  ) {
    return Obx(() {
      if (controller.isLoadingAppointments.value) {
        return SliverFillRemaining(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (controller.appointmentsError.value.isNotEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: GithubTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GithubTheme.danger.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              controller.appointmentsError.value,
              style: const TextStyle(color: GithubTheme.danger),
            ),
          ),
        );
      }

      final List<PatientAppointment> pending = controller.appointments
          .where((PatientAppointment item) => item.status == 'Pending')
          .toList();
      final List<PatientAppointment> accepted = controller.appointments
          .where((PatientAppointment item) => item.chatEnabled)
          .toList();
      final List<PatientAppointment> other = controller.appointments
          .where(
            (PatientAppointment item) =>
                item.status != 'Pending' && !item.chatEnabled,
          )
          .toList();

      if (controller.appointments.isEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: GithubTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GithubTheme.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: GithubTheme.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: GithubTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medical_information_outlined,
                    size: 40,
                    color: GithubTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No appointments yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: GithubTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Book an appointment to start chatting with doctors and schedule your consultations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GithubTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      _showBookAppointmentDialog(Get.context!, controller),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Book Appointment'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (pending.isNotEmpty) ...[
              const Text(
                'Pending Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: GithubTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...pending.map((PatientAppointment item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppointmentCard(
                    appointment: item,
                    unreadCount: 0,
                    onTap: () {
                      Get.snackbar(
                        'Pending',
                        'Your request is waiting for the doctor to accept.',
                      );
                    },
                    onDelete: () =>
                        _confirmDeleteAppointment(context, controller, item.id),
                    statusText: item.status,
                    statusColor: GithubTheme.warning,
                    subtitle: 'Waiting for doctor confirmation',
                    isActionable: false,
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            if (accepted.isNotEmpty) ...[
              const Text(
                'Active Consultations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: GithubTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...accepted.map((PatientAppointment item) {
                final int unread = controller.unreadForAppointment(item.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppointmentCard(
                    appointment: item,
                    unreadCount: unread,
                    onTap: () => Get.toNamed(AppRoutes.chat, arguments: item),
                    onDelete: () =>
                        _confirmDeleteAppointment(context, controller, item.id),
                    statusText: 'Accepted',
                    statusColor: GithubTheme.success,
                    subtitle: 'Tap to continue the consultation',
                    isActionable: true,
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            if (other.isNotEmpty) ...[
              const Text(
                'Other Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: GithubTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...other.map((PatientAppointment item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppointmentCard(
                    appointment: item,
                    unreadCount: 0,
                    onTap: () {
                      Get.snackbar(
                        'Appointment queued',
                        'This appointment has been recorded for your review.',
                      );
                    },
                    onDelete: () =>
                        _confirmDeleteAppointment(context, controller, item.id),
                    statusText: item.status,
                    statusColor: GithubTheme.textMuted,
                    subtitle: 'Appointment status: ${item.status}',
                    isActionable: false,
                  ),
                );
              }),
            ],
          ],
        ),
      );
    });
  }

  void _showSearchDoctorsDialog(
    BuildContext context,
    PatientController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          title: const Row(
            children: <Widget>[
              Icon(Icons.search, color: GithubTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search Doctors',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ignore: prefer_const_constructors
                TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name or specialty',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    filled: true,
                    fillColor: GithubTheme.surface,
                  ),
                  onChanged: (String value) => controller.searchDoctors(value),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.filteredDoctors.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: GithubTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No doctors found. Try another name or specialty.',
                        style: TextStyle(color: GithubTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${controller.filteredDoctors.length} doctors found',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GithubTheme.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: ListView.separated(
                          itemCount: controller.filteredDoctors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final DoctorOption doctor =
                                controller.filteredDoctors[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 1,
                              color: GithubTheme.surface,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      GithubTheme.primary.withValues(alpha: 0.16),
                                  backgroundImage: doctor.avatarUrl != null
                                      ? NetworkImage(doctor.avatarUrl!)
                                      : null,
                                  child: doctor.avatarUrl == null
                                      ? Text(
                                          doctor.name.isNotEmpty
                                              ? doctor.name[0].toUpperCase()
                                              : 'D',
                                          style: const TextStyle(
                                            color: GithubTheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  doctor.specialty ?? 'General',
                                  style: const TextStyle(
                                    color: GithubTheme.textSecondary,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 92,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          minimumSize: const Size(72, 28),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                        ),
                                        onPressed: () {
                                          Get.back();
                                          Get.toNamed(
                                            AppRoutes.publicProfile,
                                            arguments: <String, dynamic>{
                                              'id': doctor.id,
                                            },
                                          );
                                        },
                                        child: const Text('View'),
                                      ),
                                      const SizedBox(height: 4),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(72, 28),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                        ),
                                        onPressed: () {
                                          Get.back();
                                          controller.sendConsultationRequest(doctor.id);
                                        },
                                        child: const Text('Request'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAppointmentDateTime(
    BuildContext context,
    PatientController controller,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) {
      return;
    }

    controller.selectedDateTime.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _showBookAppointmentDialog(
    BuildContext context,
    PatientController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Book Appointment'),
          content: Obx(() {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: controller.selectedDoctorId.value,
                    decoration: const InputDecoration(labelText: 'Doctor'),
                    items: controller.doctors.map((DoctorOption doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor.id,
                        child: Text(doctor.name),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      controller.selectedDoctorId.value = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _pickAppointmentDateTime(context, controller),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Choose Date & Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              controller.selectedDateTime.value == null
                                  ? 'Select appointment slot'
                                  : '${controller.selectedDateTime.value!.year}-${controller.selectedDateTime.value!.month.toString().padLeft(2, '0')}-${controller.selectedDateTime.value!.day.toString().padLeft(2, '0')} ${controller.selectedDateTime.value!.hour.toString().padLeft(2, '0')}:${controller.selectedDateTime.value!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: controller.selectedDateTime.value == null
                                    ? GithubTheme.textSecondary
                                    : GithubTheme.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.bookingError.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        controller.bookingError.value,
                        style: const TextStyle(color: GithubTheme.danger),
                      ),
                    ),
                ],
              ),
            );
          }),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            Obx(() {
              final NavigatorState navigator = Navigator.of(context);
              return FilledButton(
                onPressed: controller.isBooking.value
                    ? null
                    : () async {
                        await controller.bookAppointment();
                        if (controller.bookingError.value.isEmpty &&
                            navigator.mounted) {
                          navigator.pop();
                        }
                      },
                child: Text(controller.isBooking.value ? 'Booking...' : 'Book'),
              );
            }),
          ],
        );
      },
    );
  }

  void _showComplaintDialog(
    BuildContext context,
    PatientController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller.complaintTitleController,
                decoration: const InputDecoration(labelText: 'Complaint title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.complaintBodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Complaint details',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            Obx(() {
              return FilledButton(
                onPressed: controller.isSubmittingComplaint.value
                    ? null
                    : () {
                        controller.submitComplaint();
                        Get.back();
                      },
                child: Text(
                  controller.isSubmittingComplaint.value
                      ? 'Sending...'
                      : 'Send',
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _confirmDeleteAppointment(
    BuildContext context,
    PatientController controller,
    String appointmentId,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text(
            'Are you sure you want to delete this appointment and all associated files? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Get.back();
                await controller.deleteAppointment(appointmentId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: GithubTheme.surface,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GithubTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: GithubTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.unreadCount,
    required this.onTap,
    required this.statusText,
    required this.statusColor,
    required this.subtitle,
    required this.isActionable,
    this.onDelete,
  });

  final PatientAppointment appointment;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String statusText;
  final Color statusColor;
  final String subtitle;
  final bool isActionable;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: GithubTheme.surface,
      elevation: 2,
      shadowColor: GithubTheme.primary.withValues(alpha: 0.08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: GithubTheme.primary.withValues(alpha: 0.16),
                backgroundImage: appointment.doctorAvatarUrl != null
                    ? NetworkImage(appointment.doctorAvatarUrl!)
                    : null,
                child: appointment.doctorAvatarUrl == null
                    ? Text(
                        appointment.doctor.isNotEmpty
                            ? appointment.doctor[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            appointment.doctor,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: GithubTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: GithubTheme.primary,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: GithubTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: GithubTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            appointment.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: GithubTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: GithubTheme.danger,
                  ),
                  tooltip: 'Delete appointment',
                ),
              Icon(
                isActionable ? Icons.arrow_forward_ios : Icons.hourglass_top,
                size: 16,
                color: GithubTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
