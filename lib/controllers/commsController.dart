import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/repo/commsRepo.dart';

/// One thing loaded from the MDM for a device: the value, or why it couldn't be loaded.
class CommsLoad<T> {
  T? value;
  bool loading = false;

  /// The MDM (or the child's phone) doesn't offer this yet.
  bool unavailable = false;
  String? error;
  DateTime? loadedAt;
}

/// Calls, messages and emergency contacts for each child device, kept by its connect ID.
class CommsController extends GetxController {
  final _calls = <String, CommsLoad<CommsPage<CallEntry>>>{};
  final _threads = <String, CommsLoad<CommsPage<MessageThread>>>{};
  final _messages = <String, CommsLoad<CommsPage<MessageEntry>>>{};
  final _emergency = <String, CommsLoad<EmergencySettings>>{};

  String _key(String kidId) {
    try {
      return Get.find<HomeController>().connectIdFor(kidId) ?? kidId;
    } catch (_) {
      return kidId;
    }
  }

  static String _threadKey(String key, String number) => "$key|${phoneDigits(number)}";

  CommsLoad<CommsPage<CallEntry>> calls(String kidId) => _calls.putIfAbsent(_key(kidId), CommsLoad.new);
  CommsLoad<CommsPage<MessageThread>> threads(String kidId) => _threads.putIfAbsent(_key(kidId), CommsLoad.new);
  CommsLoad<CommsPage<MessageEntry>> messages(String kidId, String number) =>
      _messages.putIfAbsent(_threadKey(_key(kidId), number), CommsLoad.new);
  CommsLoad<EmergencySettings> emergency(String kidId) => _emergency.putIfAbsent(_key(kidId), CommsLoad.new);

  /// A missing endpoint answers with a bare 404 ("Error 404"), or a body that isn't the API's JSON.
  static bool isUnavailable(ResponseModel res) {
    final m = res.message ?? "";
    return m.startsWith("Error 404") || m.startsWith("Error 405") || m.startsWith("Parse Error");
  }

  static String errorText(ResponseModel res) {
    final m = res.message ?? "";
    if (m == "Network Error") return "No internet connection. Check it and try again.";
    return m.isEmpty ? "Couldn't load this. Try again." : m;
  }

  Future<void> _load<T>(CommsLoad<T> load, Future<ResponseModel> Function() fetch,
      T Function(Map<String, dynamic>? data) parse, bool force) async {
    if (load.loading) return;
    if (!force && load.loadedAt != null && DateTime.now().difference(load.loadedAt!) < const Duration(seconds: 30)) {
      return;
    }
    load.loading = true;
    update();
    final res = await fetch();
    load.loading = false;
    load.loadedAt = DateTime.now();
    if (res.isSuccessful) {
      final data = res.data is Map ? res.data["data"] : null;
      load.value = parse(data is Map ? Map<String, dynamic>.from(data) : null);
      load.unavailable = false;
      load.error = null;
    } else {
      load.unavailable = isUnavailable(res);
      load.error = load.unavailable ? null : errorText(res);
    }
    update();
  }

  Future<void> loadCalls(String kidId, {bool force = false}) {
    final key = _key(kidId);
    return _load(calls(kidId), () => CommsRepo.getCallLog(key), (d) => CommsPage.fromJson(d, CallEntry.fromJson), force);
  }

  Future<void> loadThreads(String kidId, {bool force = false}) {
    final key = _key(kidId);
    return _load(
        threads(kidId), () => CommsRepo.getMessageThreads(key), (d) => CommsPage.fromJson(d, MessageThread.fromJson), force);
  }

  Future<void> loadMessages(String kidId, String number, {bool force = false}) {
    final key = _key(kidId);
    return _load(messages(kidId, number), () => CommsRepo.getMessages(key, number),
        (d) => CommsPage.fromJson(d, MessageEntry.fromJson), force);
  }

  Future<void> loadEmergency(String kidId, {bool force = false}) {
    final key = _key(kidId);
    return _load(emergency(kidId), () => CommsRepo.getEmergencyContacts(key), EmergencySettings.fromJson, force);
  }

  /// Sends the whole emergency list and switch to the child's phone. Returns an error message, or null once
  /// the MDM has them.
  Future<String?> saveEmergency(String kidId,
      {required bool emergencyOnly, required List<EmergencyContact> contacts}) async {
    final key = _key(kidId);
    final res =
        await CommsRepo.setEmergencyContacts(connectId: key, emergencyOnly: emergencyOnly, contacts: contacts);
    if (!res.isSuccessful) {
      if (isUnavailable(res)) return "Emergency contacts can't be set on this phone yet.";
      return errorText(res);
    }
    final load = emergency(kidId);
    final data = res.data is Map ? res.data["data"] : null;
    load.value = data is Map
        ? EmergencySettings.fromJson(Map<String, dynamic>.from(data))
        : EmergencySettings(emergencyOnly: emergencyOnly, contacts: contacts);
    load.unavailable = false;
    load.error = null;
    load.loadedAt = DateTime.now();
    update();
    return null;
  }

  /// Drops everything kept for a device, e.g. after unpairing it.
  void forgetDevice(String connectId) {
    _calls.remove(connectId);
    _threads.remove(connectId);
    _emergency.remove(connectId);
    _messages.removeWhere((k, _) => k.startsWith("$connectId|"));
    update();
  }
}
