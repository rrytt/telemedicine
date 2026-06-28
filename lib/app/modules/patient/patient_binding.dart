import 'package:get/get.dart';
import 'controllers/doctor_search_controller.dart';

class PatientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorSearchController>(() => DoctorSearchController());
  }
}
