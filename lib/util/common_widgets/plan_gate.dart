import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/screens/subscription_screen/subscription_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

bool planAllows(Feature feature) => Get.find<SubscriptionController>().allows(feature);

/// Runs [action] when the parent's plan includes [feature]; otherwise offers the plan that does.
void withFeature(Feature feature, String featureName, VoidCallback action) {
  if (planAllows(feature)) {
    action();
  } else {
    showUpgradeDialog(Plan.requiredFor(feature), "$featureName is part of the");
  }
}

/// True when the parent's plan has room for one more device; otherwise explains the limit.
bool requireDeviceSlot() {
  final plan = Get.find<SubscriptionController>().currentPlan;
  final connected = Get.find<HomeController>().connectedKids.length;
  if (plan.canAddDevice(connected)) return true;
  final next = Plan.requiredForDevices(connected + 1);
  final limit = "Your ${plan.title} plan includes ${plan.deviceLimit} device${plan.deviceLimit == 1 ? "" : "s"}.";
  if (next == null) {
    showLimitDialog("$limit Remove a device before adding another.");
  } else {
    showUpgradeDialog(next, "$limit Managing up to ${next.deviceLimit} devices is part of the");
  }
  return false;
}

void showLimitDialog(String message) {
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: boldText("Device limit reached", fontSize: 18),
    content: regularText(message, fontSize: 14, height: 1.4),
    actions: [
      TextButton(onPressed: Get.back, child: regularText("OK", color: AppColors.normalGreen, fontSize: 14)),
    ],
  ));
}

/// [reason] is completed with the plan name, so it reads e.g. "Browser history is part of the Premium plan."
void showUpgradeDialog(Plan plan, String reason) {
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: Row(
      children: [
        Icon(Icons.workspace_premium, color: AppColors.normalGreen),
        horizontalSpace(8),
        boldText("Upgrade to ${plan.title}", fontSize: 18),
      ],
    ),
    content: regularText("$reason ${plan.title} plan (${plan.priceLabel}).", fontSize: 14, height: 1.4),
    actions: [
      TextButton(onPressed: Get.back, child: regularText("Not now", fontSize: 14)),
      TextButton(
        onPressed: () {
          Get.back();
          Get.toNamed(SubscriptionScreen.screenName);
        },
        child: regularText("See plans", color: AppColors.normalGreen, fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ],
  ));
}

/// For features that are announced in a plan but not built yet.
void showComingSoon(String featureName) {
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: Row(
      children: [
        Icon(Icons.hourglass_top, color: AppColors.normalGreen),
        horizontalSpace(8),
        boldText("Coming soon", fontSize: 18),
      ],
    ),
    content: regularText("$featureName is coming soon. We'll let you know when it's ready.", fontSize: 14, height: 1.4),
    actions: [
      TextButton(onPressed: Get.back, child: regularText("OK", color: AppColors.normalGreen, fontSize: 14)),
    ],
  ));
}

/// Shown in place of a section the parent's plan doesn't include.
Widget lockedFeaturePanel(Feature feature, String featureName) {
  final plan = Plan.requiredFor(feature);
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: roundedContainer(
        color: AppColors.lightGrey,
        borderRadius: 15,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 44, color: Colors.grey),
            verticalSpace(14),
            bigSubHeading("${plan.title} Feature"),
            verticalSpace(10),
            subHeadingText(
              "$featureName is available on the ${plan.title} plan (${plan.priceLabel}) and above.",
              textAlign: TextAlign.center,
              height: 1.4,
            ),
            verticalSpace(16),
            CustomButton(
              text: "See plans",
              margin: EdgeInsets.zero,
              onTap: () => Get.toNamed(SubscriptionScreen.screenName),
            ),
          ],
        ),
      ),
    ),
  );
}
