import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/advertisementController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/app_search_field.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Get.find<HomeController>().getInstalledApps(kidId: widget.kidId));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (homeController) {
      final kid = homeController.getSelectedKid(widget.kidId);
      final apps = kid.installedApps
          .where((a) => !HomeController.isProtectedApp(a.packageName))
          .toList();
      // A blocked app is suspended on the device and drops out of its installed-apps report,
      // so list it from the rules to keep it unblockable.
      final listed = apps.map((a) => a.packageName).toSet();
      for (final pkg in kid.blockedPackages) {
        if (!listed.contains(pkg) && !HomeController.isProtectedApp(pkg)) {
          apps.add(App(pkg: pkg, name: kid.appNames[pkg] ?? pkg));
        }
      }
      apps.sort((a, b) => (a.appName ?? "").toLowerCase().compareTo((b.appName ?? "").toLowerCase()));
      final shown = apps.where((a) => appMatchesQuery(a, query)).toList();
      return Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: Colors.white,
        body: Loader(
          c: homeController,
          child: apps.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: regularText(
                        homeController.isLoading
                            ? ""
                            : homeController.findKid(widget.kidId) == null
                                ? "This device isn't in your device list right now. Go back to Home and open it again."
                                : "No apps found on this device",
                        color: AppColors.grey,
                        textAlign: TextAlign.center),
                  ))
              : ListView(
                  padding: const EdgeInsets.only(top: 10, bottom: adBannerSpace),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: regularText(
                          "Blocked apps are turned off on ${kid.name?.split(" ")[0] ?? "the child"}'s device at all times.",
                          color: AppColors.grey,
                          fontSize: 13),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: AppSearchField(
                        controller: search,
                        onChanged: (value) => setState(() => query = value),
                      ),
                    ),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: regularText('No apps match "${query.trim()}"',
                              color: AppColors.grey, fontSize: 14),
                        ),
                      ),
                    for (final app in shown)
                      appItem(app, kid.blockedPackages.contains(app.packageName)),
                  ],
                ),
        ),
      );
    });
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: boldText('Blocked Apps', fontSize: 18, color: Colors.black),
      centerTitle: true,
      leading: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: SvgPicture.asset('assets/images/home/back.svg'),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget appItem(App app, bool blocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boldText(app.appName ?? app.packageName ?? "Unknown App",
                    fontSize: 14, color: blocked ? AppColors.red : Colors.black),
                regularText(app.packageName ?? "", color: AppColors.grey, fontSize: 11),
              ],
            ),
          ),
          Switch(
            value: blocked,
            activeColor: AppColors.red,
            onChanged: app.packageName == null
                ? null
                : (value) => Get.find<HomeController>().setAppBlocked(
                    kidId: widget.kidId, appPackage: app.packageName!, blocked: value),
          ),
        ],
      ),
    );
  }
}
