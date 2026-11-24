// Calls, messages and emergency contacts on the child's phone, as the MDM reports them
// (getCallLog, getMessageThreads, getMessages, getEmergencyContacts). See
// build/share/mdm-calls-messages-emergency.md for the API.

DateTime? _time(dynamic v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;
String _text(dynamic v) => v is String ? v.trim() : "";
String? _nameOrNull(dynamic v) {
  final s = _text(v);
  return s.isEmpty ? null : s;
}

enum CallDirection { incoming, outgoing, missed, rejected, blocked }

class CallEntry {
  CallEntry({
    required this.id,
    required this.time,
    required this.direction,
    required this.number,
    this.name,
    this.durationSec = 0,
    this.emergencyContact = false,
  });

  final String id;
  final DateTime time; // UTC
  final CallDirection direction;
  final String number;
  final String? name;
  final int durationSec;
  final bool emergencyContact;

  /// The contact's name on the child's phone, or the number.
  String get who => name ?? number;

  static CallEntry? fromJson(Map<String, dynamic> j) {
    final time = _time(j["time"]);
    final direction = CallDirection.values.where((d) => d.name == j["direction"]).firstOrNull;
    if (time == null || direction == null) return null;
    return CallEntry(
      id: _text(j["id"]),
      time: time,
      direction: direction,
      number: _text(j["number"]),
      name: _nameOrNull(j["name"]),
      durationSec: (j["durationSec"] as num?)?.toInt() ?? 0,
      emergencyContact: j["emergencyContact"] == true,
    );
  }
}

enum MessageDirection { received, sent, blocked }

class MessageThread {
  MessageThread({
    required this.number,
    this.name,
    required this.lastTime,
    required this.lastText,
    required this.lastDirection,
    this.messageCount = 0,
    this.emergencyContact = false,
  });

  final String number;
  final String? name;
  final DateTime lastTime; // UTC
  final String lastText;
  final MessageDirection lastDirection;
  final int messageCount;
  final bool emergencyContact;

  String get who => name ?? number;

  static MessageThread? fromJson(Map<String, dynamic> j) {
    final time = _time(j["lastTime"]);
    final number = _text(j["number"]);
    if (time == null || number.isEmpty) return null;
    return MessageThread(
      number: number,
      name: _nameOrNull(j["name"]),
      lastTime: time,
      lastText: _text(j["lastText"]),
      lastDirection:
          MessageDirection.values.where((d) => d.name == j["lastDirection"]).firstOrNull ?? MessageDirection.received,
      messageCount: (j["messageCount"] as num?)?.toInt() ?? 0,
      emergencyContact: j["emergencyContact"] == true,
    );
  }
}

class MessageEntry {
  MessageEntry({
    required this.id,
    required this.time,
    required this.direction,
    required this.text,
    this.mms = false,
    this.attachments = 0,
  });

  final String id;
  final DateTime time; // UTC
  final MessageDirection direction;
  final String text;
  final bool mms;
  final int attachments;

  static MessageEntry? fromJson(Map<String, dynamic> j) {
    final time = _time(j["time"]);
    final direction = MessageDirection.values.where((d) => d.name == j["direction"]).firstOrNull;
    if (time == null || direction == null) return null;
    return MessageEntry(
      id: _text(j["id"]),
      time: time,
      direction: direction,
      text: _text(j["text"]),
      mms: j["kind"] == "mms",
      attachments: (j["attachments"] as num?)?.toInt() ?? 0,
    );
  }
}

/// A list the phone reported, and whether it reports this kind of history at all.
class CommsPage<T> {
  CommsPage({required this.items, this.enabled = true});
  final List<T> items;

  /// False when the child's phone isn't sending this history (older software, permission not granted).
  final bool enabled;

  static CommsPage<T> fromJson<T>(Map<String, dynamic>? data, T? Function(Map<String, dynamic>) item) {
    final list = <T>[];
    for (final raw in (data?["items"] as List? ?? const [])) {
      if (raw is Map) {
        final parsed = item(Map<String, dynamic>.from(raw));
        if (parsed != null) list.add(parsed);
      }
    }
    final coverage = data?["coverage"];
    return CommsPage(items: list, enabled: coverage is Map ? coverage["enabled"] != false : true);
  }
}

class EmergencyContact {
  EmergencyContact({this.id, required this.name, required this.number});
  final String? id;
  final String name;
  final String number;

  Map<String, dynamic> toJson() => {"name": name, "number": number};

  static EmergencyContact? fromJson(Map<String, dynamic> j) {
    final name = _text(j["name"]);
    final number = _text(j["number"]);
    if (number.isEmpty) return null;
    return EmergencyContact(id: _nameOrNull(j["id"]), name: name.isEmpty ? number : name, number: number);
  }
}

class EmergencySettings {
  EmergencySettings({this.emergencyOnly = false, this.contacts = const [], this.notApplied});
  final bool emergencyOnly;
  final List<EmergencyContact> contacts;

  /// Why the child's phone can't follow "Emergency contacts only" yet, or null.
  final String? notApplied;

  static EmergencySettings fromJson(Map<String, dynamic>? data) => EmergencySettings(
        emergencyOnly: data?["emergencyOnly"] == true,
        contacts: [
          for (final raw in (data?["contacts"] as List? ?? const []))
            if (raw is Map) EmergencyContact.fromJson(Map<String, dynamic>.from(raw)),
        ].whereType<EmergencyContact>().toList(),
        notApplied: _nameOrNull(data?["notApplied"]),
      );
}

/// The digits of a phone number, without a leading 1 for US numbers, so "(212) 555-0199" and
/// "+1 212 555 0199" compare equal.
String phoneDigits(String number) {
  final digits = number.replaceAll(RegExp(r"\D"), "");
  return digits.length == 11 && digits.startsWith("1") ? digits.substring(1) : digits;
}

bool samePhoneNumber(String a, String b) {
  final x = phoneDigits(a), y = phoneDigits(b);
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  // One may have a country code the other lacks: compare the last 10 digits when both have that many.
  return x.length >= 10 && y.length >= 10 && x.substring(x.length - 10) == y.substring(y.length - 10);
}

/// The MDM refuses longer names and numbers (422).
const maxContactNameLength = 100;
const maxPhoneLength = 32;

/// Why [number] can't be an emergency contact, or null when it can.
String? phoneProblem(String number) {
  final trimmed = number.trim();
  if (trimmed.isEmpty) return "Enter a phone number.";
  if (trimmed.length > maxPhoneLength) return "That number is too long.";
  if (!RegExp(r"^\+?[\d\s().-]+$").hasMatch(trimmed)) return "Use only digits, spaces, +, (, ) and -.";
  final digits = trimmed.replaceAll(RegExp(r"\D"), "").length;
  if (digits < 3 || digits > 15) return "Enter a full phone number.";
  return null;
}

/// "45 s", "3 min 12 s", "1 h 5 min".
String formatCallDuration(int seconds) {
  if (seconds < 60) return "$seconds s";
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  if (h > 0) return m == 0 ? "$h h" : "$h h $m min";
  return s == 0 ? "$m min" : "$m min $s s";
}

const _weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/// "Today", "Yesterday", or "Mon, Nov 23" for [day] seen from [today] (both on the same clock).
String dayLabel(DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return "Today";
  if (diff == 1) return "Yesterday";
  final label = "${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}";
  return d.year == t.year ? label : "$label, ${d.year}";
}
