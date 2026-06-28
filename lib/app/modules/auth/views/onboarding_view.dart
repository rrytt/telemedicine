import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void skip() {
    _complete();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    return Scaffold(
      backgroundColor: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(controller),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: (index) => controller.currentPage.value = index,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildBottomButtons(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/icon.jpg', width: 32, height: 32, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Text('Telemedicine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Get.isDarkMode ? const Color(0xFFF1F5F9) : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= controller.currentPage.value
                    ? const Color(0xFF4ECDC4)
                    : Get.isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      )),
    );
  }

  Widget _buildBottomButtons(OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final page = _pages[controller.currentPage.value];
        final isLast = controller.currentPage.value == 3;
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLast ? controller.skip : controller.nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.isDarkMode ? const Color(0xFF0A7A8A) : const Color(0xFF2D9CDB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLast ? 'Get Started' : page['buttonText'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (!isLast && page['showNext']) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ],
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: controller.skip,
                child: Text('Get Started',
                  style: TextStyle(color: Get.isDarkMode ? const Color(0xFF0A7A8A) : const Color(0xFF2D9CDB), fontSize: 14),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: Image.asset(
              page['image'],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.medical_services_outlined,
                size: 200,
                color: Get.isDarkMode ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
          ),
          Text(
            page['title'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF2D7A8A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page['subtitle'],
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Get.isDarkMode ? const Color(0xFF94A3B8) : Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/onboarding1.png',
      'title': 'Access free Consultations',
      'subtitle': 'Expert medical & mental care, quick access that are for free all in one place',
      'buttonText': 'Next',
      'showNext': true,
    },
    {
      'image': 'assets/images/onboarding2.png',
      'title': 'Bring Home Labs Right To Your Doorstep',
      'subtitle': 'Experience the ultimate convenience with our Home Labs delivered right to your doorstep',
      'buttonText': 'Next',
      'showNext': true,
    },
    {
      'image': 'assets/images/onboarding3.png',
      'title': 'Unlock The Benefits Of Our Behavioral Health Programs',
      'subtitle': 'Experience the power of behavioral health & wellness guidance to reach your health goals',
      'buttonText': 'Next',
      'showNext': true,
    },
    {
      'image': 'assets/images/onboarding4.png',
      'title': 'Have A Peace Of Mind Accessing Urgent Care 24/7',
      'subtitle': 'Whether its a weekend or late at night, our urgent care doctors are always here for you',
      'buttonText': 'Next',
      'showNext': true,
    },
  ];
}
