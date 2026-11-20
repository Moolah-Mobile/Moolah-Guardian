import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/block_rule_model.dart';

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
}
