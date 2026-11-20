import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/screens/block_rules/schedule_edit_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// The device's schedules: when apps are turned off, each with an on/off switch.
class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({required this.kidId, super.key});
  final String kidId;

  void _open(BuildContext context, [BlockSchedule? schedule]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleEditScreen(kidId: kidId, schedule: schedule)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BlockRulesController>(
        initState: (_) => Get.find<BlockRulesController>().loadFromMdm(kidId),
        builder: (rules) {
          final kid = Get.find<HomeController>().getSelectedKid(kidId);
          final name = childFirstName(kid);
          final schedules = rules.schedulesFor(kidId);
          final now = childNow(kid);
          final clockNote = childClockNote(kid);

          return ruleScreen(context, title: "Block by schedule", children: [
            regularText("Turn apps off on $name's phone at set times. Phone calls and Moolah apps always stay on.",
                fontSize: 14, color: AppColors.grey, height: 1.45),
            verticalSpace(16),
            if (clockNote != null) ...[infoNote(clockNote), verticalSpace(12)],
            if (schedules.isEmpty)
              roundedContainer(
                color: AppColors.lightGrey,
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    iconBadge(Icons.schedule, size: 52),
                    verticalSpace(12),
                    boldText("No schedules yet", fontSize: 16),
                    verticalSpace(4),
                    regularText("Add one for school hours, homework or bedtime.",
                        fontSize: 14, color: AppColors.grey, textAlign: TextAlign.center),
                  ],
                ),
              ),
            for (final s in schedules) _scheduleCard(context, rules, kid, s, name, now),
            verticalSpace(4),
            primaryButton("Add schedule", icon: Icons.add, onTap: () => _open(context)),
            verticalSpace(16),
            infoNote("Sent to $name's phone when you save. It keeps following them offline and after a restart."),
          ]);
        });
  }

  Widget _scheduleCard(
      BuildContext context, BlockRulesController rules, Kid kid, BlockSchedule s, String name, DateTime now) {
    final notActive = rules.notAppliedReason(kidId, s.id);
    final count = "${s.packages.length} ${s.packages.length == 1 ? "app" : "apps"}";
    return ruleCard(
      onTap: () => _open(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        boldText(s.name.isEmpty ? "Schedule" : s.name, fontSize: 17),
                        if (s.isOnAt(now))
                          pill(
                            color: AppColors.normalGreen,
                            child: boldText("On now", fontSize: 11, color: AppColors.white),
                          ),
                      ],
                    ),
                    verticalSpace(3),
                    regularText(s.whenText, fontSize: 14, color: AppColors.grey),
                  ],
                ),
              ),
              ruleSwitch(
                  value: s.enabled,
                  onChanged: (v) async {
                    final error = await rules.setScheduleEnabled(kidId, s.id, v);
                    if (error != null) errorToast(error);
                  }),
            ],
          ),
          verticalSpace(10),
          Row(
            children: [
              if (!s.allApps) ...[appIconStack(kid, s.packages), horizontalSpace(10)],
              Expanded(
                child: regularText(
                    s.allApps
                        ? "All apps except Phone and Messages"
                        : notActive == null && s.enabled
                            ? "$count blocked"
                            : count,
                    fontSize: 14),
              ),
            ],
          ),
          if (notActive != null) ...[verticalSpace(10), notActiveLine(notActiveText(notActive, name))],
        ],
      ),
    );
  }
}
