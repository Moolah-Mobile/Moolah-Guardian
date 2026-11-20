// Rules that turn apps off on the child's phone at set times ([BlockSchedule]) or at a place ([BlockPlace]).
//
// [toMdmRule] is the rule as setDeviceRestrictions takes it, and [BlockSchedule.fromMdmRule] /
// [BlockPlace.fromMdmRule] read it back from getDeviceRestrictions. BlockRulesController keeps them in step.

/// Days are 1 (Monday) to 7 (Sunday), as in [DateTime.weekday].
const weekdays = {1, 2, 3, 4, 5};
const weekend = {6, 7};
const everyDay = {1, 2, 3, 4, 5, 6, 7};

const _dayKeys = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
const _dayShort = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/// A time of day (minutes after midnight, 0–1439) as parents read it: "8:00 AM", "3:30 PM", "12:00 AM".
String formatTime(int minutes) {
  final hour = minutes ~/ 60;
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return "$h12:${(minutes % 60).toString().padLeft(2, '0')} ${hour < 12 ? "AM" : "PM"}";
}

/// The same time as the MDM's rules expect it: "08:00", "15:30".
String formatMinutes24(int minutes) =>
    "${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}";

/// "Every day", "Mon–Fri", "Weekends" or "Mon, Wed".
String describeDays(Set<int> days) {
  if (days.length == 7) return "Every day";
  if (days.length == 5 && days.containsAll(weekdays)) return "Mon–Fri";
  if (days.length == 2 && days.containsAll(weekend)) return "Weekends";
  if (days.isEmpty) return "No days";
  // Runs of three or more days read as a range: {1..6} is "Mon–Sat", {1, 3, 4, 5} is "Mon, Wed–Fri".
  final sorted = days.toList()..sort();
  final parts = <String>[];
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
      j++;
    }
    if (j - i >= 2) {
      parts.add("${_dayShort[sorted[i] - 1]}–${_dayShort[sorted[j] - 1]}");
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(_dayShort[sorted[k] - 1]);
      }
    }
    i = j + 1;
  }
  return parts.join(", ");
}

/// Whether a daily window [from]–[to] (minutes) on [days] covers [now]. A window that ends before it starts
/// runs overnight: Mon 21:30–07:00 covers Monday night and Tuesday morning.
bool windowCovers(Set<int> days, int from, int to, DateTime now) {
  final minute = now.hour * 60 + now.minute;
  if (from == to) return days.contains(now.weekday);
  if (from < to) return days.contains(now.weekday) && minute >= from && minute < to;
  final yesterday = now.weekday == 1 ? 7 : now.weekday - 1;
  return (days.contains(now.weekday) && minute >= from) || (days.contains(yesterday) && minute < to);
}

/// "08:00" → 480. Null for anything that isn't an "HH:mm" time.
int? parseMinutes24(dynamic value) {
  final m = RegExp(r"^([01][0-9]|2[0-3]):([0-5][0-9])$").firstMatch(value?.toString() ?? "");
  return m == null ? null : int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

List<String> _packagesFrom(dynamic json) => (json as List? ?? []).map((p) => p.toString()).toList();

Set<int> _daysFromJson(dynamic json) {
  final list = json as List? ?? [];
  return list.map((d) => _dayKeys.indexOf(d.toString()) + 1).where((d) => d > 0).toSet();
}

List<String> _daysToJson(Set<int> days) => (days.toList()..sort()).map((d) => _dayKeys[d - 1]).toList();

class BlockSchedule {
  final String id;
  String name;
  bool enabled;
  Set<int> days;
  int from;
  int to;
  // True: every app except the ones the child always keeps (phone, messages, Moolah).
  bool allApps;
  List<String> packages;

  BlockSchedule({
    required this.id,
    this.name = "",
    this.enabled = true,
    Set<int>? days,
    this.from = 8 * 60,
    this.to = 15 * 60,
    this.allApps = false,
    List<String>? packages,
  })  : days = days ?? {...weekdays},
        packages = packages ?? [];

  BlockSchedule copy() => BlockSchedule(
      id: id, name: name, enabled: enabled, days: {...days}, from: from, to: to, allApps: allApps,
      packages: [...packages]);

  String get whenText => "${describeDays(days)} · ${formatTime(from)} – ${formatTime(to)}";

  bool isOnAt(DateTime now) => enabled && windowCovers(days, from, to, now);

  factory BlockSchedule.fromJson(Map<String, dynamic> json) => BlockSchedule(
        id: json["id"].toString(),
        name: json["name"]?.toString() ?? "",
        enabled: json["enabled"] != false,
        days: _daysFromJson(json["days"]),
        from: (json["fromMin"] as num?)?.toInt() ?? 8 * 60,
        to: (json["toMin"] as num?)?.toInt() ?? 15 * 60,
        allApps: json["allApps"] == true,
        packages: (json["packages"] as List? ?? []).map((p) => p.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "enabled": enabled,
        "days": _daysToJson(days),
        "fromMin": from,
        "toMin": to,
        "allApps": allApps,
        "packages": packages,
      };

  /// A schedule from getDeviceRestrictions. No days means every day.
  factory BlockSchedule.fromMdmRule(Map<String, dynamic> rule) => BlockSchedule(
        id: rule["id"].toString(),
        name: rule["name"]?.toString() ?? "",
        enabled: rule["enabled"] != false,
        days: rule["days"] == null ? {...everyDay} : _daysFromJson(rule["days"]),
        from: parseMinutes24(rule["from"]) ?? 8 * 60,
        to: parseMinutes24(rule["to"]) ?? 15 * 60,
        allApps: rule["mode"] == "allowOnly",
        packages: _packagesFrom(rule["packages"]),
      );

  Map<String, dynamic> toMdmRule() => {
        "id": id,
        "name": name,
        "type": "time",
        "enabled": enabled,
        "days": _daysToJson(days),
        "from": formatMinutes24(from),
        "to": formatMinutes24(to),
        "mode": allApps ? "allowOnly" : "block",
        "packages": packages,
      };
}

class BlockPlace {
  final String id;
  String name;
  double lat;
  double lng;
  int radiusM;
  // True: block while the child is inside the area; false: while outside it.
  bool inside;
  bool enabled;
  // False: any time; true: only during [days] [from]–[to].
  bool useTimes;
  Set<int> days;
  int from;
  int to;
  List<String> packages;

  BlockPlace({
    required this.id,
    this.name = "",
    required this.lat,
    required this.lng,
    this.radiusM = 200,
    this.inside = true,
    this.enabled = true,
    this.useTimes = false,
    Set<int>? days,
    this.from = 8 * 60,
    this.to = 15 * 60,
    List<String>? packages,
  })  : days = days ?? {...weekdays},
        packages = packages ?? [];

  BlockPlace copy() => BlockPlace(
      id: id, name: name, lat: lat, lng: lng, radiusM: radiusM, inside: inside, enabled: enabled,
      useTimes: useTimes, days: {...days}, from: from, to: to, packages: [...packages]);

  static const minRadius = 100;
  static const maxRadius = 1000;

  String get radiusText => radiusM >= 1000 ? "1\u00A0km" : "$radiusM\u00A0m"; // no line break before the unit

  String get whenText =>
      useTimes ? "${describeDays(days)} · ${formatTime(from)} – ${formatTime(to)}" : "Any time";

  factory BlockPlace.fromJson(Map<String, dynamic> json) => BlockPlace(
        id: json["id"].toString(),
        name: json["name"]?.toString() ?? "",
        lat: (json["lat"] as num?)?.toDouble() ?? 0,
        lng: (json["lng"] as num?)?.toDouble() ?? 0,
        radiusM: (json["radiusM"] as num?)?.toInt() ?? 200,
        inside: json["trigger"] != "outside",
        enabled: json["enabled"] != false,
        useTimes: json["useTimes"] == true,
        days: _daysFromJson(json["days"]),
        from: (json["fromMin"] as num?)?.toInt() ?? 8 * 60,
        to: (json["toMin"] as num?)?.toInt() ?? 15 * 60,
        packages: (json["packages"] as List? ?? []).map((p) => p.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "lat": lat,
        "lng": lng,
        "radiusM": radiusM,
        "trigger": inside ? "inside" : "outside",
        "enabled": enabled,
        "useTimes": useTimes,
        "days": _daysToJson(days),
        "fromMin": from,
        "toMin": to,
        "packages": packages,
      };

  /// A place from getDeviceRestrictions; one with days or times is limited to them.
  factory BlockPlace.fromMdmRule(Map<String, dynamic> rule) {
    final from = parseMinutes24(rule["from"]);
    final to = parseMinutes24(rule["to"]);
    return BlockPlace(
      id: rule["id"].toString(),
      name: rule["name"]?.toString() ?? "",
      lat: (rule["lat"] as num?)?.toDouble() ?? 0,
      lng: (rule["lng"] as num?)?.toDouble() ?? 0,
      radiusM: (rule["radiusM"] as num?)?.toInt() ?? 200,
      inside: rule["trigger"] != "outside",
      enabled: rule["enabled"] != false,
      useTimes: from != null && to != null,
      days: rule["days"] == null ? {...everyDay} : _daysFromJson(rule["days"]),
      from: from ?? 8 * 60,
      to: to ?? 15 * 60,
      packages: _packagesFrom(rule["packages"]),
    );
  }

  Map<String, dynamic> toMdmRule() => {
        "id": id,
        "name": name,
        "type": "geofence",
        "enabled": enabled,
        "lat": lat,
        "lng": lng,
        "radiusM": radiusM,
        "trigger": inside ? "inside" : "outside",
        if (useTimes) "days": _daysToJson(days),
        if (useTimes) "from": formatMinutes24(from),
        if (useTimes) "to": formatMinutes24(to),
        "mode": "block",
        "packages": packages,
      };
}
