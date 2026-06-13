import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../patient_theme.dart';
import '../controllers/doctor_search_controller.dart';

class DoctorSearchView extends StatelessWidget {
  const DoctorSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final DoctorSearchController controller = Get.put(DoctorSearchController());

    return Scaffold(
      body: Container(
        decoration: PatientStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: PatientStyles.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    const Text(
                      'Find Doctors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PatientStyles.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextField(
                  controller: controller.searchController,
                  decoration: PatientStyles.inputDecoration(
                    label: 'Search by name or specialty',
                    prefixIcon: const Icon(Icons.search, color: PatientStyles.slateLight),
                  ),
                  onChanged: (String value) => controller.searchDoctors(value),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: PatientStyles.navy));
                  }

                  if (controller.error.value.isNotEmpty && controller.doctors.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          controller.error.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: PatientStyles.slate,
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller.filteredDoctors.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.search_off_rounded, size: 64, color: PatientStyles.slateLight.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No doctors match your search.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: PatientStyles.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: controller.filteredDoctors.length,
                    itemBuilder: (BuildContext context, int index) {
                      final doctor = controller.filteredDoctors[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: PatientStyles.cardDecoration(borderRadius: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: PatientStyles.blue.withValues(alpha: 0.16),
                                    backgroundImage: doctor.avatarUrl != null
                                        ? NetworkImage(doctor.avatarUrl!)
                                        : null,
                                    child: doctor.avatarUrl == null
                                        ? Text(
                                            doctor.name.isNotEmpty
                                                ? doctor.name[0].toUpperCase()
                                                : 'D',
                                            style: const TextStyle(
                                              color: PatientStyles.navy,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          doctor.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: PatientStyles.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          doctor.specialty ?? 'General Practitioner',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: PatientStyles.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _RatingRow(average: doctor.averageRating, count: doctor.reviewCount),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: PatientStyles.navy,
                                        side: const BorderSide(color: PatientStyles.border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => Get.toNamed(
                                        AppRoutes.publicProfile,
                                        arguments: <String, dynamic>{'id': doctor.id},
                                      ),
                                      child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: PatientStyles.navy,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: PatientStyles.navy.withValues(alpha: 0.3),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Get.find<DoctorSearchController>().sendConsultationRequest(doctor.id);
                                      },
                                      child: const Text('Request', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Row(
        children: <Widget>[
          ...List.generate(5, (int i) => Icon(Icons.star_border, size: 16, color: PatientStyles.slateLight.withValues(alpha: 0.6))),
          const SizedBox(width: 6),
          Text(
            'No ratings yet',
            style: TextStyle(fontSize: 12, color: PatientStyles.slateLight.withValues(alpha: 0.8)),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        ...List.generate(5, (int i) {
          final double filled = average - i;
          IconData icon;
          if (filled >= 1) {
            icon = Icons.star;
          } else if (filled >= 0.25) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: 16, color: const Color(0xFFF59E0B));
        }),
        const SizedBox(width: 6),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: PatientStyles.textPrimary,
          ),
        ),
        Text(
          ' ($count)',
          style: const TextStyle(fontSize: 12, color: PatientStyles.slateLight),
        ),
      ],
    );
  }
}
