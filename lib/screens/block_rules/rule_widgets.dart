import 'package:flutter/material.dart';
import 'package:moolah/controllers/advertisementController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// Pieces shared by the schedule and place screens.

/// A screen with the app bar, the white sheet and a scrolling list, like Blocked Apps.
Widget ruleScreen(BuildContext context, {required String title, required List<Widget> children}) {
  return CommonGradientBackground(
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          commonAppBar(heading: title, onTap: () => Navigator.pop(context)),
          verticalSpace(12),
          Expanded(
            child: pageSheet(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, adBannerSpace),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: children,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String childFirstName(Kid kid) {
  final name = kid.name?.trim() ?? "";
  return name.isEmpty ? "your child" : name.split(" ").first;
}

/// The app named [pkg] on [kid]'s phone, or a stand-in with whatever name Guardian knows.
App appFor(Kid kid, String pkg) {
  for (final app in kid.installedApps) {
    if (app.packageName == pkg) return app;
  }
  return App(pkg: pkg, name: kid.appNames[pkg] ?? pkg);
}

/// "TikTok Lite, Block Blast! and 2 more".
String appListText(Kid kid, List<String> packages) {
  final names = packages.map((p) => appFor(kid, p).appName ?? p).toList();
  if (names.isEmpty) return "No apps chosen";
  if (names.length == 1) return names.first;
  if (names.length == 2) return "${names[0]} and ${names[1]}";
  if (names.length == 3) return "${names[0]}, ${names[1]} and ${names[2]}";
  return "${names[0]}, ${names[1]} and ${names.length - 2} more";
}

/// The MDM's icon for [app], or a generic one while it loads, when it fails, or when there is none.
Widget ruleAppIcon(App app, {double size = 36}) {
  final placeholder = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(size * 0.25)),
    child: Icon(Icons.apps, size: size * 0.55, color: AppColors.grey),
  );
  final url = app.iconUrl;
  if (url == null || url.isEmpty) return placeholder;
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.25),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    ),
  );
}

/// Up to four overlapping app icons, for a rule's card.
Widget appIconStack(Kid kid, List<String> packages) {
  final shown = packages.take(4).toList();
  return SizedBox(
    height: 30,
    width: shown.isEmpty ? 0 : 30.0 + (shown.length - 1) * 22,
    child: Stack(
      children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: i * 22.0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.white, width: 2)),
              child: ruleAppIcon(appFor(kid, shown[i]), size: 26),
            ),
          ),
      ],
    ),
  );
}

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: boldText(text, fontSize: 14),
    );

/// A grey note with an info icon.
Widget infoNote(String text) {
  return roundedContainer(
    color: AppColors.lightGrey,
    borderRadius: 16,
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 20, color: AppColors.grey),
        horizontalSpace(10),
        Expanded(child: regularText(text, fontSize: 13, color: AppColors.grey, height: 1.45)),
      ],
    ),
  );
}

/// A plain-language summary of what the rule will do.
Widget summaryNote(String text) {
  return roundedContainer(
    color: AppColors.veryVeryLightGreen,
    borderRadius: 16,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: regularText(text, fontSize: 14, height: 1.5, color: AppColors.black),
  );
}

/// Two or more options in a green track; the chosen one is filled.
Widget segmentedChoice({required List<String> options, required int selected, required ValueChanged<int> onChanged}) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.veryVeryLightGreen, borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.normalGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: regularText(options[i],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? AppColors.white : AppColors.normalGreen),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Seven day buttons (Monday first) plus Weekdays / Weekend / Every day shortcuts.
Widget dayPicker({required Set<int> days, required ValueChanged<Set<int>> onChanged}) {
  const letters = ["M", "T", "W", "T", "F", "S", "S"];
  const names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  Widget shortcut(String label, Set<int> value) => GestureDetector(
        onTap: () => onChanged({...value}),
        // No alignment here: a Container with one fills the whole row width inside a Wrap.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.darkLightGrey),
            color: AppColors.white,
          ),
          child: regularText(label, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (var d = 1; d <= 7; d++) ...[
            if (d > 1) horizontalSpace(6),
            Expanded(
              child: Semantics(
                label: names[d - 1],
                button: true,
                selected: days.contains(d),
                child: GestureDetector(
                  onTap: () {
                    final next = {...days};
                    next.contains(d) ? next.remove(d) : next.add(d);
                    onChanged(next);
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: days.contains(d) ? AppColors.normalGreen : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: days.contains(d) ? AppColors.normalGreen : AppColors.darkLightGrey),
                    ),
                    child: boldText(letters[d - 1],
                        fontSize: 14, color: days.contains(d) ? AppColors.white : AppColors.black),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      verticalSpace(10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          shortcut("Weekdays", weekdays),
          shortcut("Weekend", weekend),
          shortcut("Every day", everyDay),
        ],
      ),
    ],
  );
}

/// A time box that opens the clock picker; [minutes] is minutes after midnight.
Widget timeField(BuildContext context,
    {required String label, required int minutes, required ValueChanged<int> onChanged}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      fieldLabel(label),
      GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
            helpText: label,
            // Always AM/PM, whatever the phone's 24-hour setting.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: Theme(
                data: Theme.of(context).copyWith(
                  timePickerTheme: Theme.of(context).timePickerTheme.copyWith(
                        dayPeriodColor: WidgetStateColor.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AppColors.normalGreen : AppColors.white),
                        dayPeriodTextColor: WidgetStateColor.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.normalGreen),
                        dayPeriodBorderSide: BorderSide(color: AppColors.normalGreen),
                      ),
                ),
                child: child!,
              ),
            ),
          );
          if (picked != null) onChanged(picked.hour * 60 + picked.minute);
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkLightGrey),
          ),
          child: Row(
            children: [
              Expanded(child: boldText(formatTime(minutes), fontSize: 17)),
              Icon(Icons.schedule, size: 20, color: AppColors.grey),
            ],
          ),
        ),
      ),
    ],
  );
}

/// The on/off switch on a rule's card.
Widget ruleSwitch({required bool value, required ValueChanged<bool> onChanged}) {
  return Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.white,
    activeTrackColor: AppColors.normalGreen,
    inactiveThumbColor: AppColors.white,
    inactiveTrackColor: AppColors.darkLightGrey,
  );
}

/// A white bordered card for a rule in a list.
Widget ruleCard({required Widget child, VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.buttonBorderGrey),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// A full-width dark button, as the rest of the app uses for the main action.
Widget primaryButton(String text, {required VoidCallback? onTap, IconData? icon}) {
  return SizedBox(
    height: 56,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        disabledBackgroundColor: AppColors.darkLightGrey,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), horizontalSpace(8)],
          boldText(text, fontSize: 17, color: AppColors.white),
        ],
      ),
    ),
  );
}

/// The banner that says these rules aren't sent to the phone yet.
Widget notOnPhoneYetNote(String childName) => infoNote(
    "Saved in Guardian on this phone. $childName's phone starts following these rules once Moolah Connect "
    "supports them.");
