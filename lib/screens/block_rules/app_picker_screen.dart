import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/app_search_field.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// Lets the parent tick the apps a schedule or place blocks. Pops with the chosen package names.
class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({required this.kidId, required this.selected, super.key});
  final String kidId;
  final List<String> selected;

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final search = TextEditingController();
  String query = "";
  late final Set<String> picked = {...widget.selected};

  @override
  void initState() {
    super.initState();
    final home = Get.find<HomeController>();
    if (home.getSelectedKid(widget.kidId).installedApps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => home.getInstalledApps(kidId: widget.kidId));
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (home) {
      final kid = home.getSelectedKid(widget.kidId);
      // Only apps the child can open, and never the ones that keep the phone managed.
      final apps = kid.installedApps
          .where((a) => HomeController.isUserApp(a) && !HomeController.isProtectedApp(a.packageName))
          .toList();
      final listed = apps.map((a) => a.packageName).toSet();
      for (final pkg in picked) {
        if (!listed.contains(pkg)) apps.add(appFor(kid, pkg));
      }
      apps.sort((a, b) => (a.appName ?? "").toLowerCase().compareTo((b.appName ?? "").toLowerCase()));
      final shown = apps.where((a) => appMatchesQuery(a, query)).toList();
      final name = childFirstName(kid);

      return CommonGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              commonAppBar(heading: "Choose apps", onTap: () => Navigator.pop(context)),
              verticalSpace(12),
              Expanded(
                child: pageSheet(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      regularText("Only apps $name can open are listed. Phone, Messages and Moolah apps can't be blocked.",
                          fontSize: 14, color: AppColors.grey, height: 1.45),
                      verticalSpace(14),
                      AppSearchField(controller: search, onChanged: (value) => setState(() => query = value)),
                      verticalSpace(10),
                      Expanded(
                        child: home.isLoading && apps.isEmpty
                            ? Center(child: CircularProgressIndicator(color: AppColors.normalGreen))
                            : shown.isEmpty
                                ? Center(
                                    child: regularText(
                                        apps.isEmpty ? "No apps found on this device" : 'No apps match "${query.trim()}"',
                                        color: AppColors.grey,
                                        fontSize: 14))
                                : ListView.separated(
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    itemCount: shown.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.greyF0F0),
                                    itemBuilder: (_, i) => _appRow(shown[i]),
                                  ),
                      ),
                      verticalSpace(12),
                      primaryButton(
                        picked.isEmpty ? "Done" : "Done · ${picked.length} ${picked.length == 1 ? "app" : "apps"}",
                        onTap: () => Navigator.pop(context, picked.toList()),
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

  Widget _appRow(App app) {
    final pkg = app.packageName ?? "";
    final on = picked.contains(pkg);
    return CheckboxListTile(
      value: on,
      onChanged: pkg.isEmpty ? null : (value) => setState(() => value == true ? picked.add(pkg) : picked.remove(pkg)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      activeColor: AppColors.normalGreen,
      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      secondary: ruleAppIcon(app),
      title: boldText(app.appName ?? pkg, fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
