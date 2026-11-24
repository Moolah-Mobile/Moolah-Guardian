import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/commsController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/common_widgets/plan_gate.dart';
import 'package:moolah/util/customtoast.dart';

int _contactLimit() =>
    Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>().currentPlan.emergencyContactLimit : 3;

/// The "Emergency contacts only" switch and who's on the list, at the top of the Calls and Messages tabs.
class EmergencyContactsCard extends StatefulWidget {
  const EmergencyContactsCard({required this.kidId, super.key});
  final String kidId;

  @override
  State<EmergencyContactsCard> createState() => _EmergencyContactsCardState();
}

class _EmergencyContactsCardState extends State<EmergencyContactsCard> {
  bool _saving = false;

  Future<void> _setOnly(bool on, EmergencySettings settings, String childName) async {
    if (on && settings.contacts.isEmpty) {
      errorToast("Add at least one emergency contact first.");
      _openList();
      return;
    }
    setState(() => _saving = true);
    final error = await Get.find<CommsController>()
        .saveEmergency(widget.kidId, emergencyOnly: on, contacts: settings.contacts);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return errorToast(error);
    successToast(on ? "Only emergency contacts can reach $childName now" : "Everyone can reach $childName again");
  }

  void _openList() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen(kidId: widget.kidId)));

  @override
  Widget build(BuildContext context) {
    final childName = childFirstName(Get.find<HomeController>().getSelectedKid(widget.kidId));
    return GetBuilder<CommsController>(
      initState: (_) => Get.find<CommsController>().loadEmergency(widget.kidId),
      builder: (comms) {
        final load = comms.emergency(widget.kidId);
        final settings = load.value ?? EmergencySettings();
        final ready = load.value != null;
        return roundedContainer(
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
                  Expanded(child: boldText("Emergency contacts only", fontSize: 16)),
                  if (_saving || (load.loading && !ready))
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    ruleSwitch(
                      value: settings.emergencyOnly,
                      onChanged: ready ? (on) => _setOnly(on, settings, childName) : (_) {},
                    ),
                ],
              ),
              verticalSpace(8),
              regularText(
                  settings.emergencyOnly
                      ? "On: $childName can only call and text the people below, and only they can reach $childName. "
                          "911 always works."
                      : "When on, $childName can only call and text the people below, and only they can reach "
                          "$childName. 911 always works.",
                  fontSize: 14,
                  height: 1.45),
              if (load.unavailable) ...[
                verticalSpace(10),
                notActiveLine("Not available on $childName's phone yet."),
              ] else if (load.error != null && !ready) ...[
                verticalSpace(10),
                notActiveLine(load.error!),
                TextButton(
                  onPressed: () => comms.loadEmergency(widget.kidId, force: true),
                  child: boldText("Try again", fontSize: 14, color: AppColors.normalGreen),
                ),
              ] else if (settings.notApplied != null) ...[
                verticalSpace(10),
                notActiveLine(settings.notApplied!),
              ],
              if (ready) ...[
                verticalSpace(12),
                Divider(height: 1, color: AppColors.darkLightGrey),
                for (final c in settings.contacts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: _initial(c.name),
                    title: boldText(c.name, fontSize: 15),
                    subtitle: regularText(c.number, fontSize: 13, color: AppColors.grey),
                  ),
                verticalSpace(6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openList,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.normalGreen,
                      side: BorderSide(color: AppColors.normalGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(settings.contacts.isEmpty ? Icons.add : Icons.edit_outlined, size: 18),
                    label: boldText(
                        settings.contacts.isEmpty
                            ? "Add emergency contact"
                            : "Manage emergency contacts (${settings.contacts.length} of ${_contactLimit()})",
                        fontSize: 15,
                        color: AppColors.normalGreen),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Widget _initial(String name) => CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.veryVeryLightGreen,
      child: boldText(name.isEmpty ? "?" : name.characters.first.toUpperCase(),
          fontSize: 15, color: AppColors.normalGreen),
    );

/// Everyone on the child's emergency list, with add, edit and remove.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({required this.kidId, super.key});
  final String kidId;

  void _add(BuildContext context, EmergencySettings settings) {
    final limit = _contactLimit();
    if (settings.contacts.length >= limit) {
      final plan = Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>().currentPlan
          : Plan.free;
      if (plan != Plan.ultimate) {
        showUpgradeDialog(Plan.ultimate,
            "Your ${plan.title} plan includes $limit emergency contacts. Adding up to 5 is part of the");
      } else {
        showLimitDialog("You can have up to $limit emergency contacts. Remove one to add someone else.");
      }
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactEditScreen(kidId: kidId)));
  }

  @override
  Widget build(BuildContext context) {
    final childName = childFirstName(Get.find<HomeController>().getSelectedKid(kidId));
    return GetBuilder<CommsController>(
      initState: (_) => Get.find<CommsController>().loadEmergency(kidId),
      builder: (comms) {
        final load = comms.emergency(kidId);
        final settings = load.value ?? EmergencySettings();
        final limit = _contactLimit();
        return ruleScreen(context, title: "Emergency contacts", children: [
          regularText(
              "Calls and texts with these people always go through, even when Emergency contacts only is on. "
              "Add up to $limit.",
              fontSize: 14,
              color: AppColors.grey,
              height: 1.45),
          verticalSpace(16),
          if (load.unavailable)
            infoNote("Emergency contacts aren't available on $childName's phone yet.")
          else if (load.value == null && load.loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (load.value == null && load.error != null)
            infoNote(load.error!)
          else ...[
            for (var i = 0; i < settings.contacts.length; i++)
              ruleCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EmergencyContactEditScreen(kidId: kidId, index: i))),
                child: Row(
                  children: [
                    _initial(settings.contacts[i].name),
                    horizontalSpace(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          boldText(settings.contacts[i].name, fontSize: 16),
                          verticalSpace(2),
                          regularText(settings.contacts[i].number, fontSize: 14, color: AppColors.grey),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.grey),
                  ],
                ),
              ),
            if (settings.contacts.isEmpty) ...[
              infoNote("No emergency contacts yet. Add the people $childName should always be able to reach."),
              verticalSpace(16),
            ],
            primaryButton("Add emergency contact (${settings.contacts.length} of $limit)",
                icon: Icons.add, onTap: () => _add(context, settings)),
            verticalSpace(12),
            infoNote("Add yourself, so $childName can always reach you. 911 always works and isn't needed here."),
          ],
        ]);
      },
    );
  }
}

/// Adds an emergency contact, or edits the one at [index].
class EmergencyContactEditScreen extends StatefulWidget {
  const EmergencyContactEditScreen({required this.kidId, this.index, super.key});
  final String kidId;
  final int? index;

  @override
  State<EmergencyContactEditScreen> createState() => _EmergencyContactEditScreenState();
}

class _EmergencyContactEditScreenState extends State<EmergencyContactEditScreen> {
  late final EmergencySettings _settings =
      Get.find<CommsController>().emergency(widget.kidId).value ?? EmergencySettings();
  late final EmergencyContact? _editing =
      widget.index != null && widget.index! < _settings.contacts.length ? _settings.contacts[widget.index!] : null;
  late final _name = TextEditingController(text: _editing?.name ?? "");
  late final _number = TextEditingController(text: _editing?.number ?? "");
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  String? get _problem {
    if (_name.text.trim().isEmpty) return "Enter a name.";
    if (_name.text.trim().length > maxContactNameLength) return "Use a shorter name.";
    final numberProblem = phoneProblem(_number.text);
    if (numberProblem != null) return numberProblem;
    for (var i = 0; i < _settings.contacts.length; i++) {
      if (i != widget.index && samePhoneNumber(_settings.contacts[i].number, _number.text)) {
        return "${_settings.contacts[i].name} already has this number.";
      }
    }
    return null;
  }

  Future<void> _send(List<EmergencyContact> contacts, String done) async {
    // With nobody left on the list, Emergency contacts only would let no one through.
    final only = _settings.emergencyOnly && contacts.isNotEmpty;
    setState(() => _saving = true);
    final error =
        await Get.find<CommsController>().saveEmergency(widget.kidId, emergencyOnly: only, contacts: contacts);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return errorToast(error);
    successToast(_settings.emergencyOnly && !only ? "$done. Emergency contacts only is off: the list is empty." : done);
    Navigator.pop(context);
  }

  void _save() {
    final contact = EmergencyContact(name: _name.text.trim(), number: _number.text.trim());
    final list = [..._settings.contacts];
    widget.index != null && _editing != null ? list[widget.index!] = contact : list.add(contact);
    _send(list, _editing == null ? "${contact.name} added" : "${contact.name} saved");
  }

  void _remove() {
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: boldText("Remove ${_editing!.name}?", fontSize: 18),
        content: regularText("They won't get through while Emergency contacts only is on.", fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: regularText("Cancel", fontSize: 14)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialog);
              _send([..._settings.contacts]..removeAt(widget.index!), "${_editing!.name} removed");
            },
            child: regularText("Remove", color: AppColors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        counterText: "", // the length limits are checked quietly; no "0/100" under the fields
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.darkLightGrey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.normalGreen, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    return ruleScreen(context, title: _editing == null ? "Add emergency contact" : "Edit emergency contact", children: [
      fieldLabel("Name"),
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        maxLength: maxContactNameLength,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontFamily: fontFamily, fontSize: 16),
        decoration: _decoration("e.g. Mom"),
      ),
      verticalSpace(16),
      fieldLabel("Phone number"),
      TextField(
        controller: _number,
        keyboardType: TextInputType.phone,
        maxLength: maxPhoneLength,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[\d\s()+.-]"))],
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontFamily: fontFamily, fontSize: 16),
        decoration: _decoration("e.g. (212) 555-0147"),
      ),
      verticalSpace(20),
      if (problem != null && (_name.text.isNotEmpty || _number.text.isNotEmpty)) ...[
        regularText(problem, fontSize: 13, color: AppColors.grey),
        verticalSpace(8),
      ],
      primaryButton(_saving ? "Saving…" : "Save", onTap: problem == null && !_saving ? _save : null),
      if (_editing != null) ...[
        verticalSpace(8),
        Center(
          child: TextButton(
            onPressed: _saving ? null : _remove,
            child: regularText("Remove from emergency contacts",
                color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ]);
  }
}
