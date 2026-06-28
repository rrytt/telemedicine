import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/doctor_search_controller.dart';
import '../patient_theme.dart';

class DoctorSearchView extends GetView<DoctorSearchController> {
  const DoctorSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientStyles.surface,
      appBar: AppBar(
        backgroundColor: PatientStyles.teal,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: PatientStyles.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search doctors...',
                      prefixIcon: Icon(Icons.search, color: PatientStyles.textSecondary),
                      suffixIcon: ListenableBuilder(
                        listenable: controller.searchController,
                        builder: (_, __) {
                          final hasText = controller.searchController.text.isNotEmpty;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasText)
                                IconButton(
                                  onPressed: () {
                                    controller.searchController.clear();
                                    controller.searchDoctors('');
                                  },
                                  icon: Icon(Icons.close, color: PatientStyles.textSecondary),
                                ),
                            ],
                          );
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (query) => controller.searchDoctors(query),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Row(
                    children: [
                      ObxValue<Rx<SortOption>>(
                        (rx) => Icon(
                          rx.value == SortOption.ratingDesc || rx.value == SortOption.ratingAsc
                              ? Icons.star
                              : Icons.sort_by_alpha,
                          color: Colors.white,
                          size: 18,
                        ),
                        controller.sortOption,
                      ),
                      const SizedBox(width: 4),
                      ObxValue<Rx<SortOption>>(
                        (rx) {
                          String label;
                          switch (rx.value) {
                            case SortOption.nameAsc:
                              label = 'Name A-Z';
                            case SortOption.nameDesc:
                              label = 'Name Z-A';
                            case SortOption.ratingDesc:
                              label = 'Top Rated';
                            case SortOption.ratingAsc:
                              label = 'Lowest Rated';
                          }
                          return Text(label, style: const TextStyle(color: Colors.white, fontSize: 14));
                        },
                        controller.sortOption,
                      ),
                      const SizedBox(width: 4),
                      ObxValue<Rx<SortOption>>(
                        (rx) => Icon(
                          rx.value == SortOption.nameAsc || rx.value == SortOption.nameDesc
                              ? Icons.swap_vert
                              : Icons.arrow_downward,
                          color: Colors.white,
                          size: 18,
                        ),
                        controller.sortOption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 48, color: PatientStyles.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    controller.error.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: PatientStyles.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.filteredDoctors.isEmpty) {
          return Center(
            child: Text(
              'No doctors match your search.',
              style: TextStyle(fontSize: 16, color: PatientStyles.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.filteredDoctors.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '${controller.filteredDoctors.length} doctor${controller.filteredDoctors.length == 1 ? '' : 's'} found',
                  style: TextStyle(fontSize: 14, color: PatientStyles.textSecondary),
                ),
              );
            }
            return _buildDoctorCard(controller.filteredDoctors[index - 1]);
          },
        );
      }),
      bottomNavigationBar: _BottomNav(),
    );
  }

  Widget _buildDoctorCard(DoctorSearchItem doctor) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.doctorDetails, arguments: {'id': doctor.id}),
      child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PatientStyles.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PatientStyles.border),
        boxShadow: [
          BoxShadow(
            color: PatientStyles.border.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: doctor.avatarUrl != null
                ? Image.network(
                    doctor.avatarUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(doctor.name),
                  )
                : _buildAvatarPlaceholder(doctor.name),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PatientStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (doctor.specialty != null)
                  Text(
                    doctor.specialty!,
                    style: TextStyle(fontSize: 13, color: PatientStyles.textSecondary),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 14,
                          color: index < doctor.averageRating.round()
                              ? Colors.amber
                              : PatientStyles.border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.reviewCount > 0
                          ? '${doctor.reviewCount} Review${doctor.reviewCount == 1 ? '' : 's'}'
                          : 'No reviews',
                      style: TextStyle(fontSize: 12, color: PatientStyles.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values.map((option) {
            final isSelected = controller.sortOption.value == option;
            String label;
            IconData icon;
            switch (option) {
              case SortOption.nameAsc:
                label = 'Name (A-Z)';
                icon = Icons.sort_by_alpha;
              case SortOption.nameDesc:
                label = 'Name (Z-A)';
                icon = Icons.sort_by_alpha;
              case SortOption.ratingDesc:
                label = 'Highest Rated';
                icon = Icons.star;
              case SortOption.ratingAsc:
                label = 'Lowest Rated';
                icon = Icons.star;
            }
            return ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: isSelected ? Icon(Icons.check, color: PatientStyles.teal) : null,
              onTap: () {
                controller.setSortOption(option);
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0x334ECDC4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: 28,
            color: PatientStyles.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: PatientStyles.teal,
      unselectedItemColor: PatientStyles.textSecondary,
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        switch (index) {
          case 0:
            Get.offAllNamed(AppRoutes.patient);
          case 2:
            Get.toNamed(AppRoutes.myConsultations);
          case 3:
            Get.toNamed(AppRoutes.notifications);
          case 4:
            Get.toNamed(AppRoutes.patientProfile);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Telemedicine'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'My Consults'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
      ],
    );
  }
}
