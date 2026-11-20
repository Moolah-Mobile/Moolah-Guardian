import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/screens/connect_device/pair_too_far_screen.dart';

void main() {
  test('times read as 12-hour for parents and 24-hour for the MDM', () {
    expect(formatTime(0), "12:00 AM");
    expect(formatTime(8 * 60), "8:00 AM");
    expect(formatTime(12 * 60), "12:00 PM");
    expect(formatTime(15 * 60 + 30), "3:30 PM");
    expect(formatTime(23 * 60 + 59), "11:59 PM");
    expect(formatMinutes24(8 * 60), "08:00");
    expect(formatMinutes24(21 * 60 + 30), "21:30");
  });

  test('day sets read naturally', () {
    expect(describeDays({...everyDay}), "Every day");
    expect(describeDays({...weekdays}), "Mon–Fri");
    expect(describeDays({...weekend}), "Weekends");
    expect(describeDays({1, 3}), "Mon, Wed");
    expect(describeDays({}), "No days");
    expect(describeDays({1, 2, 3, 4, 5, 6}), "Mon–Sat");
    expect(describeDays({1, 3, 4, 5}), "Mon, Wed–Fri");
    expect(describeDays({1, 2, 4}), "Mon, Tue, Thu");
    expect(describeDays({6, 7, 1}), "Mon, Sat, Sun");
  });

  test('area sizes never break before the unit', () {
    expect(BlockPlace(id: "p", name: "", lat: 0, lng: 0, radiusM: 400).radiusText, "400 m");
    expect(BlockPlace(id: "p", name: "", lat: 0, lng: 0, radiusM: 1000).radiusText, "1 km");
  });

  test('a daytime schedule covers only its window on its days', () {
    final school = BlockSchedule(id: "s", days: {...weekdays}, from: 8 * 60, to: 15 * 60);
    expect(school.isOnAt(DateTime(2026, 11, 20, 10, 0)), isTrue); // Friday 10:00 AM
    expect(school.isOnAt(DateTime(2026, 11, 20, 15, 0)), isFalse); // ends at 3:00 PM
    expect(school.isOnAt(DateTime(2026, 11, 20, 7, 59)), isFalse);
    expect(school.isOnAt(DateTime(2026, 11, 21, 10, 0)), isFalse); // Saturday
    school.enabled = false;
    expect(school.isOnAt(DateTime(2026, 11, 20, 10, 0)), isFalse);
  });

  test('an overnight schedule runs past midnight into the next day', () {
    // Friday only, 9:30 PM – 7:00 AM: Friday night and Saturday morning.
    final bedtime = BlockSchedule(id: "b", days: {5}, from: 21 * 60 + 30, to: 7 * 60);
    expect(bedtime.isOnAt(DateTime(2026, 11, 20, 22, 0)), isTrue); // Friday 10 PM
    expect(bedtime.isOnAt(DateTime(2026, 11, 21, 6, 0)), isTrue); // Saturday 6 AM
    expect(bedtime.isOnAt(DateTime(2026, 11, 21, 22, 0)), isFalse); // Saturday night isn't chosen
    expect(bedtime.isOnAt(DateTime(2026, 11, 20, 6, 0)), isFalse); // Friday morning belongs to Thursday
  });

  test('rules survive a save and load, and give the MDM rule shape', () {
    final s = BlockSchedule(
        id: "sched-1", name: "Bedtime", days: {...everyDay}, from: 21 * 60 + 30, to: 7 * 60, allApps: true);
    final back = BlockSchedule.fromJson(s.toJson());
    expect(back.name, "Bedtime");
    expect(back.days, {...everyDay});
    expect(back.from, 21 * 60 + 30);
    expect(back.allApps, isTrue);
    expect(s.toMdmRule(), containsPair("from", "21:30"));
    expect(s.toMdmRule(), containsPair("mode", "allowOnly"));
    expect(s.toMdmRule()["days"], ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]);

    final p = BlockPlace(id: "place-1", name: "School", lat: 28.6, lng: 77.2, radiusM: 250, inside: false,
        useTimes: true, packages: ["com.block.juggle"]);
    final placeBack = BlockPlace.fromJson(p.toJson());
    expect(placeBack.inside, isFalse);
    expect(placeBack.radiusM, 250);
    expect(placeBack.packages, ["com.block.juggle"]);
    expect(p.toMdmRule(), containsPair("type", "geofence"));
    expect(p.toMdmRule(), containsPair("trigger", "outside"));
    expect(p.toMdmRule(), containsPair("from", "08:00"));
    expect(p.whenText, "Mon–Fri · 8:00 AM – 3:00 PM");
  });

  test('rules read back from the MDM are the rules that were sent', () {
    final s = BlockSchedule(
        id: "sched-1", name: "Homework", days: {...weekdays}, from: 17 * 60, to: 21 * 60,
        packages: ["com.zhiliaoapp.musically.go"]);
    final back = BlockSchedule.fromMdmRule(s.toMdmRule());
    expect(back.toJson(), s.toJson());

    final bedtime = BlockSchedule(id: "sched-2", days: {...everyDay}, from: 21 * 60 + 30, to: 7 * 60, allApps: true);
    expect(BlockSchedule.fromMdmRule(bedtime.toMdmRule()).toJson(), bedtime.toJson());

    final anyTime = BlockPlace(id: "place-1", name: "School", lat: 28.6, lng: 77.2, radiusM: 400, inside: false,
        enabled: false, packages: ["com.block.juggle"]);
    final placeBack = BlockPlace.fromMdmRule(anyTime.toMdmRule());
    expect(placeBack.useTimes, isFalse);
    expect(placeBack.inside, isFalse);
    expect(placeBack.enabled, isFalse);
    expect(placeBack.radiusM, 400);
    expect(placeBack.packages, ["com.block.juggle"]);

    final timed = BlockPlace(id: "place-2", lat: 1, lng: 2, useTimes: true, days: {6}, from: 9 * 60, to: 12 * 60);
    final timedBack = BlockPlace.fromMdmRule(timed.toMdmRule());
    expect(timedBack.useTimes, isTrue);
    expect(timedBack.days, {6});
    expect(timedBack.from, 9 * 60);
    expect(timedBack.to, 12 * 60);

    // A rule with no days set (made elsewhere) runs every day.
    expect(BlockSchedule.fromMdmRule({"id": "sched-x", "type": "time", "from": "08:00", "to": "09:00"}).days,
        {...everyDay});
    expect(parseMinutes24("21:30"), 21 * 60 + 30);
    expect(parseMinutes24("24:00"), isNull);
  });

  test('saving replaces only Guardian\'s schedules and places, keeping Blocked Apps', () {
    final current = [
      {"id": "always-off", "type": "time", "packages": ["com.block.juggle"], "from": "00:00", "to": "23:59"},
      {"id": "always-off-last-minute", "type": "time", "packages": ["com.block.juggle"], "from": "23:59", "to": "00:00"},
      {"id": "sched-old", "type": "time", "packages": ["a.b"], "from": "08:00", "to": "09:00"},
      {"id": "place-old", "type": "geofence", "lat": 1, "lng": 2, "radiusM": 200, "packages": ["a.b"]},
    ];
    final s = BlockSchedule(id: "sched-new", packages: ["c.d"]);
    final p = BlockPlace(id: "place-new", lat: 3, lng: 4, packages: ["e.f"]);
    final merged = BlockRulesController.mergeRules(current, [s], [p]);
    expect(merged.map((r) => r["id"]), ["always-off", "always-off-last-minute", "sched-new", "place-new"]);
    expect(BlockRulesController.mergeRules(current, [], []).map((r) => r["id"]),
        ["always-off", "always-off-last-minute"]);
  });

  test('the MDM\'s notApplied list tells the parent why a rule is not active', () {
    final notApplied = BlockRulesController.notAppliedFrom([
      {"id": "place-2", "reason": "Place rules limited to certain days or times need a newer agent on the phone; not applied yet"},
      {"id": "sched-2", "reason": "\"allowOnly\" rules need a newer agent on the phone; not applied yet"},
      {"id": null, "reason": "no id"},
    ]);
    expect(notApplied.keys, ["place-2", "sched-2"]);
    expect(notActiveText(notApplied["place-2"]!, "Aman"), contains("places with set times"));
    expect(notActiveText(notApplied["sched-2"]!, "Aman"), contains("All apps"));
    expect(notActiveText("Place rules are only applied on Miro C67 phones so far", "Aman"),
        "Not active on Aman's phone yet: this phone doesn't support places.");
    expect(notActiveText("something new", "Aman"), "Not active on Aman's phone yet.");
  });

  test('an app hidden by a block stays in the app list', () {
    final hidden = App(pkg: "com.tiktok.lite.go", name: "TikTok Lite", launchable: false, systemApp: false, state: "hidden");
    final service = App(pkg: "com.example.service", name: "Service", launchable: false, systemApp: false, state: "active");
    expect(HomeController.isUserApp(hidden), isTrue);
    expect(HomeController.isUserApp(service), isFalse);
  });

  test('rules are checked on the child\'s clock when the phone reports its time zone', () {
    // 8:19 PM Friday in India is 9:49 AM Friday in New York (UTC-5 in November).
    final instant = DateTime.utc(2026, 11, 20, 14, 49);
    final newYork = clockAt(-300, instant);
    expect([newYork.weekday, newYork.hour, newYork.minute], [DateTime.friday, 9, 49]);
    final india = clockAt(330, instant);
    expect([india.hour, india.minute], [20, 19]);

    final homework = BlockSchedule(id: "sched-h", days: {...weekdays}, from: 17 * 60, to: 21 * 60);
    expect(homework.isOnAt(india), isTrue);
    expect(homework.isOnAt(newYork), isFalse);

    // Across midnight the child's day can differ from the parent's: Saturday 1 AM in India is Friday 2:30 PM
    // in New York.
    final late = clockAt(-300, DateTime.utc(2026, 11, 20, 19, 30));
    expect([late.weekday, late.hour], [DateTime.friday, 14]);
  });

  test('the too-far screen says how far away the parent is', () {
    expect(PairTooFarScreen.milesText(2414), "1.5 miles");
    expect(PairTooFarScreen.milesText(13520), "8.4 miles");
    expect(PairTooFarScreen.milesText(13500000), "8389 miles");
  });
}
