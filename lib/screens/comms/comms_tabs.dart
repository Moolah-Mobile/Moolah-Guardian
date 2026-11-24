import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/commsController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart' show clockAt, formatTime;
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/screens/comms/emergency_contacts.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

// Times on the child's clock, like the app rules: "Aman called at 4:05 PM" means 4:05 PM where Aman is.
DateTime _childTime(Kid kid, DateTime utc) => clockAt(kid.deviceDetail?.data?.utcOffsetMinutes, utc);
String _clock(DateTime t) => formatTime(t.hour * 60 + t.minute);

/// What a list shows while it can't show items: loading, not offered yet, an error or nothing yet.
Widget _listState<T>(BuildContext context, CommsLoad<CommsPage<T>> load,
    {required String childName, required String what, required String empty, required VoidCallback retry}) {
  if (load.value == null && load.loading) {
    return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
  }
  if (load.unavailable || load.value?.enabled == false) {
    return _note(Icons.hourglass_empty, "$what isn't available on $childName's phone yet",
        "It will show here once $childName's phone gets the update that sends it.");
  }
  if (load.value == null && load.error != null) {
    return Column(children: [
      _note(Icons.cloud_off_outlined, "Couldn't load $what", load.error!),
      TextButton(onPressed: retry, child: boldText("Try again", fontSize: 15, color: AppColors.normalGreen)),
    ]);
  }
  return _note(Icons.inbox_outlined, empty, null);
}

Widget _note(IconData icon, String title, String? text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(children: [
        iconBadge(icon, size: 56),
        verticalSpace(12),
        boldText(title, fontSize: 16),
        if (text != null) ...[
          verticalSpace(6),
          subHeadingText(text, textAlign: TextAlign.center, height: 1.45),
        ],
      ]),
    );

Widget _sectionHeader(String title, String? trailing) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: boldText(title, fontSize: 18)),
        if (trailing != null) regularText(trailing, fontSize: 13, color: AppColors.grey),
      ]),
    );

Widget _emergencyBadge() => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: "Emergency contact",
        child: Icon(Icons.verified_user, size: 16, color: AppColors.normalGreen),
      ),
    );

/// Shared frame for both tabs: pull to refresh, the emergency card, the clock note, then the list.
Widget _tabList(BuildContext context, {required Future<void> Function() onRefresh, required List<Widget> children}) {
  return Expanded(
    child: RefreshIndicator(
      color: AppColors.normalGreen,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(10, 16, 10, listEndPadding(context)),
        children: children,
      ),
    ),
  );
}

/// The Calls tab: who the child called and who called, newest first, by day.
class CallsTab extends StatelessWidget {
  const CallsTab({required this.kidId, super.key});
  final String kidId;

  static (IconData, Color, String) _look(CallEntry c) {
    switch (c.direction) {
      case CallDirection.incoming:
        return (Icons.call_received, AppColors.normalGreen, "Incoming · ${formatCallDuration(c.durationSec)}");
      case CallDirection.outgoing:
        return (Icons.call_made, AppColors.blue, "Outgoing · ${formatCallDuration(c.durationSec)}");
      case CallDirection.missed:
        return (Icons.call_missed, AppColors.red, "Missed");
      case CallDirection.rejected:
        return (Icons.call_end, AppColors.grey, "Declined");
      case CallDirection.blocked:
        return (Icons.block, AppColors.red, "Blocked by Emergency contacts only");
    }
  }

  @override
  Widget build(BuildContext context) {
    final kid = Get.find<HomeController>().getSelectedKid(kidId);
    final childName = childFirstName(kid);
    return GetBuilder<CommsController>(
      initState: (_) => Get.find<CommsController>().loadCalls(kidId),
      builder: (comms) {
        final load = comms.calls(kidId);
        final calls = load.value?.items ?? const <CallEntry>[];
        final today = _childTime(kid, DateTime.now().toUtc());
        final rows = <Widget>[];
        String? lastDay;
        for (final c in calls) {
          final t = _childTime(kid, c.time);
          final day = dayLabel(t, today);
          if (day != lastDay) {
            rows.add(Padding(
              padding: EdgeInsets.only(top: lastDay == null ? 0 : 14, bottom: 4),
              child: regularText(day, fontSize: 13, color: AppColors.grey, fontWeight: FontWeight.w700),
            ));
            lastDay = day;
          }
          final (icon, color, text) = _look(c);
          rows.add(ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 20, color: color),
            ),
            title: Row(children: [
              Flexible(child: boldText(c.who, fontSize: 15, maxLines: 1, textOverflow: TextOverflow.ellipsis)),
              if (c.emergencyContact) _emergencyBadge(),
            ]),
            subtitle: regularText(c.name == null ? text : "$text · ${c.number}",
                fontSize: 13, color: AppColors.grey, maxLines: 1, textOverflow: TextOverflow.ellipsis),
            trailing: regularText(_clock(t), fontSize: 13, color: AppColors.grey),
          ));
        }
        final note = childClockNote(kid);
        return _tabList(context, onRefresh: () async {
          await Future.wait([comms.loadCalls(kidId, force: true), comms.loadEmergency(kidId, force: true)]);
        }, children: [
          EmergencyContactsCard(kidId: kidId),
          verticalSpace(22),
          _sectionHeader("Recent calls", calls.isEmpty ? null : "Last 7 days"),
          if (note != null && calls.isNotEmpty) ...[infoNote(note), verticalSpace(10)],
          if (calls.isEmpty)
            _listState(context, load,
                childName: childName,
                what: "Call history",
                empty: "No calls in the last 7 days",
                retry: () => comms.loadCalls(kidId, force: true))
          else
            ...rows,
        ]);
      },
    );
  }
}

/// The Messages tab: one row per person the child texts with, newest first.
class MessagesTab extends StatelessWidget {
  const MessagesTab({required this.kidId, super.key});
  final String kidId;

  @override
  Widget build(BuildContext context) {
    final kid = Get.find<HomeController>().getSelectedKid(kidId);
    final childName = childFirstName(kid);
    return GetBuilder<CommsController>(
      initState: (_) => Get.find<CommsController>().loadThreads(kidId),
      builder: (comms) {
        final load = comms.threads(kidId);
        final threads = load.value?.items ?? const <MessageThread>[];
        final today = _childTime(kid, DateTime.now().toUtc());
        return _tabList(context, onRefresh: () async {
          await Future.wait([comms.loadThreads(kidId, force: true), comms.loadEmergency(kidId, force: true)]);
        }, children: [
          EmergencyContactsCard(kidId: kidId),
          verticalSpace(22),
          _sectionHeader("Conversations", threads.isEmpty ? null : "Last 30 days"),
          if (threads.isEmpty)
            _listState(context, load,
                childName: childName,
                what: "Messages",
                empty: "No messages in the last 30 days",
                retry: () => comms.loadThreads(kidId, force: true))
          else
            for (final th in threads)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => MessageThreadScreen(kidId: kidId, thread: th))),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.veryVeryLightGreen,
                  child: Icon(Icons.person_outline, color: AppColors.normalGreen),
                ),
                title: Row(children: [
                  Flexible(child: boldText(th.who, fontSize: 15, maxLines: 1, textOverflow: TextOverflow.ellipsis)),
                  if (th.emergencyContact) _emergencyBadge(),
                ]),
                subtitle: regularText(
                    switch (th.lastDirection) {
                      MessageDirection.sent => "$childName: ${th.lastText}",
                      MessageDirection.blocked => "Blocked: ${th.lastText}",
                      MessageDirection.received => th.lastText,
                    },
                    fontSize: 13,
                    color: AppColors.grey,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis),
                trailing: regularText(_whenShort(_childTime(kid, th.lastTime), today),
                    fontSize: 12, color: AppColors.grey),
              ),
        ]);
      },
    );
  }

  static String _whenShort(DateTime t, DateTime today) {
    final day = dayLabel(t, today);
    return day == "Today" ? _clock(t) : day.split(", ").length > 1 ? day.split(", ")[1] : day;
  }
}

/// One conversation: the child's messages on the right, the other person's on the left.
class MessageThreadScreen extends StatelessWidget {
  const MessageThreadScreen({required this.kidId, required this.thread, super.key});
  final String kidId;
  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final kid = Get.find<HomeController>().getSelectedKid(kidId);
    final childName = childFirstName(kid);
    return GetBuilder<CommsController>(
      initState: (_) => Get.find<CommsController>().loadMessages(kidId, thread.number),
      builder: (comms) {
        final load = comms.messages(kidId, thread.number);
        // Oldest first, as a conversation reads.
        final messages = (load.value?.items ?? const <MessageEntry>[]).reversed.toList();
        final today = _childTime(kid, DateTime.now().toUtc());
        final children = <Widget>[
          if (thread.name != null) Center(child: regularText(thread.number, fontSize: 13, color: AppColors.grey)),
          if (thread.emergencyContact)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: pill(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_user, size: 14, color: AppColors.normalGreen),
                    horizontalSpace(4),
                    regularText("Emergency contact", fontSize: 12, color: AppColors.normalGreen),
                  ]),
                ),
              ),
            ),
          verticalSpace(12),
        ];
        if (messages.isEmpty) {
          children.add(_listState(context, load,
              childName: childName,
              what: "Messages",
              empty: "No messages in the last 30 days",
              retry: () => comms.loadMessages(kidId, thread.number, force: true)));
        }
        String? lastDay;
        for (final m in messages) {
          final t = _childTime(kid, m.time);
          final day = dayLabel(t, today);
          if (day != lastDay) {
            children.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(child: regularText(day, fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w700)),
            ));
            lastDay = day;
          }
          children.add(_bubble(m, t, childName));
        }
        return ruleScreen(context, title: thread.who, children: children);
      },
    );
  }

  Widget _bubble(MessageEntry m, DateTime t, String childName) {
    final mine = m.direction == MessageDirection.sent;
    final blocked = m.direction == MessageDirection.blocked;
    final body = m.text.isNotEmpty
        ? m.text
        : m.attachments > 0
            ? "${m.attachments} attachment${m.attachments == 1 ? "" : "s"}"
            : "(no text)";
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: blocked
                ? AppColors.lightGrey
                : mine
                    ? AppColors.normalGreen
                    : AppColors.veryVeryLightGreen,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: blocked ? Border.all(color: AppColors.darkLightGrey) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blocked) ...[
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.block, size: 14, color: AppColors.red),
                  horizontalSpace(4),
                  regularText("Blocked by Emergency contacts only",
                      fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600),
                ]),
                verticalSpace(4),
              ],
              regularText(body,
                  fontSize: 15, color: mine && !blocked ? AppColors.white : AppColors.black, height: 1.35),
              verticalSpace(4),
              regularText("${m.mms ? "MMS · " : ""}${_clock(t)}",
                  fontSize: 11, color: mine && !blocked ? AppColors.white.withValues(alpha: 0.8) : AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
