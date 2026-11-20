import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/advertisementController.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart' show childFirstName, childNow, ruleBlocksNow;
import 'package:moolah/screens/block_rules/places_screen.dart';
import 'package:moolah/screens/block_rules/schedules_screen.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
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

class _SyncDeviceDetailScreenState extends State<SyncDeviceDetailScreen> with SingleTickerProviderStateMixin {
  TabController? tabController;
  String headingText = "Blocked Apps";
  int prevIndex = 0;
  final appSearch = TextEditingController();
  final appSearchFocus = FocusNode();
  String appQuery = "";

  // While the parent types in the app search, the summary card collapses so the list fits above the keyboard.
  // It comes back as soon as the keyboard closes, even if the field keeps focus (Android's Back key).
  bool get _searchingApps => appSearchFocus.hasFocus && MediaQuery.of(context).viewInsets.bottom > 0;

  // The ad banner floats just above the keyboard and would cover the search results, so it is hidden
  // while searching and shown again when the keyboard closes.
  bool _bannerHiddenForSearch = false;

  // Once the search keyboard has been shown and is closed again (Android's Back key), the field gives up
  // focus, so the keyboard doesn't pop up by itself when the parent comes back from another screen.
  bool _searchKeyboardShown = false;

  void _releaseSearchFocusWhenKeyboardCloses() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (appSearchFocus.hasFocus && keyboardOpen) {
      _searchKeyboardShown = true;
    } else if (appSearchFocus.hasFocus && !keyboardOpen && _searchKeyboardShown) {
      _searchKeyboardShown = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => appSearchFocus.unfocus());
    } else if (!appSearchFocus.hasFocus) {
      _searchKeyboardShown = false;
    }
  }

  void _syncBannerWithSearch(bool searching) {
    if (searching == _bannerHiddenForSearch) return;
    _bannerHiddenForSearch = searching;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searching) {
        IronSource.hideBanner();
      } else {
        IronSource.displayBanner();
      }
    });
  }

  @override
  void dispose() {
    if (_bannerHiddenForSearch) IronSource.displayBanner();
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
    tabController = TabController(length: 4, vsync: this, animationDuration: Duration.zero);
    tabController?.addListener(() {
      final currentIndex = tabController?.index;
      if (currentIndex != prevIndex) {
        setState(() {
          headingText = currentIndex == 0 ? "Blocked Apps" : "Add Black List URL";
        });
        prevIndex = currentIndex ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _releaseSearchFocusWhenKeyboardCloses();
    _syncBannerWithSearch(_searchingApps);
    return GetBuilder<SubscriptionController>(
        builder: (_) => GetBuilder<HomeController>(builder: (homeController) {
              if (homeController.findKid(widget.kidId) == null) {
                return deviceUnavailable(context, homeController);
              }
              final kid = homeController.getSelectedKid(widget.kidId);
              return CommonGradientBackground(
                // Resize only for the app search; the dialogs' fields move above the keyboard on their own.
                resizeForKeyboard: _searchingApps,
                child: Loader(
                  c: homeController,
                  child: Column(
                    children: [
                      verticalSpace(20),
                      commonAppBar(heading: "${kid.name?.split(" ")[0] ?? "Kid"}'s Summary"),
                      // The summary card scrolls away as the tab's list scrolls up, the tabs stay pinned, and the
                      // card comes back when the list is scrolled back to the top.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0).copyWith(bottom: 0),
                          child: NestedScrollView(
                            headerSliverBuilder: (context, innerBoxIsScrolled) => [
                              SliverToBoxAdapter(
                                child: _searchingApps
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(bottom: 15),
                                        child: headingWidget(homeController),
                                      ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _PinnedTabBar(
                                  height: _tabBarExtent,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                    alignment: Alignment.topCenter,
                                    child: tabBar(),
                                  ),
                                ),
                              ),
                            ],
                            // Keyed so the tabs' lists and the app search keep their state when the card collapses.
                            body: Container(
                              key: const ValueKey("tabs_panel"),
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  if (tabController?.index == 0)
                                    planAllows(Feature.deleteApps)
                                        ? appSection(homeController)
                                        : Expanded(
                                            child: lockedFeaturePanel(Feature.deleteApps, "Deleting and blocking apps"))
                                  else if (tabController?.index == 1)
                                    planAllows(Feature.browserHistory)
                                        ? urlSection(homeController)
                                        : Expanded(
                                            child: lockedFeaturePanel(
                                                Feature.browserHistory, "Browser history and URL blocking"))
                                  else if (tabController?.index == 2)
                                    messagesSection(homeController)
                                  else if (tabController?.index == 3)
                                    callsSection(homeController),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }));
  }

  // Height of the pinned bar: 10 top padding plus the tab bar (5 padding each side around a 46 tall TabBar).
  static const double _tabBarExtent = 12 + 56 + 6;

  /// "Blocked Apps" or "Add Black List URL" at the top of the tab's list, so it scrolls away with it.
  Widget _tabActionButton() {
    if (!_tabUnlocked) return const SizedBox.shrink();
    return CustomButton(
      text: headingText,
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        if (tabController?.index != 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BlackListScreen(kidId: widget.kidId)),
          );
        } else {
          _showAddBlackListDialog();
        }
      },
    );
  }

  /// Shown instead of the summary when this device isn't in the device list (for example while the list
  /// reloads). Drawing the summary for a missing device used to crash, or show another device's data.
  Widget deviceUnavailable(BuildContext context, HomeController homeController) {
    return CommonGradientBackground(
      child: Loader(
        c: homeController,
        child: Column(
          children: [
            verticalSpace(20),
            commonAppBar(heading: "Device"),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: roundedContainer(
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phonelink_off, size: 44, color: AppColors.grey),
                        verticalSpace(14),
                        bigSubHeading("This device isn't available right now"),
                        verticalSpace(10),
                        subHeadingText(
                          "It isn't in your device list at the moment. Go back to Home and open it again.",
                          textAlign: TextAlign.center,
                          height: 1.4,
                        ),
                        verticalSpace(18),
                        CustomButton(
                          text: "Go back",
                          margin: EdgeInsets.zero,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final apps = (kid.installedApps.isNotEmpty ? kid.installedApps : (kid.deviceDetail?.data?.apps ?? <App>[]))
        .where(HomeController.isUserApp)
        .toList();
    final shown = apps.where((a) => appMatchesQuery(a, appQuery)).toList();
    final filtering = appQuery.trim().isNotEmpty;
    // While typing, results start right under the search box; with the keyboard closed, Blocked Apps and the
    // rest of the tab are back.
    final compact = _searchingApps;
    return Expanded(
      key: const ValueKey("apps_section"),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // The search box sits above the list, outside it, so rows above the results can come and go
            // without rebuilding the field and closing the keyboard.
            if (apps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: AppSearchField(
                  controller: appSearch,
                  focusNode: appSearchFocus,
                  onChanged: (value) => setState(() => appQuery = value),
                ),
              ),
            Expanded(
              child: ListView(
                // No room is needed for the ad banner while it is hidden for the keyboard.
                padding: EdgeInsets.only(bottom: _searchingApps ? 16 : adBannerSpace),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (!compact) ...[
                    _scheduleOnNowBanner(kid),
                    _tabActionButton(),
                    _ruleEntryTiles(kid),
                    verticalSpace(10),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child:
                        boldText(filtering ? 'All Apps · ${shown.length} of ${apps.length}' : 'All Apps', fontSize: 18),
                  ),
                  if (filtering && shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: regularText('No apps match "${appQuery.trim()}"', color: AppColors.grey, fontSize: 14),
                      ),
                    ),
                  // Rebuilt when the schedules and places load, to show which apps they block now.
                  GetBuilder<BlockRulesController>(builder: (rules) {
                    final ruleBlocks = ruleBlocksNow(rules, kid, widget.kidId, childNow(kid));
                    return Column(children: [
                      for (final app in shown)
                        appItem(app,
                            kidId: widget.kidId,
                            blocked: kid.blockedPackages.contains(app.packageName),
                            ruleBlock: ruleBlocks[app.packageName],
                            uninstalling: kid.pendingUninstalls.contains(app.packageName)),
                    ]);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "Block by schedule" and "Block by location", each with a short status, opening their lists.
  Widget _ruleEntryTiles(Kid kid) {
    return GetBuilder<BlockRulesController>(
        initState: (_) => Get.find<BlockRulesController>().loadFromMdm(widget.kidId),
        builder: (rules) {
      final schedules = rules.schedulesFor(widget.kidId);
      final places = rules.placesFor(widget.kidId);
      final onNow = rules.schedulesOnAt(widget.kidId, childNow(kid)).length;
      String count(int n, String one) => n == 0 ? "None yet" : "$n $one${n == 1 ? "" : "s"}";
      return Column(
        children: [
          _ruleEntryTile(
            Icons.schedule,
            "Block by schedule",
            "${count(schedules.length, "schedule")}${onNow > 0 ? " · $onNow on now" : ""}",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulesScreen(kidId: widget.kidId))),
          ),
          _ruleEntryTile(
            Icons.location_on_outlined,
            "Block by location",
            count(places.length, "place"),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlacesScreen(kidId: widget.kidId))),
          ),
        ],
      );
    });
  }

  Widget _ruleEntryTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return customGestureDetecter(
      onTap: onTap,
      child: roundedContainer(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        color: AppColors.lightGrey,
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.normalGreen),
            horizontalSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  regularText(title, fontSize: 14, fontWeight: FontWeight.w700),
                  regularText(subtitle, fontSize: 12, color: AppColors.grey),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  // "School hours is on · until 3:00 PM", while a schedule is running; nothing otherwise.
  Widget _scheduleOnNowBanner(Kid kid) {
    return GetBuilder<BlockRulesController>(builder: (rules) {
      final on = rules.schedulesOnAt(widget.kidId, childNow(kid));
      if (on.isEmpty) return const SizedBox.shrink();
      // A schedule the phone follows comes first; one it can't follow yet says so.
      final s = on.firstWhere((s) => rules.notAppliedReason(widget.kidId, s.id) == null, orElse: () => on.first);
      final active = rules.notAppliedReason(widget.kidId, s.id) == null;
      final apps = s.allApps ? "All apps except Phone and Messages" : "${s.packages.length} ${s.packages.length == 1 ? "app" : "apps"}";
      return customGestureDetecter(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulesScreen(kidId: widget.kidId))),
        child: roundedContainer(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          color: AppColors.veryVeryLightGreen,
          borderRadius: 16,
          child: Row(
            children: [
              iconBadge(Icons.schedule, size: 38, color: AppColors.white, background: AppColors.normalGreen),
              horizontalSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    boldText("${s.name.isEmpty ? "A schedule" : s.name} is on", fontSize: 14),
                    regularText(
                        active
                            ? "$apps blocked until ${formatTime(s.to)}"
                            : "$apps until ${formatTime(s.to)} · not on ${childFirstName(kid)}'s phone\u00A0yet",
                        fontSize: 12, color: AppColors.grey),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: AppColors.grey),
            ],
          ),
        ),
      );
    });
  }

  // The MDM's icon for the app, or a generic one while it loads, when it fails, or when there is none.
  Widget _appIcon(String? url) {
    final placeholder = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.apps, size: 20, color: AppColors.grey),
    );
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
      ),
    );
  }

  Widget appItem(App listOfInstalledApp,
      {required String kidId, required bool blocked, String? ruleBlock, bool uninstalling = false}) {
    String appName = listOfInstalledApp.appName ?? "Unknown App";
    final pkg = listOfInstalledApp.packageName ?? "";
    final systemApp = HomeController.isSystemApp(listOfInstalledApp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 10),
          _appIcon(listOfInstalledApp.iconUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText(appName,
                    fontSize: 14, color: blocked || ruleBlock != null ? AppColors.red : Colors.black),
                regularText(
                    uninstalling
                        ? "Uninstall pending…"
                        : !blocked && ruleBlock != null
                            ? ruleBlock
                            : "${systemApp ? "System app" : "Installed app"}${blocked ? " · Disabled" : ""}",
                    color: uninstalling
                        ? AppColors.normalGreen
                        : !blocked && ruleBlock != null
                            ? AppColors.lightRed
                            : AppColors.grey,
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
                  Get.find<HomeController>().setAppBlocked(kidId: kidId, appPackage: pkg, blocked: !blocked);
                }
              },
              itemBuilder: (context) => [
                // System apps cannot be uninstalled; they can only be disabled.
                if ((listOfInstalledApp.removable ?? !systemApp) && !uninstalling)
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
                        regularText("Uninstall App", color: AppColors.red, fontSize: 13)
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
        content: regularText("$appName will be removed from the child's device as soon as it is online.", fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: regularText("Cancel", fontSize: 14)),
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
    final sites = history?.visitedSites ?? [];
    final hidden = history?.hiddenLookups ?? 0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          padding: const EdgeInsets.only(bottom: adBannerSpace),
          children: [
            _tabActionButton(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16).copyWith(bottom: 15, top: 0),
              child: boldText('Websites (last 7 days)', fontSize: 18),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: regularText("Websites can take up to 2 hours to appear here.",
                        color: AppColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (history?.gapWarning != null)
              roundedContainer(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                color: AppColors.yellow.withValues(alpha: 0.12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.black),
                    const SizedBox(width: 8),
                    Expanded(child: regularText(history!.gapWarning!, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            if (history == null)
              subHeadingText("Loading browser history...")
            else if (sites.isEmpty)
              subHeadingText("No websites visited in the last 7 days.")
            else
              for (final site in sites)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            boldText(site.domain, fontSize: 14),
                            regularText(
                                [
                                  if (site.appName != null) site.appName!,
                                  if (site.lastVisit != null) _visitTime(site.lastVisit!),
                                ].join(" · "),
                                color: AppColors.grey,
                                fontSize: 11),
                          ],
                        ),
                      ),
                      if (site.visits > 1) regularText("${site.visits}×", color: AppColors.grey, fontSize: 12),
                    ],
                  ),
                ),
            if (history != null && hidden > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                child: regularText("$hidden background lookups by the phone's system apps and Moolah are hidden.",
                    color: AppColors.grey, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  static String _visitTime(DateTime time) =>
      "${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  Widget actionButton(IconData icon, String text, VoidCallback onTap, {bool locked = false, bool danger = false}) {
    final color = danger && !locked ? AppColors.red : AppColors.black;
    return Expanded(
      child: customGestureDetecter(
        onTap: onTap,
        child: roundedContainer(
          padding: const EdgeInsets.symmetric(vertical: 14),
          borderRadius: 16,
          color: AppColors.white,
          border: Border.all(color: AppColors.buttonBorderGrey),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(locked ? Icons.lock_outline : icon, size: 19, color: locked ? AppColors.grey : color),
              horizontalSpace(8),
              regularText(text, fontSize: 14, fontWeight: FontWeight.w600, color: locked ? AppColors.grey : color),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUnpair() {
    final kid = Get.find<HomeController>().getSelectedKid(widget.kidId);
    final name = kid.name?.split(" ").first ?? "your child";
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: boldText("Unpair $name's device?", fontSize: 18),
        content: regularText(
            "It will be removed from your account, and you won't be able to see or manage it here. "
            "To add it again, connect it with a new code from the device.",
            fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: regularText("Cancel", fontSize: 14)),
          TextButton(
              onPressed: () async {
                Navigator.pop(dialog);
                final unpaired = await Get.find<HomeController>().unpairDevice(kidId: widget.kidId);
                // The device is gone from the list, so go back to Home.
                if (unpaired && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: regularText("Unpair", color: AppColors.red, fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmReboot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: boldText("Reboot device?", fontSize: 18),
        content: regularText("The child's device will restart as soon as it is online.", fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: regularText("Cancel", fontSize: 14)),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Get.find<HomeController>().sendDeviceAction(
                    kidId: widget.kidId, action: "reboot", successMessage: "Reboot sent to the device");
              },
              child: regularText("Reboot", color: AppColors.red, fontSize: 14)),
        ],
      ),
    );
  }

  Widget messagesSection(HomeController homeController) => _comingSoonTab(
        icon: Icons.chat_bubble_outline,
        text: "Messages monitoring is coming soon. We'll let you know when it's ready.",
      );

  Widget callsSection(HomeController homeController) {
    final name = homeController.getSelectedKid(widget.kidId).name?.split(" ").first ?? "your child";
    return _comingSoonTab(
      icon: Icons.call_outlined,
      text: "See who $name calls and who calls $name, with the time and length of each call.",
      showContacts: true,
    );
  }

  /// A tab whose feature isn't ready: what it will show, then the emergency-contacts limit to come, which
  /// covers both calls and messages. Its switch is shown but can't be turned on yet.
  Widget _comingSoonTab({required IconData icon, required String text, bool showContacts = false}) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 24, 10, adBannerSpace),
        children: [
          Center(child: iconBadge(icon, size: 72)),
          verticalSpace(14),
          Center(child: bigSubHeading("Coming soon")),
          verticalSpace(8),
          subHeadingText(text, textAlign: TextAlign.center, height: 1.45),
          verticalSpace(22),
          roundedContainer(
            borderRadius: 20,
            border: Border.all(color: AppColors.buttonBorderGrey),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconBadge(Icons.verified_user_outlined, size: 40),
                    horizontalSpace(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          boldText("Emergency contacts only", fontSize: 16),
                          verticalSpace(4),
                          roundedContainer(
                            borderRadius: 20,
                            color: AppColors.veryVeryLightGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: regularText("Coming soon",
                                fontSize: 11, color: AppColors.normalGreen, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // Shown so parents know it's coming; it can't be switched on yet.
                    const Switch(value: false, onChanged: null),
                  ],
                ),
                verticalSpace(10),
                regularText("Limit communication to only emergency contacts through calls and messages when enabled.",
                    fontSize: 14, height: 1.45),
              ],
            ),
          ),
          if (showContacts) ...[
            verticalSpace(20),
            boldText("Emergency contacts", fontSize: 15),
            verticalSpace(10),
            roundedContainer(
              borderRadius: 16,
              color: AppColors.lightGrey,
              border: Border.all(color: AppColors.darkLightGrey),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.grey),
                  horizontalSpace(8),
                  regularText("Add emergency contact", fontSize: 15, color: AppColors.grey, fontWeight: FontWeight.w600),
                ],
              ),
            ),
            verticalSpace(10),
            regularText("Calls and messages to these people will always go through, even when everything else is limited.",
                fontSize: 13, color: AppColors.grey, height: 1.45),
          ],
        ],
      ),
    );
  }

  /// Battery or data on the summary's gradient card. A figure the plan doesn't include shows a lock and
  /// opens the upgrade prompt when tapped.
  Widget _heroStat(IconData icon, String label, String value, String unit, Feature feature) {
    final locked = !planAllows(feature);
    return Expanded(
      child: customGestureDetecter(
        onTap: locked ? () => withFeature(feature, label, () {}) : null,
        child: glassTile(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  horizontalSpace(6),
                  Expanded(
                    child: regularText(label, fontSize: 12, color: AppColors.white.withValues(alpha: 0.9)),
                  ),
                  if (locked) const Icon(Icons.lock_outline, size: 16, color: Colors.white),
                ],
              ),
              verticalSpace(8),
              if (locked)
                regularText("Upgrade to see", fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    boldText(value, fontSize: 24, color: AppColors.white),
                    horizontalSpace(3),
                    regularText(unit, fontSize: 13, color: AppColors.white.withValues(alpha: 0.85)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget headingWidget(HomeController homeController) {
    Kid kid = homeController.getSelectedKid(widget.kidId);
    final stats = kid.deviceDetail?.data?.realTimeStats;

    final walletOn = kid.walletEnabled ?? false;
    return Column(
      children: [
        gradientCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.35)),
                    child: ClipOval(
                      child: ColoredBox(
                        color: AppColors.white,
                        child: kid.kidPic == null
                            ? SvgPicture.asset(AppImages.person)
                            : Image.network(kid.kidPic!,
                                fit: BoxFit.cover, errorBuilder: (c, e, v) => SvgPicture.asset(AppImages.person)),
                      ),
                    ),
                  ),
                  horizontalSpace(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        boldText(kid.name ?? "",
                            fontSize: 20, color: AppColors.white, maxLines: 1, textOverflow: TextOverflow.ellipsis),
                        verticalSpace(4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: AppColors.white.withValues(alpha: 0.9)),
                            horizontalSpace(5),
                            Flexible(
                              child: regularText("Active ${kid.lastActive ?? "N/A"}",
                                  fontSize: 12,
                                  color: AppColors.white.withValues(alpha: 0.9),
                                  maxLines: 1,
                                  textOverflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              verticalSpace(16),
              Row(
                children: [
                  _heroStat(Icons.battery_charging_full_rounded, "Battery", stats?.batteryLevel?.toString() ?? "0", "%",
                      Feature.battery),
                  horizontalSpace(10),
                  _heroStat(
                      Icons.public,
                      "Data used",
                      kid.networkHistory?.dataUsageGb ?? stats?.deviceDataUsage?.toString() ?? "0",
                      "GB",
                      Feature.appUsage),
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
                child: glassTile(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: Colors.white),
                      horizontalSpace(10),
                      Expanded(
                        child: regularText("View last location",
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        verticalSpace(12),
        // M! wallet: the info button explains it, the switch turns it on or off.
        roundedContainer(
          borderRadius: 18,
          shadow: softShadow,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              regularText("M!",
                  customFontFamily: fontFamilyPraise,
                  fontSize: 20,
                  color: walletOn ? AppColors.normalGreen : AppColors.grey),
              horizontalSpace(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    regularText("M! Wallet", fontSize: 14, fontWeight: FontWeight.w600),
                    regularText(walletOn ? "Wallet Enabled" : "Wallet Disabled",
                        color: walletOn ? AppColors.normalGreen : AppColors.grey, fontSize: 12),
                  ],
                ),
              ),
              customGestureDetecter(
                  onTap: () {
                    withFeature(Feature.wallet, "The M! wallet", _showAdDialog);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset(AppImages.information),
                  )),
              horizontalSpace(8),
              customSwitch(value: walletOn),
            ],
          ),
        ),
        verticalSpace(12),
        Row(
          children: [
            actionButton(Icons.sync, "Sync now", () {
              withFeature(Feature.deviceActions, "Sync now", () {
                Get.find<HomeController>().sendDeviceAction(
                    kidId: widget.kidId, action: "configUpdated", successMessage: "Sync sent to the device");
              });
            }, locked: !planAllows(Feature.deviceActions)),
            horizontalSpace(10),
            actionButton(
                Icons.restart_alt, "Reboot", () => withFeature(Feature.deviceActions, "Reboot", _confirmReboot),
                locked: !planAllows(Feature.deviceActions)),
          ],
        ),
        verticalSpace(10),
        // Any plan can unpair: it only removes the device from this account.
        Row(children: [actionButton(Icons.link_off, "Unpair device", _confirmUnpair, danger: true)]),
      ],
    );
  }

  Widget tabBar() {
    return roundedContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      color: AppColors.veryVeryLightGreen,
      child: Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(surfaceContainerHighest: Colors.transparent)),
        child: TabBar(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.normalGreen, boxShadow: [
              BoxShadow(color: AppColors.normalGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
            ]),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            dividerColor: Colors.transparent,
            onTap: (v) {
              setState(() {});
            },
            controller: tabController,
            tabs: [
              textForTab("Apps", tabController!.index == 0),
              // Four tabs fit a phone only with "History" for browser history.
              textForTab("History", tabController!.index == 1),
              textForTab("Messages", tabController!.index == 2),
              textForTab("Calls", tabController!.index == 3),
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
          Get.find<HomeController>().enableWallet(value: switchButton, kidId: widget.kidId);
        });
      },
      child: Stack(
        alignment: switchButton ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          roundedContainer(
              borderRadius: 30,
              color: switchButton ? AppColors.lightGreen : AppColors.darkLightGrey,
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
                    color: switchButton ? AppColors.lightGreen : AppColors.darkLightGrey,
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
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
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
                          bigHeadingText("M!", customFontFamily: fontFamilyPraise),
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
                          value: Get.find<HomeController>().getSelectedKid(widget.kidId).walletEnabled ?? false),
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

/// Keeps the tab bar pinned under the screen title while the summary card scrolls away.
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  _PinnedTabBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  // The tab bar's labels and selection change with the screen's state, so always rebuild it.
  @override
  bool shouldRebuild(covariant _PinnedTabBar oldDelegate) => true;
}
