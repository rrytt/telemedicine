import 'package:get/get.dart';
import 'controllers/doctor_chat_controller.dart';

class DoctorChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorChatController>(
      () => DoctorChatController(),
    );
  }
}