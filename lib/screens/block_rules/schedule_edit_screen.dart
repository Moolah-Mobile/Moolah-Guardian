import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/screens/block_rules/app_picker_screen.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// Adds a schedule, or edits [schedule] when given.
class ScheduleEditScreen extends StatefulWidget {
  const ScheduleEditScreen({required this.kidId, this.schedule, super.key});
  final String kidId;
  final BlockSchedule? schedule;

  @override
  State<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends State<ScheduleEditScreen> {
  late final BlockSchedule draft =
      widget.schedule?.copy() ?? BlockSchedule(id: BlockRulesController.newId("sched"), name: "");
  late final name = TextEditingController(text: draft.name);

  bool get _isNew => widget.schedule == null;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  // What stops the schedule from being saved, or null when it can be.
  String? get _problem {
    if (name.text.trim().isEmpty) return "Give the schedule a name.";
    if (draft.days.isEmpty) return "Pick at least one day.";
    if (draft.from == draft.to) return "The start and end times are the same.";
    if (!draft.allApps && draft.packages.isEmpty) return "Choose at least one app.";
    return null;
  }

  Future<void> _chooseApps() async {
    final picked = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => AppPickerScreen(kidId: widget.kidId, selected: draft.packages)),
    );
    if (picked != null) setState(() => draft.packages = picked);
  }

  // Sent to the child's phone first; the screen closes only once the MDM has it.
  bool _saving = false;

  Future<void> _run(Future<String?> Function(BlockRulesController rules) change) async {
    setState(() => _saving = true);
    final error = await change(Get.find<BlockRulesController>());
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return errorToast(error);
    Navigator.pop(context);
  }

  void _save() {
    draft.name = name.text.trim();
    _run((rules) => rules.saveSchedule(widget.kidId, draft));
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: boldText("Delete ${draft.name.isEmpty ? "this schedule" : draft.name}?", fontSize: 18),
        content: regularText("Apps it blocks will stay on at these times.", fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: regularText("Cancel", fontSize: 14)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialog);
              _run((rules) => rules.deleteSchedule(widget.kidId, draft.id));
            },
            child: regularText("Delete", color: AppColors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _summary(Kid kid) {
    final what = draft.allApps
        ? "All apps except Phone, Messages and Moolah apps will be blocked"
        : draft.packages.isEmpty
            ? "Choose the apps to block"
            : "${appListText(kid, draft.packages)} will be blocked";
    if (draft.packages.isEmpty && !draft.allApps) return "$what.";
    final days = describeDays(draft.days);
    final overnight = draft.to < draft.from ? " (overnight)" : "";
    return "$what ${days == "Every day" ? "every day" : days == "Weekends" ? "at weekends" : "on $days"} "
        "from ${formatTime(draft.from)} to ${formatTime(draft.to)}$overnight.";
  }

  @override
  Widget build(BuildContext context) {
    final kid = Get.find<HomeController>().getSelectedKid(widget.kidId);
    final problem = _problem;

    return ruleScreen(context, title: _isNew ? "New schedule" : "Edit schedule", children: [
      fieldLabel("Name"),
      TextField(
        controller: name,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontFamily: fontFamily, fontSize: 16),
        decoration: InputDecoration(
          hintText: "e.g. School hours",
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.darkLightGrey)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.darkLightGrey)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.normalGreen, width: 2)),
        ),
      ),
      verticalSpace(18),
      fieldLabel("Days"),
      dayPicker(days: draft.days, onChanged: (d) => setState(() => draft.days = d)),
      verticalSpace(18),
      Row(
        children: [
          Expanded(
              child: timeField(context,
                  label: "From", minutes: draft.from, onChanged: (m) => setState(() => draft.from = m))),
          horizontalSpace(10),
          Expanded(
              child: timeField(context,
                  label: "Until", minutes: draft.to, onChanged: (m) => setState(() => draft.to = m))),
        ],
      ),
      if (childClockNote(kid) case final note?) ...[verticalSpace(12), infoNote(note)],
      verticalSpace(18),
      fieldLabel("What to block"),
      segmentedChoice(
        options: const ["Chosen apps", "All apps"],
        selected: draft.allApps ? 1 : 0,
        onChanged: (i) => setState(() => draft.allApps = i == 1),
      ),
      verticalSpace(12),
      if (draft.allApps)
        infoNote("Every app is turned off except Phone, Messages and Moolah apps. Children's phones can't "
            "follow this yet: the schedule is saved and starts once they can.")
      else
        _chosenApps(kid),
      verticalSpace(16),
      summaryNote(_summary(kid)),
      verticalSpace(16),
      if (problem != null) ...[
        regularText(problem, fontSize: 13, color: AppColors.grey),
        verticalSpace(8),
      ],
      primaryButton(_saving ? "Saving…" : "Save schedule", onTap: problem == null && !_saving ? _save : null),
      if (!_isNew) ...[
        verticalSpace(8),
        Center(
          child: TextButton(
            onPressed: _saving ? null : _delete,
            child: regularText("Delete schedule", color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ]);
  }

  Widget _chosenApps(Kid kid) {
    return roundedContainer(
      borderRadius: 20,
      border: Border.all(color: AppColors.buttonBorderGrey),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (final pkg in draft.packages)
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  ruleAppIcon(appFor(kid, pkg)),
                  horizontalSpace(12),
                  Expanded(child: boldText(appFor(kid, pkg).appName ?? pkg, fontSize: 15, fontWeight: FontWeight.w600)),
                  IconButton(
                    tooltip: "Remove ${appFor(kid, pkg).appName ?? pkg}",
                    onPressed: () => setState(() => draft.packages = [...draft.packages]..remove(pkg)),
                    icon: Icon(Icons.close, size: 20, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          if (draft.packages.isNotEmpty) Divider(height: 1, color: AppColors.greyF0F0),
          InkWell(
            onTap: _chooseApps,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Icon(Icons.add, size: 22, color: AppColors.normalGreen),
                  horizontalSpace(10),
                  boldText("Choose apps", fontSize: 15, color: AppColors.normalGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
