import 'package:get/get.dart';

class BaseController extends GetxController implements GetxService {
  final RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) {
    _isLoading.value = value;
    update(); // Support both GetBuilder and Obx
  }
}
