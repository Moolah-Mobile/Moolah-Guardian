import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart' show childNow, ruleBlocksNow;
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/app_search_field.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/common_widgets/loader.dart';

class BlackListScreen extends StatefulWidget {
  const BlackListScreen({required this.kidId, Key? key}) : super(key: key);
  final String kidId;

  @override
  State<BlackListScreen> createState() => _BlackListScreenState();
}

class _BlackListScreenState extends State<BlackListScreen> {
  final search = TextEditingController();
  String query = "";

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Get.find<HomeController>().getInstalledApps(kidId: widget.kidId));
  }

  @override
  Widget build(BuildContext context) {
    // Rule blocks come from the schedules and places, so rebuild when either controller changes.
    return GetBuilder<BlockRulesController>(
        initState: (_) => Get.find<BlockRulesController>().loadFromMdm(widget.kidId),
        builder: (rules) => GetBuilder<HomeController>(builder: (homeController) {
              final kid = homeController.getSelectedKid(widget.kidId);
              // Apps a schedule or place is blocking now. Their switch stays off: it means "blocked at all times".
              final ruleBlocks = ruleBlocksNow(rules, kid, widget.kidId, childNow(kid));
              // Only the blocked apps: always blocked, or blocked now by a schedule or place. A blocked app may be
              // missing from the installed-apps report, so it's listed from the rules, with the report's name and
              // icon when it has them.
              final installed = {for (final a in kid.installedApps) a.packageName: a};
              final apps = {...kid.blockedPackages, ...ruleBlocks.keys}
                  .where((pkg) => !HomeController.isMoolahApp(pkg))
                  .map((pkg) => installed[pkg] ?? App(pkg: pkg, name: kid.appNames[pkg] ?? pkg))
                  // Like All Apps, only the child's own apps: no system apps.
                  .where((app) => !HomeController.isSystemApp(app))
                  .toList()
                ..sort((a, b) => (a.appName ?? "").toLowerCase().compareTo((b.appName ?? "").toLowerCase()));
              final shown = apps.where((a) => appMatchesQuery(a, query)).toList();
              final childName = kid.name?.split(" ")[0] ?? "the child";

              return CommonGradientBackground(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      commonAppBar(heading: "Blocked Apps", onTap: () => Navigator.pop(context)),
                      verticalSpace(12),
                      Expanded(
                        child: pageSheet(
                          child: Loader(
                            c: homeController,
                            child: apps.isEmpty
                                ? _emptyState(
                                    homeController.isLoading
                                        ? null
                                        : homeController.findKid(widget.kidId) == null
                                            ? "This device isn't in your device list right now. Go back to Home and open it again."
                                            : "",
                                    childName: childName)
                                : ListView(
                                    padding: EdgeInsets.fromLTRB(16, 20, 16, listEndPadding(context)),
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    children: [
                                      _summary(childName, apps.length),
                                      verticalSpace(16),
                                      // Search only helps once the list is long.
                                      if (apps.length > 8 || query.isNotEmpty) ...[
                                        AppSearchField(
                                          controller: search,
                                          onChanged: (value) => setState(() => query = value),
                                        ),
                                        verticalSpace(12),
                                      ],
                                      if (shown.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24),
                                          child: Center(
                                            child: regularText('No apps match "${query.trim()}"',
                                                color: AppColors.grey, fontSize: 14),
                                          ),
                                        )
                                      else
                                        roundedContainer(
                                          borderRadius: 20,
                                          color: AppColors.greyFAFA,
                                          border: Border.all(color: AppColors.greyF0F0),
                                          child: Column(
                                            children: [
                                              for (int i = 0; i < shown.length; i++) ...[
                                                if (i > 0)
                                                  Divider(
                                                      height: 1, thickness: 1, indent: 64, color: AppColors.greyF0F0),
                                                appItem(shown[i], kid.blockedPackages.contains(shown[i].packageName),
                                                    ruleBlocks[shown[i].packageName]),
                                              ],
                                            ],
                                          ),
                                        ),
                                    ],
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

  /// How many apps are blocked, and what blocking does.
  Widget _summary(String childName, int blocked) {
    return gradientCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText("$blocked ${blocked == 1 ? "app" : "apps"} blocked", fontSize: 20, color: AppColors.white),
                verticalSpace(6),
                regularText("Turned off on $childName's device. Switch an app off to let $childName use it again.",
                    fontSize: 13, color: AppColors.white.withValues(alpha: 0.9), height: 1.4),
              ],
            ),
          ),
          horizontalSpace(12),
          glassTile(
            child:
                Icon(blocked > 0 ? Icons.block_rounded : Icons.verified_user_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  /// [message] explains a problem; with none, it says nothing is blocked and how to block an app. Empty
  /// while loading shows nothing.
  Widget _emptyState(String? message, {required String childName}) {
    if (message == null) return const SizedBox.shrink();
    final nothingBlocked = message.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconBadge(nothingBlocked ? Icons.verified_user_outlined : Icons.apps_rounded, size: 72),
            verticalSpace(14),
            if (nothingBlocked) ...[
              boldText("No apps blocked", fontSize: 17),
              verticalSpace(6),
            ],
            regularText(
                nothingBlocked
                    ? "Every app on $childName's device is on. To block one, tap \u22EE next to it in All Apps "
                        "and choose Disable App, or add a schedule or place."
                    : message,
                color: AppColors.grey,
                textAlign: TextAlign.center,
                height: 1.4),
          ],
        ),
      ),
    );
  }

  Widget _appIcon(String? url, bool blocked) {
    final placeholder = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.apps, size: 20, color: AppColors.grey),
    );
    final icon = (url == null || url.isEmpty)
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
            ),
          );
    // Blocked apps are shown greyed out, as they are on the child's phone.
    return AnimatedOpacity(opacity: blocked ? 0.4 : 1, duration: const Duration(milliseconds: 200), child: icon);
  }

  /// [ruleBlock] says why a schedule or place is blocking the app right now, when one is.
  Widget appItem(App app, bool blocked, [String? ruleBlock]) {
    final off = blocked || ruleBlock != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          _appIcon(app.iconUrl, off),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText(app.appName ?? app.packageName ?? "Unknown App",
                    fontSize: 14, maxLines: 1, textOverflow: TextOverflow.ellipsis),
                verticalSpace(2),
                regularText(blocked ? "Blocked" : ruleBlock ?? (app.packageName ?? ""),
                    color: off ? AppColors.lightRed : AppColors.grey,
                    fontSize: 11,
                    fontWeight: off ? FontWeight.w600 : null,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // A schedule or place lifts its own block when it ends; only an always-on block has a switch.
          if (blocked)
            Switch(
              value: blocked,
              trackColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? AppColors.lightRed : AppColors.darkLightGrey),
              onChanged: app.packageName == null
                  ? null
                  : (value) => Get.find<HomeController>()
                      .setAppBlocked(kidId: widget.kidId, appPackage: app.packageName!, blocked: value),
            ),
        ],
      ),
    );
  }
}
