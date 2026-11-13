import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/screens/blacklist/blacklist_screen.dart';
import 'package:moolah/screens/sync_device_detail_screen/screens/live_location.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/common_widgets/loader.dart';
import 'package:moolah/util/images.dart';

import '../../helper/models/device_detail_model.dart';
import '../../helper/models/kids_model.dart';
import '../../util/apptext.dart';
import '../../util/common_widgets/CommonGradientBackground.dart';
import '../../util/common_widgets/common_text_field.dart';

class SyncDeviceDetailScreen extends StatefulWidget {
  static const screenName = "syncDeviceDetailScreen";

  const SyncDeviceDetailScreen({required this.kidId, Key? key}) : super(key: key);
  final String kidId;

  @override
  State<SyncDeviceDetailScreen> createState() => _SyncDeviceDetailScreenState();
}

class _SyncDeviceDetailScreenState extends State<SyncDeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  String headingText = "Black List App";
  int prevIndex = 0;

  @override
  void initState() {
    super.initState();
    initAPIS();
    tabController = TabController(length: 3, vsync: this);
    tabController?.addListener(() {
      final currentIndex = tabController?.index;
      if (currentIndex != prevIndex) {
        setState(() {
          headingText = currentIndex == 0 ? "Black List App" : "Add Black List URL";
        });
        prevIndex = currentIndex ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (homeController) {
      final kid = homeController.getSelectedKid(widget.kidId);
      return CommonGradientBackground(
        child: Loader(
          c: homeController,
          child: Column(
            children: [
              verticalSpace(20),
              commonAppBar(
                  heading:
                      "${kid.name?.split(" ")[0] ?? "Kid"}'s Summary"),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0).copyWith(bottom: 0),
                  child: Column(
                    children: [
                      headingWidget(homeController),
                      verticalSpace(15),
                      Expanded(
                        child: roundedContainer(
                            borderRadius: 15,
                            borderRadiusWhole: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                tabBar(),
                                if (tabController?.index != 2)
                                  CustomButton(
                                    text: headingText,
                                    onTap: () {
                                      if (tabController?.index != 1) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const BlackListScreen(),
                                          ),
                                        );
                                      } else {
                                        _showAddBlackListDialog();
                                      }
                                    },
                                  ),
                                verticalSpace(0),
                                if (tabController?.index == 0)
                                  appSection(homeController)
                                else if (tabController?.index == 1)
                                  urlSection(homeController)
                                else if (tabController?.index == 2)
                                  messagesSection(homeController),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showAddBlackListDialog() async {
    String url = "";
    TextEditingController urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Builder(builder: (context) {
            var width = MediaQuery.of(context).size.width;
            return SizedBox(
              width: width - 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 26,
                      ),
                      boldText('Black List URL', fontSize: 18),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomTextField(
                      hintText: "Enter URL",
                      textEditingController: urlController,
                    ),
                  ),
                  CustomButton(
                    text: 'Black List',
                    onTap: () {
                      if (urlController.text.trim().isNotEmpty) {
                        url = urlController.text.trim();
                      }
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ],
              ),
            );
          }),
        );
      },
    );
    if (url.isNotEmpty) {
      Get.find<HomeController>().addBlacklistUrl(kidId: widget.kidId, url: url);
    }
  }

  Widget appSection(HomeController homeController) {
    final kid = homeController.getSelectedKid(widget.kidId);
    final apps = kid.deviceDetail?.data?.apps ?? [];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16)
                  .copyWith(bottom: 25, top: 0),
              child: boldText('All Apps', fontSize: 18),
            ),
            for (int i = 0; i < apps.length; i++)
              if (!(apps[i].systemApp ?? false))
                appItem(apps[i], kidId: widget.kidId),
          ],
        ),
      ),
    );
  }

  Widget appItem(App listOfInstalledApp, {required String kidId}) {
    String appName = listOfInstalledApp.appName ?? "Unknown App";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText(appName, fontSize: 14),
              ],
            ),
          ),
          PopupMenuButton(
            icon: SvgPicture.asset('assets/images/home/more.svg'),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () {
                  Get.find<HomeController>().deleteApp(
                      kidId: kidId,
                      appPackage: listOfInstalledApp.packageName ?? "");
                },
                padding: const EdgeInsets.only(left: 5),
                height: 30,
                value: 1,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/images/home/trash.svg'),
                    const SizedBox(
                      width: 10,
                    ),
                    regularText("Uninstall App",
                        color: AppColors.red, fontSize: 13)
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  Get.find<HomeController>().blacklistApp(
                      kidId: kidId,
                      appPackage: listOfInstalledApp.packageName ?? "");
                },
                padding: const EdgeInsets.only(left: 5),
                height: 30,
                value: 2,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/images/home/slash.svg'),
                    const SizedBox(
                      width: 10,
                    ),
                    regularText("Disable App", fontSize: 13)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget urlSection(HomeController homeController) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: roundedContainer(
            color: AppColors.lightGrey,
            borderRadius: 15,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                verticalSpace(16),
                bigSubHeading("Platinum Feature"),
                verticalSpace(10),
                subHeadingText(
                  "Browser History is available for Platinum users. This feature is coming soon!",
                  textAlign: TextAlign.center,
                  height: 1.4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget messagesSection(HomeController homeController) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: roundedContainer(
            color: AppColors.lightGrey,
            borderRadius: 15,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                verticalSpace(16),
                bigSubHeading("Platinum Feature"),
                verticalSpace(10),
                subHeadingText(
                  "Messages monitoring is available for Platinum users. This feature is coming soon!",
                  textAlign: TextAlign.center,
                  height: 1.4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget percentageContainer(
      Color color, String icon, String text, String value, String t,
      {bool otherOne = false}) {
    return Expanded(
      child: roundedContainer(
          padding: const EdgeInsets.all(7),
          color: AppColors.lightGrey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  roundedContainer(
                    padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                    color: color,
                    child: SvgPicture.asset(
                      icon,
                      colorFilter:
                          ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                    ),
                  ),
                  horizontalSpace(3),
                  if (otherOne)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: regularText(text,
                          fontSize: 15, fontWeight: FontWeight.w600),
                    )
                  else
                    subHeadingText(text, fontSize: 10),
                ],
              ),
              if (!otherOne)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bigHeadingText(value, fontSize: 20),
                    Column(
                      children: [
                        bigHeadingText(t, fontSize: 12),
                        verticalSpace(2)
                      ],
                    ),
                  ],
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                )
            ],
          )),
    );
  }

  Widget headingWidget(HomeController homeController) {
    Kid kid = homeController.getSelectedKid(widget.kidId);
    final stats = kid.deviceDetail?.data?.realTimeStats;

    return roundedContainer(
      borderRadius: 15,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: ClipRRect(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(1000),
                      child: kid.kidPic == null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(1000),
                              child: SvgPicture.asset(AppImages.person))
                          : Image.network(kid.kidPic!,
                              errorBuilder: (c, e, v) =>
                                  SvgPicture.asset(AppImages.person)),
                    )),
                  ),
                  horizontalSpace(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bigSubHeading(kid.name),
                      iconText(AppImages.clock, "Active ${kid.lastActive}",
                          isItalic: true),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      customGestureDetecter(
                          onTap: () {
                            _showAdDialog();
                          },
                          child: SvgPicture.asset(AppImages.information)),
                      horizontalSpace(10),
                      customSwitch(value: kid.walletEnabled ?? false)
                    ],
                  ),
                  verticalSpace(2),
                  regularText(
                      kid.walletEnabled ?? false
                          ? "Wallet Enabled"
                          : "Wallet Disabled",
                      color: kid.walletEnabled ?? false
                          ? AppColors.normalGreen
                          : AppColors.grey,
                      fontSize: 10,
                      italic: true)
                ],
              )
            ],
          ),
          verticalSpace(20),
          Row(
            children: [
              percentageContainer(
                  AppColors.yellow,
                  AppImages.emptyBattery,
                  "Battery %",
                  stats?.batteryLevel?.toString() ?? "0",
                  "%"),
              horizontalSpace(10),
              percentageContainer(AppColors.blue, AppImages.global, "Data Used",
                  stats?.deviceDataUsage?.toString() ?? "0", "GB")
            ],
          ),
          verticalSpace(10),
          customGestureDetecter(
            onTap: () {
              Get.toNamed(LiveLocation.screenName, arguments: {
                "lat": stats?.currentLatitude,
                "long": stats?.currentLongitude,
                "deviceId": widget.kidId,
              });
            },
            child: Row(
              children: [
                percentageContainer(AppColors.purple, AppImages.location,
                    "View Last Location", kid.batteryStatus ?? "", "%",
                    otherOne: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabBar() {
    return roundedContainer(
      padding: const EdgeInsets.all(5),
      color: AppColors.veryVeryLightGreen,
      child: Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                surfaceContainerHighest: Colors.transparent)),
        child: TabBar(
            overlayColor:
                WidgetStateColor.resolveWith((states) => AppColors.lightGreen),
            indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.normalGreen),
            onTap: (v) {
              setState(() {});
            },
            controller: tabController,
            tabs: [
              textForTab("Apps", tabController!.index == 0),
              textForTab("Browser History", tabController!.index == 1),
              textForTab("Messages", tabController!.index == 2),
            ]),
      ),
    );
  }

  Widget customSwitch({bool showM = true, required bool value}) {
    double size = 35;
    bool switchButton = value;
    return customGestureDetecter(
      onTap: () {
        setState(() {
          switchButton = !switchButton;
        });
        Get.find<HomeController>()
            .enableWallet(value: switchButton, kidId: widget.kidId);
      },
      child: Stack(
        alignment: switchButton ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          roundedContainer(
              borderRadius: 30,
              color:
                  switchButton ? AppColors.lightGreen : AppColors.darkLightGrey,
              height: size * 0.65,
              width: size * 1.2),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              roundedContainer(
                borderRadius: 30,
                color: Colors.white,
                margin: EdgeInsets.all(size * 0.083), //2.5
                height: size * 0.5,
                width: size * 0.5,
              ),
              if (showM)
                regularText("M!",
                    customFontFamily: fontFamilyPraise,
                    color: switchButton
                        ? AppColors.lightGreen
                        : AppColors.darkLightGrey,
                    fontSize: 11)
            ],
          ),
        ],
      ),
    );
  }

  void _showAdDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return Material(
            type: MaterialType.transparency,
            child: Center(
              child: roundedContainer(
                  margin: const EdgeInsets.all(30),
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppImages.earningImage),
                      verticalSpace(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          bigHeadingText("Enable Earning "),
                          bigHeadingText("M!",
                              customFontFamily: fontFamilyPraise),
                        ],
                      ),
                      verticalSpace(20),
                      subHeadingText("""Earning M! is enabled by default
 in all Moolah M1 tablets. Use the
 Guardian App to disable Moolah Ads and
 Wallet from Moolah Guarded devices.


                  """),
                      verticalSpace(20),
                      customSwitch(
                          showM: false,
                          value: Get.find<HomeController>()
                                  .getSelectedKid(widget.kidId)
                                  .walletEnabled ??
                              false),
                    ],
                  )),
            ),
          );
        });
  }

  void initAPIS() async {
    Get.find<HomeController>().getAppUsage(kidId: widget.kidId);
    await Get.find<AuthController>().refreshToken();
    Get.find<HomeController>().getDeviceDetail(kidId: widget.kidId);
    Get.find<HomeController>().getBlacklistUrls(kidId: widget.kidId);
    Get.find<HomeController>().getWalletStatus(kidId: widget.kidId);
    Get.find<HomeController>().getMSMSMonitoringStatus(kidId: widget.kidId);
  }

  Widget comingSoon() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AppImages.comingSoon),
        ],
      ),
    );
  }
}
