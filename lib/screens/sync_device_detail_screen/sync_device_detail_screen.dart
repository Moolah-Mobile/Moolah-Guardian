import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/advertisementController.dart';
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

import '../../controllers/subscription_controller.dart';
import '../../helper/models/device_detail_model.dart';
import '../../helper/models/plan.dart';
import '../../util/common_widgets/plan_gate.dart';
import '../../util/common_widgets/app_search_field.dart';
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
  final appSearch = TextEditingController();
  final appSearchFocus = FocusNode();
  String appQuery = "";

  // While the parent types in the app search, the summary card collapses so the list fits above the keyboard.
  // It comes back as soon as the keyboard closes, even if the field keeps focus (Android's Back key).
  bool get _searchingApps => appSearchFocus.hasFocus && MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  void dispose() {
    appSearch.dispose();
    appSearchFocus.dispose();
    tabController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    appSearchFocus.addListener(() => setState(() {}));
    // initAPIS updates HomeController (loader state), which is not allowed while this screen is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => initAPIS());
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
    return GetBuilder<SubscriptionController>(builder: (_) => GetBuilder<HomeController>(builder: (homeController) {
      final kid = homeController.getSelectedKid(widget.kidId);
      return CommonGradientBackground(
        // Resize only for the app search; the dialogs' fields move above the keyboard on their own.
        resizeForKeyboard: _searchingApps,
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
                      if (!_searchingApps) ...[
                        headingWidget(homeController),
                        verticalSpace(15),
                      ],
                      // Keyed so the tabs and the app search keep their state when the card above collapses.
                      Expanded(
                        key: const ValueKey("tabs_panel"),
                        child: roundedContainer(
                            borderRadius: 15,
                            borderRadiusWhole: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                tabBar(),
                                if (_tabUnlocked && !_searchingApps)
                                  CustomButton(
                                    text: headingText,
                                    onTap: () {
                                      if (tabController?.index != 1) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BlackListScreen(kidId: widget.kidId),
                                          ),
                                        );
                                      } else {
                                        _showAddBlackListDialog();
                                      }
                                    },
                                  ),
                                verticalSpace(0),
                                if (tabController?.index == 0)
                                  planAllows(Feature.deleteApps)
                                      ? appSection(homeController)
                                      : Expanded(child: lockedFeaturePanel(Feature.deleteApps, "Deleting and blocking apps"))
                                else if (tabController?.index == 1)
                                  planAllows(Feature.browserHistory)
                                      ? urlSection(homeController)
                                      : Expanded(child: lockedFeaturePanel(Feature.browserHistory, "Browser history and URL blocking"))
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
    }));
  }

  /// The Messages tab has no button, and a locked tab shows its upgrade panel instead.
  bool get _tabUnlocked {
    switch (tabController?.index) {
      case 0:
        return planAllows(Feature.blockApps);
      case 1:
        return planAllows(Feature.urlBlacklist);
      default:
        return false;
    }
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
    // getInstalledApps lists every app; getDeviceDetails may report only some of them.
    final apps = kid.installedApps.isNotEmpty
        ? kid.installedApps
        : (kid.deviceDetail?.data?.apps ?? []);
    final shown = apps.where((a) => appMatchesQuery(a, appQuery)).toList();
    final filtering = appQuery.trim().isNotEmpty;
    return Expanded(
      key: const ValueKey("apps_section"),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          padding: const EdgeInsets.only(bottom: adBannerSpace),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // Keep these children fixed while searching: removing rows above the search field rebuilds it
          // and closes the keyboard.
          children: [
            comingSoonTile(Icons.location_on_outlined, "Delete apps by location and time"),
            comingSoonTile(Icons.lock_clock_outlined, "Block apps until unlocked"),
            verticalSpace(10),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: boldText(filtering ? 'All Apps · ${shown.length} of ${apps.length}' : 'All Apps',
                  fontSize: 18),
            ),
            if (apps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSearchField(
                  controller: appSearch,
                  focusNode: appSearchFocus,
                  onChanged: (value) => setState(() => appQuery = value),
                ),
              ),
            if (filtering && shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: regularText('No apps match "${appQuery.trim()}"', color: AppColors.grey, fontSize: 14),
                ),
              ),
            for (final app in shown)
              appItem(app,
                  kidId: widget.kidId,
                  blocked: kid.blockedPackages.contains(app.packageName)),
          ],
        ),
      ),
    );
  }

  Widget comingSoonTile(IconData icon, String title) {
    return customGestureDetecter(
      onTap: () => showComingSoon(title),
      child: roundedContainer(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        color: AppColors.lightGrey,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.normalGreen),
            horizontalSpace(10),
            Expanded(child: regularText(title, fontSize: 13, fontWeight: FontWeight.w600)),
            roundedContainer(
              borderRadius: 20,
              color: AppColors.veryVeryLightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: regularText("Coming soon", fontSize: 10, color: AppColors.normalGreen, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget appItem(App listOfInstalledApp, {required String kidId, required bool blocked}) {
    String appName = listOfInstalledApp.appName ?? "Unknown App";
    final pkg = listOfInstalledApp.packageName ?? "";
    final systemApp = HomeController.isSystemApp(listOfInstalledApp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText(appName, fontSize: 14, color: blocked ? AppColors.red : Colors.black),
                regularText(
                    "${systemApp ? "System app" : "Installed app"}${blocked ? " · Disabled" : ""}",
                    color: AppColors.grey,
                    fontSize: 11),
              ],
            ),
          ),
          if (!HomeController.isProtectedApp(pkg))
          PopupMenuButton<int>(
            icon: SvgPicture.asset('assets/images/home/more.svg'),
            onSelected: (value) {
              if (value == 1) {
                _confirmUninstall(appName, pkg);
              } else {
                Get.find<HomeController>()
                    .setAppBlocked(kidId: kidId, appPackage: pkg, blocked: !blocked);
              }
            },
            itemBuilder: (context) => [
              // System apps cannot be uninstalled; they can only be disabled.
              if (!systemApp)
                PopupMenuItem<int>(
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
              PopupMenuItem<int>(
                padding: const EdgeInsets.only(left: 5),
                height: 30,
                value: 2,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/images/home/slash.svg'),
                    const SizedBox(
                      width: 10,
                    ),
                    regularText(blocked ? "Enable App" : "Disable App", fontSize: 13)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmUninstall(String appName, String pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: boldText("Uninstall $appName?", fontSize: 18),
        content: regularText(
            "$appName will be removed from the child's device as soon as it is online.",
            fontSize: 14),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: regularText("Cancel", fontSize: 14)),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Get.find<HomeController>().deleteApp(kidId: widget.kidId, appPackage: pkg);
              },
              child: regularText("Uninstall", color: AppColors.red, fontSize: 14)),
        ],
      ),
    );
  }

  Widget urlSection(HomeController homeController) {
    final history = homeController.getSelectedKid(widget.kidId).networkHistory;
    final websites = history?.websites ?? [];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          padding: const EdgeInsets.only(bottom: adBannerSpace),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16)
                  .copyWith(bottom: 15, top: 0),
              child: boldText('Websites (last 7 days)', fontSize: 18),
            ),
            if (history == null)
              subHeadingText("Loading browser history...")
            else if (websites.isEmpty)
              subHeadingText("No websites visited in the last 7 days.")
            else
              for (final site in websites)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      boldText(site.domain, fontSize: 14),
                      regularText(
                          [
                            if (site.appName != null) site.appName!,
                            if (site.time != null)
                              "${site.time!.day}/${site.time!.month} ${site.time!.hour.toString().padLeft(2, '0')}:${site.time!.minute.toString().padLeft(2, '0')}",
                          ].join(" · "),
                          color: AppColors.grey,
                          fontSize: 11),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(IconData icon, String text, VoidCallback onTap, {bool locked = false, bool danger = false}) {
    final color = danger && !locked ? AppColors.red : null;
    return Expanded(
      child: customGestureDetecter(
        onTap: onTap,
        child: roundedContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: AppColors.lightGrey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(locked ? Icons.lock_outline : icon, size: 18, color: color),
              horizontalSpace(6),
              regularText(text, fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // Erasing a child's device cannot be undone, so the parent has to type WIPE to confirm.
  void _confirmWipe() {
    showDialog(
      context: context,
      builder: (_) => _WipeConfirmDialog(
        onConfirm: () => Get.find<HomeController>().wipeDevice(kidId: widget.kidId),
      ),
    );
  }

  void _confirmReboot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: boldText("Reboot device?", fontSize: 18),
        content: regularText(
            "The child's device will restart as soon as it is online.",
            fontSize: 14),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: regularText("Cancel", fontSize: 14)),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Get.find<HomeController>().sendDeviceAction(
                    kidId: widget.kidId,
                    action: "reboot",
                    successMessage: "Reboot sent to the device");
              },
              child: regularText("Reboot", color: AppColors.red, fontSize: 14)),
        ],
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
                const Icon(Icons.hourglass_top, size: 48, color: Colors.grey),
                verticalSpace(16),
                bigSubHeading("Coming soon"),
                verticalSpace(10),
                subHeadingText(
                  "Messages monitoring is coming soon. We'll let you know when it's ready.",
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
      {bool otherOne = false, Feature? feature}) {
    final locked = feature != null && !planAllows(feature);
    return Expanded(
      child: customGestureDetecter(
        onTap: locked ? () => withFeature(feature, text, () {}) : null,
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
              if (locked)
                const Icon(Icons.lock_outline, size: 20, color: Colors.grey)
              else if (!otherOne)
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
      ),
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
                            withFeature(Feature.wallet, "The M! wallet", _showAdDialog);
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
                  "%",
                  feature: Feature.battery),
              horizontalSpace(10),
              percentageContainer(AppColors.blue, AppImages.global, "Data Used",
                  kid.networkHistory?.dataUsageGb ?? stats?.deviceDataUsage?.toString() ?? "0", "GB",
                  feature: Feature.appUsage)
            ],
          ),
          verticalSpace(10),
          customGestureDetecter(
            onTap: () {
              Get.toNamed(LiveLocation.screenName, arguments: {
                "lat": stats?.currentLatitude,
                "long": stats?.currentLongitude,
                "deviceId": kid.kidId ?? widget.kidId,
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
          verticalSpace(10),
          Row(
            children: [
              actionButton(Icons.sync, "Sync now", () {
                withFeature(Feature.deviceActions, "Sync now", () {
                  Get.find<HomeController>().sendDeviceAction(
                      kidId: widget.kidId,
                      action: "configUpdated",
                      successMessage: "Sync sent to the device");
                });
              }, locked: !planAllows(Feature.deviceActions)),
              horizontalSpace(10),
              actionButton(Icons.restart_alt, "Reboot",
                  () => withFeature(Feature.deviceActions, "Reboot", _confirmReboot),
                  locked: !planAllows(Feature.deviceActions)),
            ],
          ),
          verticalSpace(10),
          Row(
            children: [
              actionButton(Icons.phonelink_erase, "Wipe device",
                  () => withFeature(Feature.deviceActions, "Wiping the device", _confirmWipe),
                  locked: !planAllows(Feature.deviceActions), danger: true),
            ],
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
        withFeature(Feature.wallet, "The M! wallet", () {
          setState(() {
            switchButton = !switchButton;
          });
          Get.find<HomeController>()
              .enableWallet(value: switchButton, kidId: widget.kidId);
        });
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
    final home = Get.find<HomeController>();
    // getAppUsage also carries the device's location, which every plan shows.
    home.getAppUsage(kidId: widget.kidId);
    // Gated data waits for the current plan, so a fresh upgrade isn't missed because of a stale cached plan.
    await Get.find<SubscriptionController>().loadSubscription();
    if (planAllows(Feature.browserHistory)) home.getNetworkHistory(kidId: widget.kidId);
    if (planAllows(Feature.deleteApps)) home.getInstalledApps(kidId: widget.kidId);
    await Get.find<AuthController>().refreshToken();
    home.getDeviceDetail(kidId: widget.kidId);
    if (planAllows(Feature.urlBlacklist)) home.getBlacklistUrls(kidId: widget.kidId);
    if (planAllows(Feature.wallet)) home.getWalletStatus(kidId: widget.kidId);
    home.getMSMSMonitoringStatus(kidId: widget.kidId);
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

/// Asks the parent to type WIPE before a factory reset. The dialog owns its text controller and disposes it
/// in [dispose], after the closing animation; disposing it when the route pops crashes the fading dialog.
class _WipeConfirmDialog extends StatefulWidget {
  const _WipeConfirmDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<_WipeConfirmDialog> createState() => _WipeConfirmDialogState();
}

class _WipeConfirmDialogState extends State<_WipeConfirmDialog> {
  final typed = TextEditingController();

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = typed.text.trim().toUpperCase() == "WIPE";
    return AlertDialog(
      title: boldText("Wipe this device?", fontSize: 18, color: AppColors.red),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          regularText(
              "This factory resets the child's device as soon as it is online. All apps, photos and "
              "data on it are erased and cannot be recovered, and it will need to be set up and linked again.",
              fontSize: 14,
              height: 1.4),
          verticalSpace(14),
          regularText("Type WIPE to confirm.", fontSize: 14, fontWeight: FontWeight.w600),
          verticalSpace(6),
          TextField(
            key: const ValueKey("wipe_confirm"),
            controller: typed,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: "WIPE", isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: regularText("Cancel", fontSize: 14)),
        TextButton(
            onPressed: confirmed
                ? () {
                    Navigator.pop(context);
                    widget.onConfirm();
                  }
                : null,
            child: regularText("Wipe device",
                color: confirmed ? AppColors.red : AppColors.grey, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
