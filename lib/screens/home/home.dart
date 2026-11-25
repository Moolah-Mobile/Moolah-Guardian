import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/screens/connect_device/connect_device_screen.dart';
import 'package:moolah/screens/home/widget/SyncDevice.dart';
import 'package:moolah/screens/subscription_screen/subscription_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/images.dart';

import '../../controllers/authController.dart';
import '../../controllers/subscription_controller.dart';
import '../../helper/models/network_history_model.dart';
import '../../helper/models/plan.dart';
import '../../util/common_widgets/plan_gate.dart';
import '../../helper/sharedHelper.dart';
import '../../util/common_widgets/CommonGradientBackground.dart';
import '../main_menu_profile/main_menu_profile.dart';

class Home extends StatefulWidget {
  static const screenName = "home";

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    setController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
        child: GetBuilder<SubscriptionController>(builder: (subscription) => GetBuilder<HomeController>(builder: (homeController) {
      return GetBuilder<AuthController>(builder: (con) {
        final kids = homeController.connectedKids;
        final firstName = Prefs.firstName.get().trim();
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar: menu on the left, the parent's avatar (opens their plan) on the right.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    customGestureDetecter(
                      onTap: () => Get.toNamed(MainMenuProfile.screenName),
                      child: roundedContainer(
                        height: 44,
                        width: 44,
                        shadow: softShadow,
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(AppImages.menu),
                      ),
                    ),
                    const Spacer(),
                    customGestureDetecter(
                      onTap: () => Get.toNamed(SubscriptionScreen.screenName),
                      child: Container(
                        height: 44,
                        width: 44,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.white, boxShadow: softShadow),
                        child: ClipOval(child: SvgPicture.asset(AppImages.person)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    regularText("Welcome back,", fontSize: 15, color: AppColors.black.withValues(alpha: 0.6)),
                    verticalSpace(2),
                    boldText(firstName.isEmpty ? "Your Name" : firstName,
                        fontSize: 28, maxLines: 1, textOverflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: softShadow,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, listEndPadding(context)),
                    children: [
                      _connectCard(),
                      verticalSpace(26),
                      Row(
                        children: [
                          boldText("Synced Devices", fontSize: 18),
                          horizontalSpace(8),
                          pill(
                            child: regularText("${kids.length}",
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.normalGreen),
                          ),
                        ],
                      ),
                      verticalSpace(6),
                      if (kids.isEmpty)
                        _noDevices()
                      else
                        for (final kid in kids)
                          SyncDevice(
                              kidId: kid.connectId ?? kid.kidId ?? "",
                              name: kid.name ?? "Unknown",
                              image: kid.kidPic,
                              active: kid.lastActive ?? "N/A",
                              battery: kid.batteryStatus ?? "0",
                              dataUsedGb: kid.dataUsageBytes == null ? null : formatGb(kid.dataUsageBytes!),
                              batteryLocked: !subscription.allows(Feature.battery),
                              usageLocked: !subscription.allows(Feature.appUsage),
                              isIPad: (kid.deviceType ?? "").toLowerCase().contains("tab")),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      });
    })));
  }

  /// The call to action for linking a child's device.
  Widget _connectCard() {
    return gradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    boldText("Add a device", fontSize: 20, color: AppColors.white),
                    verticalSpace(6),
                    regularText("Enter the code from your child's phone to start protecting it.",
                        fontSize: 13, color: AppColors.white.withValues(alpha: 0.9), height: 1.4),
                  ],
                ),
              ),
              horizontalSpace(12),
              glassTile(
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              ),
            ],
          ),
          CustomButton(
              text: "Connect a Device",
              margin: const EdgeInsets.only(top: 18),
              icon: AppImages.scanBarcode,
              onTap: () {
                if (!requireDeviceSlot()) return;
                Get.find<AuthController>().refreshToken();
                Get.toNamed(ConnectDeviceScreen.screenName);
              }),
        ],
      ),
    );
  }

  Widget _noDevices() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(color: AppColors.veryVeryLightGreen, shape: BoxShape.circle),
            child: Icon(Icons.devices_other_outlined, size: 34, color: AppColors.normalGreen),
          ),
          verticalSpace(14),
          boldText("No devices yet", fontSize: 16),
          verticalSpace(6),
          subHeadingText("Connect your child's phone to see it here.", textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void setController() async {
    await Get.find<AuthController>().refreshToken();
    final plan = Get.find<SubscriptionController>().loadSubscription();
    final home = Get.find<HomeController>();
    await home.getSyncedKidDevices();
    // Data used is a paid stat: wait for the current plan before asking the MDM for it.
    await plan;
    if (planAllows(Feature.appUsage)) home.getDataUsage();
  }
}
