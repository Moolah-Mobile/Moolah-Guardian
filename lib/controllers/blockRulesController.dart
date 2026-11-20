import 'dart:convert';

import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/helper/sharedHelper.dart';

/// The parent's schedule and place rules for each child device.
///
/// The MDM is the record: every change is sent with setDeviceRestrictions before it shows here, and
/// [loadFromMdm] reads the rules back with getDeviceRestrictions. A copy is kept on this phone so the screens
/// open instantly and work offline. The MDM also says which saved rules the phone can't follow yet
/// (`notApplied`, for example places limited to set times); [notAppliedReason] gives that per rule.
class BlockRulesController extends GetxController {
  final Map<String, List<BlockSchedule>> _schedules = {};
  final Map<String, List<BlockPlace>> _places = {};
  final Map<String, Map<String, String>> _notApplied = {};
  final Map<String, DateTime> _refreshedAt = {};

  // Rules belong to the device, whichever ID a screen was opened with; the key is its connect ID.
  String _key(String kidId) {
    try {
      return Get.find<HomeController>().connectIdFor(kidId) ?? kidId;
    } catch (_) {
      return kidId;
    }
  }

  /// Whether a rule from getDeviceRestrictions is one of Guardian's schedules or places. Other rules
  /// (the "Blocked Apps" always-off pair, rules set from the MDM console) are left as they are.
  static bool isScheduleRule(Map rule) => rule["id"]?.toString().startsWith("sched-") == true;
  static bool isPlaceRule(Map rule) => rule["id"]?.toString().startsWith("place-") == true;

  /// The device's rule list with Guardian's schedules and places replaced by [schedules] and [places].
  static List<Map<String, dynamic>> mergeRules(
      List current, List<BlockSchedule> schedules, List<BlockPlace> places) {
    return [
      ...current
          .whereType<Map>()
          .where((r) => !isScheduleRule(r) && !isPlaceRule(r))
          .map((r) => Map<String, dynamic>.from(r)),
      ...schedules.map((s) => s.toMdmRule()),
      ...places.map((p) => p.toMdmRule()),
    ];
  }

  static Map<String, String> notAppliedFrom(dynamic list) => {
        for (final n in (list as List? ?? []).whereType<Map>())
          if (n["id"] != null) n["id"].toString(): n["reason"]?.toString() ?? "",
      };

  String _prefsKey(String key) => "block_rules_$key";

  void _load(String key) {
    if (_schedules.containsKey(key)) return;
    _schedules[key] = [];
    _places[key] = [];
    _notApplied[key] = {};
    String? raw;
    try {
      raw = Prefs.prefs.getString(_prefsKey(key));
    } catch (_) {
      raw = null;
    }
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _schedules[key] = (json["schedules"] as List? ?? [])
          .map((s) => BlockSchedule.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      _places[key] = (json["places"] as List? ?? [])
          .map((p) => BlockPlace.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      _notApplied[key] = Map<String, String>.from(json["notApplied"] as Map? ?? {});
      _sentOnce[key] = json["sent"] == true;
    } catch (_) {
      // A damaged entry is dropped rather than blocking the screens.
    }
  }

  void _save(String key) {
    try {
      Prefs.prefs.setString(
          _prefsKey(key),
          jsonEncode({
            "schedules": _schedules[key]!.map((s) => s.toJson()).toList(),
            "places": _places[key]!.map((p) => p.toJson()).toList(),
            "notApplied": _notApplied[key],
            "sent": _sentOnce[key] == true,
          }));
    } catch (_) {
      // Tests run without SharedPreferences; the rules then live for this session only.
    }
    update();
  }

  List<BlockSchedule> schedulesFor(String kidId) {
    final key = _key(kidId);
    _load(key);
    return List.unmodifiable(_schedules[key]!);
  }

  List<BlockPlace> placesFor(String kidId) {
    final key = _key(kidId);
    _load(key);
    return List.unmodifiable(_places[key]!);
  }

  // Whether this device's rules have reached the MDM at least once. Rules made before Guardian sent them
  // exist only on this phone; the first load sends them instead of dropping them.
  final Map<String, bool> _sentOnce = {};

  /// Why the child's phone isn't following the rule with [id] yet, or null when it is (or it's paused).
  String? notAppliedReason(String kidId, String id) {
    final key = _key(kidId);
    _load(key);
    return _notApplied[key]![id];
  }

  /// Reads the device's rules from the MDM. Skipped if done in the last [maxAge].
  Future<void> loadFromMdm(String kidId, {Duration maxAge = const Duration(seconds: 15)}) async {
    final key = _key(kidId);
    _load(key);
    final last = _refreshedAt[key];
    if (last != null && DateTime.now().difference(last) < maxAge) return;
    _refreshedAt[key] = DateTime.now();

    final res = await HomeRepo.getDeviceRestrictions(key);
    if (!res.isSuccessful) return; // keep showing the copy on this phone
    final data = res.data?["data"];
    final rules = (data?["rules"] as List? ?? []).whereType<Map>().map((r) => Map<String, dynamic>.from(r));

    final hasLocalOnly = _sentOnce[key] != true && (_schedules[key]!.isNotEmpty || _places[key]!.isNotEmpty);
    if (hasLocalOnly && !rules.any((r) => isScheduleRule(r) || isPlaceRule(r))) {
      await _send(key, _schedules[key]!, _places[key]!);
      return;
    }
    _schedules[key] = rules.where(isScheduleRule).map(BlockSchedule.fromMdmRule).toList();
    _places[key] = rules.where(isPlaceRule).map(BlockPlace.fromMdmRule).toList();
    _notApplied[key] = notAppliedFrom(data?["notApplied"]);
    _sentOnce[key] = true;
    _save(key);
  }

  /// Sends [schedules] and [places] as the device's Guardian rules, keeping its other rules. On success they
  /// become this device's rules here too; on failure nothing changes and the MDM's message is returned.
  Future<String?> _send(String key, List<BlockSchedule> schedules, List<BlockPlace> places) async {
    // setDeviceRestrictions replaces the whole list, so start from what the device has now.
    final current = await HomeRepo.getDeviceRestrictions(key);
    if (!current.isSuccessful) return current.message ?? "Couldn't reach the phone's settings. Try again.";
    final rules = mergeRules(current.data?["data"]?["rules"] as List? ?? [], schedules, places);
    final res = await HomeRepo.setDeviceRestrictions(connectId: key, rules: rules);
    if (!res.isSuccessful) return res.message ?? "Couldn't save. Try again.";
    _schedules[key] = schedules;
    _places[key] = places;
    _notApplied[key] = notAppliedFrom(res.data?["data"]?["notApplied"]);
    _sentOnce[key] = true;
    _refreshedAt[key] = DateTime.now();
    _save(key);
    return null;
  }

  List<BlockSchedule> _schedulesCopy(String key) => _schedules[key]!.map((s) => s.copy()).toList();
  List<BlockPlace> _placesCopy(String key) => _places[key]!.map((p) => p.copy()).toList();

  /// Adds [schedule], or replaces the saved one with the same id. Returns an error message, or null.
  Future<String?> saveSchedule(String kidId, BlockSchedule schedule) {
    final key = _key(kidId);
    _load(key);
    final list = _schedulesCopy(key);
    final index = list.indexWhere((s) => s.id == schedule.id);
    index < 0 ? list.add(schedule) : list[index] = schedule;
    return _send(key, list, _placesCopy(key));
  }

  Future<String?> deleteSchedule(String kidId, String id) {
    final key = _key(kidId);
    _load(key);
    return _send(key, _schedulesCopy(key)..removeWhere((s) => s.id == id), _placesCopy(key));
  }

  Future<String?> setScheduleEnabled(String kidId, String id, bool enabled) {
    final key = _key(kidId);
    _load(key);
    final list = _schedulesCopy(key);
    for (final s in list) {
      if (s.id == id) s.enabled = enabled;
    }
    return _send(key, list, _placesCopy(key));
  }

  /// Adds [place], or replaces the saved one with the same id. Returns an error message, or null.
  Future<String?> savePlace(String kidId, BlockPlace place) {
    final key = _key(kidId);
    _load(key);
    final list = _placesCopy(key);
    final index = list.indexWhere((p) => p.id == place.id);
    index < 0 ? list.add(place) : list[index] = place;
    return _send(key, _schedulesCopy(key), list);
  }

  Future<String?> deletePlace(String kidId, String id) {
    final key = _key(kidId);
    _load(key);
    return _send(key, _schedulesCopy(key), _placesCopy(key)..removeWhere((p) => p.id == id));
  }

  Future<String?> setPlaceEnabled(String kidId, String id, bool enabled) {
    final key = _key(kidId);
    _load(key);
    final list = _placesCopy(key);
    for (final p in list) {
      if (p.id == id) p.enabled = enabled;
    }
    return _send(key, _schedulesCopy(key), list);
  }

  /// The schedules running at [now] on this device.
  List<BlockSchedule> schedulesOnAt(String kidId, DateTime now) =>
      schedulesFor(kidId).where((s) => s.isOnAt(now)).toList();

  static String newId(String prefix) => "$prefix-${DateTime.now().microsecondsSinceEpoch}";
}
