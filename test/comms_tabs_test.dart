import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/commsController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/screens/comms/comms_tabs.dart';
import 'package:moolah/screens/comms/emergency_contacts.dart';

const kidId = "C67202408006423";

Future<void> _loadFonts() async {
  final loader = FontLoader("DM Sans");
  for (final f in ["Regular", "Bold", "Medium"]) {
    loader.addFont(Future.value(ByteData.sublistView(File("assets/fonts/dm-sans/DMSans-$f.ttf").readAsBytesSync())));
  }
  await loader.load();
}

CommsController _comms() {
  final c = CommsController();
  Get.put(c);
  return c;
}

void _fill<T>(CommsLoad<T> load, T value) {
  load.value = value;
  load.loadedAt = DateTime.now(); // fresh, so the screens don't fetch
}

Future<void> _pump(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: Column(children: [body]))));
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Get.reset();
    final home = HomeController();
    home.connectedKids = [Kid(kidId: kidId)..name = "Aman Arora"];
    Get.put(home);
  });

  final now = DateTime.now().toUtc();

  testWidgets('Calls tab lists calls by day with the emergency card on top', (tester) async {
    final comms = _comms();
    _fill(comms.emergency(kidId), EmergencySettings(contacts: [EmergencyContact(name: "Mom", number: "+12125550147")]));
    _fill(
        comms.calls(kidId),
        CommsPage(items: [
          CallEntry(id: "1", time: now, direction: CallDirection.incoming, number: "+12125550147", name: "Mom",
              durationSec: 192, emergencyContact: true),
          CallEntry(id: "2", time: now.subtract(const Duration(minutes: 5)), direction: CallDirection.blocked,
              number: "+13475550190"),
        ]));
    await _pump(tester, const CallsTab(kidId: kidId));
    expect(find.text("Emergency contacts only"), findsOneWidget);
    expect(find.text("Manage emergency contacts (1 of 3)"), findsOneWidget);
    expect(find.text("Recent calls"), findsOneWidget);
    expect(find.text("Incoming · 3 min 12 s · +12125550147"), findsOneWidget);
    expect(find.text("Blocked by Emergency contacts only"), findsOneWidget);
  });

  testWidgets('Calls tab says when the phone does not send call history yet', (tester) async {
    final comms = _comms();
    comms.emergency(kidId)
      ..unavailable = true
      ..loadedAt = DateTime.now();
    comms.calls(kidId)
      ..unavailable = true
      ..loadedAt = DateTime.now();
    await _pump(tester, const CallsTab(kidId: kidId));
    expect(find.text("Call history isn't available on Aman's phone yet"), findsOneWidget);
    expect(find.text("Not available on Aman's phone yet."), findsOneWidget);
  });

  testWidgets('Messages tab lists conversations, and a conversation shows its messages', (tester) async {
    final comms = _comms();
    _fill(comms.emergency(kidId), EmergencySettings(emergencyOnly: true, contacts: [
      EmergencyContact(name: "Mom", number: "+12125550147"),
    ]));
    final thread = MessageThread(
        number: "+12125550147", name: "Mom", lastTime: now, lastText: "On my way",
        lastDirection: MessageDirection.received, messageCount: 3, emergencyContact: true);
    _fill(comms.threads(kidId), CommsPage(items: [
      thread,
      MessageThread(number: "+13475550190", lastTime: now.subtract(const Duration(hours: 30)), lastText: "hey",
          lastDirection: MessageDirection.blocked),
    ]));
    _fill(comms.messages(kidId, thread.number), CommsPage(items: [
      MessageEntry(id: "3", time: now, direction: MessageDirection.received, text: "On my way"),
      MessageEntry(id: "2", time: now.subtract(const Duration(minutes: 1)), direction: MessageDirection.sent,
          text: "Where are you?"),
    ]));
    await _pump(tester, const MessagesTab(kidId: kidId));
    expect(find.text("Conversations"), findsOneWidget);
    expect(find.text("Blocked: hey"), findsOneWidget);
    expect(find.textContaining("On: Aman can only call and text"), findsOneWidget);

    await tester.tap(find.text("Mom").last);
    await tester.pumpAndSettle();
    expect(find.text("Where are you?"), findsOneWidget);
    expect(find.text("Emergency contact"), findsOneWidget);
  });

  testWidgets('Emergency contacts list shows the plan limit', (tester) async {
    final comms = _comms();
    _fill(comms.emergency(kidId), EmergencySettings(contacts: [
      EmergencyContact(name: "Mom", number: "+12125550147"),
      EmergencyContact(name: "Dad", number: "(212) 555-0199"),
    ]));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    await tester.pumpWidget(const GetMaterialApp(home: EmergencyContactsScreen(kidId: kidId)));
    await tester.pump();
    expect(find.text("Add emergency contact (2 of 3)"), findsOneWidget);
    expect(find.text("Dad"), findsOneWidget);
  });
}
