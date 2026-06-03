import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/github_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
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
        backgroundColor: GithubTheme.bg,
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
        actions: <Widget>[
          IconButton(
            padding: const EdgeInsets.all(8),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 18),
            ),
            onPressed: () => Get.toNamed(AppRoutes.patientProfile),
            tooltip: 'Profile',
          ),
          IconButton(
            padding: const EdgeInsets.all(8),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month, size: 18),
            ),
            onPressed: () => _showBookAppointmentDialog(context, controller),
            tooltip: 'Book Appointment',
          ),
          IconButton(
            padding: const EdgeInsets.all(8),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 18),
            ),
            onPressed: () => _showSearchDoctorsDialog(context, controller),
            tooltip: 'Search Doctors',
          ),
          IconButton(
            padding: const EdgeInsets.all(8),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.report_problem_outlined, size: 18),
            ),
            onPressed: () => _showComplaintDialog(context, controller),
            tooltip: 'Submit Complaint',
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'logout') {
                authController.logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
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
          title: const Text('Search Doctors'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: controller.searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or specialty',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (String value) => controller.searchDoctors(value),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.filteredDoctors.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No doctors found.'),
                    );
                  }
                  return SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: controller.filteredDoctors.length,
                      itemBuilder: (BuildContext context, int index) {
                        final DoctorOption doctor =
                            controller.filteredDoctors[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: GithubTheme.secondary,
                            child: Text(
                              doctor.name.isNotEmpty
                                  ? doctor.name[0].toUpperCase()
                                  : 'D',
                            ),
                          ),
                          title: Text(doctor.name),
                          subtitle: Text(doctor.specialty ?? 'General'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  Get.toNamed(
                                    AppRoutes.publicProfile,
                                    arguments: <String, dynamic>{'id': doctor.id},
                                  );
                                },
                                child: const Text('View'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  Get.back();
                                  controller.sendConsultationRequest(doctor.id);
                                },
                                child: const Text('Request'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Get.back(), child: const Text('Close')),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: GithubTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    appointment.doctor.isNotEmpty
                        ? appointment.doctor[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
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
                            decoration: BoxDecoration(
                              color: GithubTheme.primary,
                              borderRadius: BorderRadius.circular(12),
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
                              borderRadius: BorderRadius.circular(10),
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
