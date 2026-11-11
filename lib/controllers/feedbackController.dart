import 'package:get/get.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/repo/feedbackRepo.dart';
import 'package:moolah/util/customtoast.dart';

class FeedbackContactController extends BaseController {

  postReview(String msg, int rate) async {
    isLoading = true;
    update();
    final res = await FeedbackRepo.postReview(rate.toString(), msg);
    apiToast(res);
    isLoading = false;
    update();
    if(res.isSuccessful){
      Get.back();
    }
  }

  postFeedback(String msg) async {
    isLoading = true;
    update();
    final res = await FeedbackRepo.postFeedback(msg);
    apiToast(res);
    isLoading = false;
    update();
    if(res.isSuccessful){
      Get.back();
    }
  }
}
