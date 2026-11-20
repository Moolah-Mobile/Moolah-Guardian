import 'dart:convert';

import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/sharedHelper.dart';

/// The parent's schedule and place rules for each child device.
///
/// The MDM agent can't enforce these yet (it has no days, overnight ranges or geofences), so the rules are
/// kept on this phone, per device, until setDeviceRestrictions accepts them ([BlockSchedule.toMdmRule],
/// [BlockPlace.toMdmRule]). Sending them now would block apps every day, so nothing is sent.
class BlockRulesController extends GetxController {
  final Map<String, List<BlockSchedule>> _schedules = {};
  final Map<String, List<BlockPlace>> _places = {};

  // Rules belong to the device, whichever ID a screen was opened with.
  String _key(String kidId) {
    try {
      return Get.find<HomeController>().connectIdFor(kidId) ?? kidId;
    } catch (_) {
      return kidId;
    }
  }

  String _prefsKey(String key) => "block_rules_$key";

  void _load(String key) {
    if (_schedules.containsKey(key)) return;
    _schedules[key] = [];
    _places[key] = [];
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

  /// Adds [schedule], or replaces the saved one with the same id.
  void saveSchedule(String kidId, BlockSchedule schedule) {
    final key = _key(kidId);
    _load(key);
    final list = _schedules[key]!;
    final index = list.indexWhere((s) => s.id == schedule.id);
    index < 0 ? list.add(schedule) : list[index] = schedule;
    _save(key);
  }

  void deleteSchedule(String kidId, String id) {
    final key = _key(kidId);
    _load(key);
    _schedules[key]!.removeWhere((s) => s.id == id);
    _save(key);
  }

  void setScheduleEnabled(String kidId, String id, bool enabled) {
    final key = _key(kidId);
    _load(key);
    for (final s in _schedules[key]!) {
      if (s.id == id) s.enabled = enabled;
    }
    _save(key);
  }

  /// Adds [place], or replaces the saved one with the same id.
  void savePlace(String kidId, BlockPlace place) {
    final key = _key(kidId);
    _load(key);
    final list = _places[key]!;
    final index = list.indexWhere((p) => p.id == place.id);
    index < 0 ? list.add(place) : list[index] = place;
    _save(key);
  }

  void deletePlace(String kidId, String id) {
    final key = _key(kidId);
    _load(key);
    _places[key]!.removeWhere((p) => p.id == id);
    _save(key);
  }

  void setPlaceEnabled(String kidId, String id, bool enabled) {
    final key = _key(kidId);
    _load(key);
    for (final p in _places[key]!) {
      if (p.id == id) p.enabled = enabled;
    }
    _save(key);
  }

  /// The schedules running at [now] on this device.
  List<BlockSchedule> schedulesOnAt(String kidId, DateTime now) =>
      schedulesFor(kidId).where((s) => s.isOnAt(now)).toList();

  static String newId(String prefix) => "$prefix-${DateTime.now().microsecondsSinceEpoch}";
}
