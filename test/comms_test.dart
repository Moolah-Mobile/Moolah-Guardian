import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/plan.dart';

void main() {
  test('call log reads from the MDM, skipping entries it cannot use', () {
    final page = CommsPage.fromJson({
      "items": [
        {
          "id": "c-1",
          "time": "2026-11-24T15:58:10Z",
          "direction": "incoming",
          "number": "+12125550147",
          "name": "Mom",
          "durationSec": 192,
          "emergencyContact": true
        },
        {"id": "c-2", "time": "2026-11-24T14:02:44Z", "direction": "blocked", "number": "+13475550190", "name": null},
        {"id": "c-3", "time": "not a time", "direction": "incoming", "number": "1"},
        {"id": "c-4", "time": "2026-11-24T14:00:00Z", "direction": "sideways", "number": "1"},
      ],
      "coverage": {"enabled": true},
    }, CallEntry.fromJson);
    expect(page.items.length, 2);
    expect(page.enabled, isTrue);
    expect(page.items[0].who, "Mom");
    expect(page.items[0].durationSec, 192);
    expect(page.items[0].emergencyContact, isTrue);
    expect(page.items[0].time, DateTime.utc(2026, 11, 24, 15, 58, 10));
    expect(page.items[1].direction, CallDirection.blocked);
    expect(page.items[1].who, "+13475550190");
    expect(CommsPage.fromJson({"items": [], "coverage": {"enabled": false}}, CallEntry.fromJson).enabled, isFalse);
    expect(CommsPage.fromJson(null, CallEntry.fromJson).items, isEmpty);
  });

  test('message threads and messages read from the MDM', () {
    final threads = CommsPage.fromJson({
      "items": [
        {"number": "+12125550147", "name": "Mom", "lastTime": "2026-11-24T15:40:00Z", "lastText": "On my way",
          "lastDirection": "sent", "messageCount": 14, "emergencyContact": true},
        {"number": "", "lastTime": "2026-11-24T15:40:00Z"},
      ]
    }, MessageThread.fromJson);
    expect(threads.items.single.lastDirection, MessageDirection.sent);
    expect(threads.items.single.messageCount, 14);

    final messages = CommsPage.fromJson({
      "items": [
        {"id": "m-1", "time": "2026-11-24T15:40:00Z", "direction": "received", "text": "On my way", "kind": "sms"},
        {"id": "m-2", "time": "2026-11-24T15:41:00Z", "direction": "blocked", "text": "", "kind": "mms", "attachments": 2},
      ]
    }, MessageEntry.fromJson);
    expect(messages.items.length, 2);
    expect(messages.items[1].mms, isTrue);
    expect(messages.items[1].attachments, 2);
  });

  test('emergency contacts read from the MDM and are sent back as name and number', () {
    final s = EmergencySettings.fromJson({
      "emergencyOnly": true,
      "contacts": [
        {"id": "ec-1", "name": "Mom", "number": "+12125550147"},
        {"id": "ec-2", "name": "", "number": "(212) 555-0199"},
        {"id": "ec-3", "name": "No number", "number": ""},
      ],
      "notApplied": "This phone's software needs an update.",
    });
    expect(s.emergencyOnly, isTrue);
    expect(s.contacts.map((c) => c.name), ["Mom", "(212) 555-0199"]);
    expect(s.contacts.first.toJson(), {"name": "Mom", "number": "+12125550147"});
    expect(s.notApplied, isNotNull);
    expect(EmergencySettings.fromJson(null).contacts, isEmpty);
  });

  test('phone numbers match however they are written', () {
    expect(samePhoneNumber("(212) 555-0199", "+1 212 555 0199"), isTrue);
    expect(samePhoneNumber("+91 98765 43210", "09876543210"), isTrue);
    expect(samePhoneNumber("212-555-0199", "212-555-0198"), isFalse);
    expect(samePhoneNumber("", "911"), isFalse);
    expect(phoneProblem(""), isNotNull);
    expect(phoneProblem("call me"), isNotNull);
    expect(phoneProblem("12"), isNotNull);
    expect(phoneProblem("+1 (212) 555-0147"), isNull);
    expect(phoneProblem("1" * 33), isNotNull); // the MDM refuses numbers over 32 characters
  });

  test('durations and days read naturally', () {
    expect(formatCallDuration(45), "45 s");
    expect(formatCallDuration(192), "3 min 12 s");
    expect(formatCallDuration(120), "2 min");
    expect(formatCallDuration(3900), "1 h 5 min");
    final today = DateTime(2026, 11, 24, 10);
    expect(dayLabel(DateTime(2026, 11, 24, 1), today), "Today");
    expect(dayLabel(DateTime(2026, 11, 23, 23), today), "Yesterday");
    expect(dayLabel(DateTime(2026, 11, 20, 9), today), "Fri, Nov 20");
    expect(dayLabel(DateTime(2025, 12, 31), today), "Wed, Dec 31, 2025");
  });

  test('emergency contacts: 3 on every plan, 5 on Ultimate', () {
    expect(Plan.free.emergencyContactLimit, 3);
    expect(Plan.premium.emergencyContactLimit, 3);
    expect(Plan.ultimate.emergencyContactLimit, 5);
  });
}
