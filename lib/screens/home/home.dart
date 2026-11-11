import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/advertisementController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/screens/connect_device/connect_device_screen.dart';
import 'package:moolah/screens/home/widget/SyncDevice.dart';
import 'package:moolah/screens/subscription_screen/subscription_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';

import '../../controllers/authController.dart';
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
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return CommonGradientBackground(
        child: GetBuilder<HomeController>(builder: (homeController) {
      return GetBuilder<AuthController>(builder: (con) {
        return Column(
          children: [
            verticalSpace(40),
            verticalSpace(height * 0.03),
            Expanded(
              child: roundedContainer(
                  borderRadiusWhole: BorderRadius.circular(13).copyWith(
                      bottomRight: Radius.zero, bottomLeft: Radius.zero),
                  padding: const EdgeInsets.all(25)
                      .copyWith(bottom: 0, left: 20, right: 20),
                  margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                  width: width,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 30,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                                left: 0,
                                child: customGestureDetecter(
                                  onTap: (){
                                     Get.toNamed(MainMenuProfile.screenName);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                                    child: SvgPicture.asset(AppImages.menu),
                                  ),
                                ))
                          ],
                        ),
                      ),
                      verticalSpace(30),
                      customGestureDetecter(
                        onTap: () {
                          Get.toNamed(SubscriptionScreen.screenName);
                        },
                        child: Column(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(1000),
                                child: SvgPicture.asset(AppImages.person)),
                            verticalSpace(15),
                            bigSubHeading(
                                Prefs.firstName.get().trim().isEmpty
                                    ? "Your Name"
                                    : Prefs.firstName.get()),
                          ],
                        ),
                      ),
                      verticalSpace(15),
                      CustomButton(
                          text: "Connect a Device",
                          notExpanded: true,
                          icon: AppImages.scanBarcode,
                          onTap: () {
                            Get.find<AuthController>().refreshToken();
                            Get.toNamed(ConnectDeviceScreen.screenName);
                          }),
                      verticalSpace(height * 0.07),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: bigSubHeading(
                              "Synced Devices (${homeController.connectedKids.length})")),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < homeController.connectedKids.length;
                                  i++)
                                SyncDevice(
                                    kidId:
                                    homeController.connectedKids[i].connectId ??
                                    homeController.connectedKids[i].kidId ??
                                    "",
                                    name: homeController.connectedKids[i].name ?? "Unknown",
                                    image:
                                        homeController.connectedKids[i].kidPic,
                                    active: homeController
                                        .connectedKids[i].lastActive ?? "N/A",
                                    battery: homeController
                                        .connectedKids[i].batteryStatus ?? "0",
                                    mbps: homeController
                                        .connectedKids[i].dataUsageStatus ?? "0",
                                    isIPad: (homeController
                                        .connectedKids[i].deviceType ?? "")
                                        .toLowerCase()
                                        .contains("tab"))
                            ],
                          ),
                        ),
                      )
                    ],
                  )),
            ),
          ],
        );
      });
    }));
  }

  void setController() async {
    Get.find<AdvertisementController>().loadBanner();
    await Get.find<AuthController>().refreshToken();
    await Get.find<HomeController>().getSyncedKidDevices();
  }
}
