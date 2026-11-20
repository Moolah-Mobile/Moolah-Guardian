import 'package:get/get.dart';
import 'package:moolah/controllers/advertisementController.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/controllers/connectDeviceController.dart';
import 'package:moolah/controllers/feedbackController.dart';
import 'package:moolah/controllers/homeController.dart';

import '../../controllers/subscription_controller.dart';
import '../../util/mixpanel_events.dart';

init(){
  Get.lazyPut(() => BaseController());
  Get.lazyPut(() => AuthController());
  Get.lazyPut(() => HomeController());
  Get.lazyPut(() => BlockRulesController(), fenix: true);
  Get.lazyPut(() => ConnectDeviceController());
  Get.lazyPut(() => AdvertisementController());
  Get.lazyPut(() => MixPanelEventsController());
  Get.lazyPut(() => FeedbackContactController());
   Get.lazyPut(() => SubscriptionController());
}