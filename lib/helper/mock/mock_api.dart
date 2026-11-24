import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/sharedHelper.dart';

/// Debug-only mock backend, for testing the app without real accounts or devices.
///
/// Log in with [demoEmail] (any password) in a debug build and every api2 and MDM request is answered here
/// instead of going to the network, until logout. Release builds never enable it: every entry point checks
/// the compile-time constant `kDebugMode`.
///
/// State (blocked apps, URLs, toggles, plan, linked devices) lives in memory, so actions show their result
/// on the next load, and resets when the app restarts.
class MockApi {
  MockApi._();

  static const demoEmail = "demo@moolah.test";

  static SharedPrefValue<bool> get _mockMode => SharedPrefValue<bool>('mock_mode');

  static bool get enabled {
    if (!kDebugMode) return false;
    try {
      return _mockMode.get();
    } catch (_) {
      return false; // Prefs not initialised, e.g. in tests.
    }
  }

  /// Turns mock mode on when [url] is the login (or sign-up) call for [demoEmail].
  static void enableIfDemoLogin(String url, Map<String, dynamic> body) {
    if (!kDebugMode) return;
    final email = body["email"]?.toString().trim().toLowerCase();
    if (email == demoEmail && (url == EndPoints.login || url == EndPoints.signUp)) {
      _mockMode.set(true);
      debugPrint("🧪 [MOCK] Mock mode ON for $demoEmail. All API calls are answered locally.");
    }
  }

  static void disable() {
    try {
      _mockMode.clear();
    } catch (_) {}
    _state = null;
  }

  static _MockState? _state;
  static _MockState get _s => _state ??= _MockState();

  /// Answers [method] [url] with a mock response, after a short delay so loaders show.
  static Future<ResponseModel> handle(String method, String url, [Map<String, dynamic> body = const {}]) async {
    await Future.delayed(Duration(milliseconds: 250 + Random().nextInt(300)));
    final uri = Uri.parse(url);
    final isMdm = url.startsWith(EndPoints.mdmBaseUrl);
    final path = isMdm ? uri.path.replaceFirst(Uri.parse(EndPoints.mdmBaseUrl).path, "") : uri.path;
    final q = uri.queryParameters;

    final Map<String, dynamic>? res = isMdm ? _mdm(path, q, body) : _api2(path, q, body);
    debugPrint("🧪 [MOCK] $method ${isMdm ? "MDM" : "api2"} $path → ${res == null ? "no handler, generic success" : "ok"}");
    final data = res ?? {"success": true, "msg": "Mock: no handler for $path"};
    final ok = data["success"] != false;
    return ResponseModel(
      isSuccessful: ok,
      data: data,
      // Most screens toast `message` after an action, so only set it where a toast makes sense.
      message: data["msg"]?.toString() ?? (ok ? null : "Mock error"),
    );
  }

  // --- api2 ---------------------------------------------------------------------------------------------

  static Map<String, dynamic>? _api2(String path, Map<String, String> q, Map<String, dynamic> body) {
    final s = _s;
    switch (path) {
      case "/guardian/login":
      case "/guardian/register":
        return {
          "success": true,
          "msg": "Logged in to mock account",
          "data": s.user,
          "tokens": {
            "access": {"token": "mock-access-token"},
            "refresh": {"token": "mock-refresh-token"},
          },
        };
      case "/refreshTokens":
        return {
          "success": true,
          "access": {"token": "mock-access-token"},
          "refresh": {"token": "mock-refresh-token"},
        };
      case "/guardian/send-otp":
        return {"success": true, "msg": "Mock OTP sent (any code works)"};
      case "/guardian/verify-otp":
        return {"success": true, "msg": "Phone verified"};
      case "/guardian/forgot-password":
        return {"success": true, "msg": "Mock reset code sent (any code works)"};
      case "/guardian/reset-password":
        return {"success": true, "msg": "Password reset"};

      case "/getConnectedKidDevices":
        return {
          "success": true,
          "devices": [
            for (final d in s.devices)
              {
                "kidDeviceAccountConnectID": d.connectId,
                "kidDeviceAccountUserID": d.kidUserId,
                "kidFullName": d.kidName,
              }
          ],
        };
      case "/linkKidByConnectCode":
        final d = s.addDevice(code: body["code"]?.toString() ?? "");
        return {
          "success": true,
          "msg": "Device linked",
          "data": {
            "kidDeviceAccountConnectID": d.connectId,
            "kidDeviceAccountUserID": d.kidUserId,
            "deviceId": d.deviceId,
          },
        };

      case "/unpairKidDevice":
        s.devices.removeWhere((d) => d.connectId == body["kidDeviceAccountConnectID"]?.toString());
        return {"success": true, "msg": "Device unpaired"};

      case "/getMSMSMonitoringStatus":
        return {"success": true, "msmsMonitoringStatus": s.msmsMonitoring};
      case "/enableMSMSMonitoring":
        s.msmsMonitoring = body["msmsMonitoringStatus"]?.toString() == "true";
        return {"success": true, "msg": "Message monitoring ${s.msmsMonitoring ? "enabled" : "disabled"}"};
      case "/getWalletEnabled":
        return {"success": true, "walletEnabled": s.walletEnabled};
      case "/enableWallet":
        s.walletEnabled = body["walletEnabled"]?.toString() == "true";
        return {"success": true, "msg": "Wallet ${s.walletEnabled ? "enabled" : "disabled"}"};

      case "/getBlockedUrlsEncryption":
        final kidUserId = body["kidDeviceAccountUserID"]?.toString() ?? "";
        return {
          "success": true,
          "blocked_urls_data": {
            "kid_device_uid": kidUserId,
            "parent_device_uid": s.user["id"].toString(),
            "blockedUrls": List<String>.from(s.blockedUrls[kidUserId] ?? []),
          },
        };
      case "/addBlockedUrl":
        final kidUserId = body["kidDeviceAccountUserID"]?.toString() ?? "";
        final urls = (body["urls"] as List? ?? []).map((u) => u.toString());
        (s.blockedUrls[kidUserId] ??= []).addAll(urls);
        return {"success": true, "msg": "URL blocked"};
      case "/blacklistUrl":
        return {"success": true, "msg": "URL blocked"};

      case "/getDeviceThreadsEncryption":
      case "/getThreadMessagesEncryption":
        return {"success": true, "data": []};
      case "/parentAppSecurityCheck":
        return {"success": true};
      case "/getBannerAds":
        return {"success": true, "campaigns": [], "adValue": "0"};
      case "/submitReview":
        return {"success": true, "msg": "Thanks for your review"};
      case "/feedback":
        return {"success": true, "msg": "Thanks for your feedback"};

      case "/guardian/plans":
        return {
          "success": true,
          "plans": [
            {"code": "basic", "price": 3.99},
            {"code": "premium", "price": 8.99},
            {"code": "ultimate", "price": 19.99},
          ],
        };
      case "/guardian/subscription":
        return {
          "success": true,
          "subscription": {
            "plan": s.plan,
            "status": "active",
            "currentPeriodEnd": DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
            "cancelAtPeriodEnd": false,
          },
        };
    }

    // /guardian/orders/{plan} and /guardian/orders/{orderId}/confirm
    final confirm = RegExp(r"^/guardian/orders/(.+)/confirm$").firstMatch(path);
    if (confirm != null) {
      final orderId = Uri.decodeComponent(confirm.group(1)!);
      final plan = s.orders.remove(orderId);
      if (plan != null) s.plan = plan;
      return {"success": true, "msg": "Order confirmed"};
    }
    final order = RegExp(r"^/guardian/orders/([^/]+)$").firstMatch(path);
    if (order != null) {
      final plan = order.group(1)!;
      if (plan == s.plan) return {"success": true, "alreadySubscribed": true, "orderId": "mock-order-existing"};
      final orderId = "mock-order-${s.nextId()}";
      s.orders[orderId] = plan;
      // No clientSecret: nothing to pay, so the app skips the Stripe sheet and confirms straight away.
      return {"success": true, "orderId": orderId};
    }
    return null;
  }

  // --- MDM ----------------------------------------------------------------------------------------------

  static Map<String, dynamic>? _mdm(String path, Map<String, String> q, Map<String, dynamic> body) {
    final s = _s;
    final connectId = q["kidDeviceAccountConnectID"] ?? body["kidDeviceAccountConnectID"]?.toString();
    final deviceId = q["deviceId"] ?? body["deviceId"]?.toString();
    final d = s.find(connectId: connectId, deviceId: deviceId);
    Map<String, dynamic> notFound() =>
        {"success": false, "error": {"message": "Mock: no device for ${connectId ?? deviceId}"}};

    switch (path) {
      case "/guardian/provision":
        return {"success": true, "data": {"parentId": "mock-parent-${s.user["id"]}"}};
      case "/guardian/link":
        return {"success": true, "data": {"connectId": body["kidDeviceAccountConnectID"]}};

      case "/getConnectedKidDevices":
        if (d == null) return notFound();
        return {"success": true, "data": {"devices": [d.summary()]}};
      case "/getSingleDeviceDetail":
        if (d == null) return notFound();
        return {"success": true, "data": d.summary()};
      case "/getDeviceDetails":
        if (d == null) return notFound();
        return {
          "success": true,
          "deviceId": d.deviceId,
          "kidDeviceAccountConnectID": d.connectId,
          "data": {
            ...d.summary(),
            "apps": d.apps,
            "usage": d.usage(),
            "location": d.location(),
          },
        };
      case "/getDeviceLocation":
        if (d == null) return notFound();
        return {"success": true, "data": d.location()};

      case "/getInstalledApps":
        if (d == null) return notFound();
        return {"success": true, "data": {"apps": d.apps}};
      case "/getDeviceRestrictions":
        if (d == null) return notFound();
        return {"success": true, "data": {"rules": d.rules}};
      case "/setDeviceRestrictions":
        if (d == null) return notFound();
        d.rules = (body["rules"] as List? ?? []).map((r) => Map<String, dynamic>.from(r as Map)).toList();
        return {"success": true, "msg": "Restrictions saved", "data": {"commandId": "mock-cmd-${s.nextId()}"}};

      case "/deleteApp":
        if (d == null) return notFound();
        final pkg = body["pkg"]?.toString() ?? "";
        final commandId = "mock-cmd-${s.nextId()}";
        s.commands[commandId] = _Command(d, "deleteApp", pkg);
        return {"success": true, "data": {"commandId": commandId, "status": "queued"}};
      case "/getCommandStatus":
        final cmd = s.commands.remove(q["commandId"]);
        if (cmd == null) return {"success": true, "data": {"status": "done"}};
        if (cmd.type == "deleteApp") cmd.device.apps.removeWhere((a) => a["pkg"] == cmd.pkg);
        return {"success": true, "data": {"status": "done"}};
      case "/getPendingCommands":
        if (d == null) return notFound();
        return {
          "success": true,
          "data": {
            "commands": [
              for (final e in s.commands.entries)
                if (e.value.device == d) {"commandId": e.key, "type": e.value.type, "pkg": e.value.pkg, "status": "queued"}
            ],
          },
        };

      case "/sendActionToDevice":
        return {"success": true, "data": {"commandId": "mock-cmd-${s.nextId()}", "status": "queued"}};
      case "/wipeDevice":
        return {"success": true, "data": {"cancellable": true}};
      case "/cancelWipe":
        return {"success": true};

      case "/getNetworkHistory":
        if (d == null) return notFound();
        return {"success": true, "data": d.networkHistory()};

      // Unpairing removes the device in api2 first, so the MDM link may already be gone here.
      case "/guardian/unlink":
        return {
          "success": true,
          "data": {"status": "unlinked", "otherParentsLinked": 0, "rulesCleared": true, "commandId": null},
        };

      case "/getCallLog":
        if (d == null) return notFound();
        return {"success": true, "data": {"items": d.callLog(), "coverage": {"enabled": true}}};
      case "/getMessageThreads":
        if (d == null) return notFound();
        return {"success": true, "data": {"items": d.messageThreads(), "coverage": {"enabled": true}}};
      case "/getMessages":
        if (d == null) return notFound();
        return {"success": true, "data": {"items": d.messagesWith(q["number"] ?? "")}};
      case "/getEmergencyContacts":
        if (d == null) return notFound();
        return {"success": true, "data": d.emergency()};
      case "/setEmergencyContacts":
        if (d == null) return notFound();
        final contacts = [
          for (final c in (body["contacts"] as List? ?? []))
            if (c is Map) {"id": "ec-${s.nextId()}", "name": "${c["name"]}", "number": "${c["number"]}"}
        ];
        final only = body["emergencyOnly"] == true;
        if (contacts.length > 5) return {"success": false, "msg": "Up to 5 emergency contacts."};
        if (only && contacts.isEmpty) {
          return {"success": false, "msg": "Add an emergency contact before turning this on."};
        }
        d.emergencyContacts = contacts;
        d.emergencyOnly = only;
        return {"success": true, "data": {...d.emergency(), "commandId": "mock-cmd-${s.nextId()}"}};
    }
    return null;
  }
}

class _Command {
  _Command(this.device, this.type, this.pkg);
  final _MockDevice device;
  final String type;
  final String pkg;
}

class _MockState {
  int _id = 100;
  String nextId() => "${++_id}";

  final Map<String, dynamic> user = {
    "id": 9001,
    "first_name": "Demo",
    "last_name": "Parent",
    "username": "demoparent",
    "email": MockApi.demoEmail,
    "phone": "+15555550100",
    "dob": "1985-04-12",
  };

  /// Starts on Ultimate so every feature is unlocked; subscribing to another plan switches to it.
  String plan = "ultimate";
  final Map<String, String> orders = {};
  bool msmsMonitoring = false;
  bool walletEnabled = true;
  final Map<String, List<String>> blockedUrls = {
    "kid-user-1": ["badsite.example", "casino.example"],
  };
  final Map<String, _Command> commands = {};

  late final List<_MockDevice> devices = [
    _MockDevice(
      deviceId: "350000000000001",
      connectId: "MOCK-CONNECT-1",
      kidUserId: "kid-user-1",
      kidName: "Emma",
      model: "Moolah Tab 8",
      osVersion: "14",
      batteryPct: 78,
      online: true,
      lastSeen: const Duration(minutes: 2),
      lat: 40.7580,
      lng: -73.9855,
      blocked: ["com.zhiliaoapp.musically"],
    ),
    _MockDevice(
      deviceId: "350000000000002",
      connectId: "MOCK-CONNECT-2",
      kidUserId: "kid-user-2",
      kidName: "Liam",
      model: "Moolah Phone X",
      osVersion: "13",
      batteryPct: 23,
      online: false,
      lastSeen: const Duration(hours: 5),
      lat: 40.7484,
      lng: -73.9857,
    ),
  ];

  _MockDevice addDevice({required String code}) {
    final n = nextId();
    final d = _MockDevice(
      deviceId: "3500000000$n",
      connectId: "MOCK-CONNECT-$n",
      kidUserId: "kid-user-$n",
      kidName: "New device ${code.isEmpty ? n : code}",
      model: "Moolah Tab 8",
      osVersion: "14",
      batteryPct: 100,
      online: true,
      lastSeen: Duration.zero,
      lat: 40.7128,
      lng: -74.0060,
    );
    devices.add(d);
    return d;
  }

  _MockDevice? find({String? connectId, String? deviceId}) {
    for (final d in devices) {
      if ((connectId != null && d.connectId == connectId) || (deviceId != null && d.deviceId == deviceId)) return d;
    }
    return null;
  }
}

class _MockDevice {
  _MockDevice({
    required this.deviceId,
    required this.connectId,
    required this.kidUserId,
    required this.kidName,
    required this.model,
    required this.osVersion,
    required this.batteryPct,
    required this.online,
    required this.lastSeen,
    required this.lat,
    required this.lng,
    List<String> blocked = const [],
  }) {
    if (blocked.isNotEmpty) {
      rules = [
        {"id": "always-off", "type": "time", "packages": blocked, "from": "00:00", "to": "23:59"},
        {"id": "always-off-last-minute", "type": "time", "packages": blocked, "from": "23:59", "to": "00:00"},
      ];
    }
  }

  final String deviceId;
  final String connectId;
  final String kidUserId;
  final String kidName;
  final String model;
  final String osVersion;
  final int batteryPct;
  final bool online;
  final Duration lastSeen;
  final double lat;
  final double lng;
  List<Map<String, dynamic>> rules = [];

  bool emergencyOnly = false;
  List<Map<String, dynamic>> emergencyContacts = [
    {"id": "ec-1", "name": "Mom", "number": "+12125550147"},
  ];

  Map<String, dynamic> emergency() => {
        "emergencyOnly": emergencyOnly,
        "contacts": emergencyContacts,
        "maxContacts": 5,
        "notApplied": null,
      };

  bool _isEmergency(String number) {
    String digits(String n) {
      final x = n.replaceAll(RegExp(r"\D"), "");
      return x.length > 10 ? x.substring(x.length - 10) : x;
    }

    return emergencyContacts.any((c) => digits("${c["number"]}") == digits(number));
  }

  static String _ago(Duration d) => DateTime.now().toUtc().subtract(d).toIso8601String();

  // Sample calls and texts, relative to now, so "Today" and "Yesterday" always have something.
  static const _people = [
    ("+12125550147", "Mom"),
    ("+12125550199", "Dad"),
    ("+13475550123", "Jake"),
    ("+16465550188", null),
  ];

  List<Map<String, dynamic>> callLog() {
    Map<String, dynamic> call(int i, Duration ago, String direction, (String, String?) who, int secs) => {
          "id": "c-$i",
          "time": _ago(ago),
          "direction": direction,
          "number": who.$1,
          "name": who.$2,
          "durationSec": secs,
          "emergencyContact": _isEmergency(who.$1),
        };
    return [
      call(1, const Duration(minutes: 25), "incoming", _people[0], 192),
      call(2, const Duration(hours: 2, minutes: 10), "outgoing", _people[2], 534),
      call(3, const Duration(hours: 3), emergencyOnly ? "blocked" : "missed", _people[3], 0),
      call(4, const Duration(hours: 20), "outgoing", _people[1], 61),
      call(5, const Duration(days: 1, hours: 4), "rejected", _people[2], 0),
      call(6, const Duration(days: 3), "incoming", _people[0], 1260),
    ];
  }

  List<(Duration, String, String)> _conversation(String number) {
    switch (number) {
      case "+12125550147":
        return [
          (const Duration(minutes: 40), "received", "On my way, 10 minutes"),
          (const Duration(minutes: 42), "sent", "Where are you?"),
          (const Duration(hours: 5), "received", "Don't forget your lunch"),
        ];
      case "+13475550123":
        return [
          (const Duration(hours: 1), "sent", "ok see you at practice"),
          (const Duration(hours: 1, minutes: 3), "received", "you coming to practice?"),
        ];
      case "+16465550188":
        return [
          (const Duration(hours: 26), emergencyOnly ? "blocked" : "received", "Claim your free prize now!"),
        ];
    }
    return [];
  }

  List<Map<String, dynamic>> messageThreads() => [
        for (final who in [_people[0], _people[2], _people[3]])
          if (_conversation(who.$1).isNotEmpty)
            {
              "number": who.$1,
              "name": who.$2,
              "lastTime": _ago(_conversation(who.$1).first.$1),
              "lastText": _conversation(who.$1).first.$3,
              "lastDirection": _conversation(who.$1).first.$2,
              "messageCount": _conversation(who.$1).length,
              "emergencyContact": _isEmergency(who.$1),
            }
      ];

  List<Map<String, dynamic>> messagesWith(String number) => [
        for (final (i, m) in _conversation(number).indexed)
          {"id": "m-$i", "time": _ago(m.$1), "direction": m.$2, "text": m.$3, "kind": "sms", "attachments": 0}
      ];

  static const _min = 60 * 1000;

  final List<Map<String, dynamic>> apps = [
    _app("com.google.android.youtube", "YouTube", 95 * _min),
    _app("com.zhiliaoapp.musically", "TikTok", 62 * _min),
    _app("com.roblox.client", "Roblox", 48 * _min),
    _app("com.instagram.android", "Instagram", 31 * _min),
    _app("com.whatsapp", "WhatsApp", 22 * _min),
    _app("com.spotify.music", "Spotify", 18 * _min),
    _app("com.duolingo", "Duolingo", 12 * _min),
    _app("com.mojang.minecraftpe", "Minecraft", 9 * _min),
    _app("com.netflix.mediaclient", "Netflix", 0),
    _app("org.khanacademy.android", "Khan Academy", 25 * _min),
    // Hidden from the Apps tab: system and Moolah's own apps.
    _app("com.android.settings", "Settings", 2 * _min, system: true, removable: false),
    _app("com.android.chrome", "Chrome", 14 * _min, system: true, removable: false),
    _app("com.moolahmobile.wallet", "Moolah Wallet", 3 * _min, removable: false),
  ];

  static Map<String, dynamic> _app(String pkg, String name, int usageMs, {bool system = false, bool removable = true}) => {
        "pkg": pkg,
        "name": name,
        "version": "1.0.0",
        "usageTodayMs": usageMs,
        "system": system,
        "launchable": true,
        "removable": removable,
        "state": "active",
      };

  String get _lastSeenAt => DateTime.now().toUtc().subtract(lastSeen).toIso8601String();

  Map<String, dynamic> summary() => {
        "deviceId": deviceId,
        "kidDeviceAccountConnectID": connectId,
        "label": kidName,
        "model": model,
        "osVersion": osVersion,
        "online": online,
        "batteryPct": batteryPct,
        "lastSeenAt": _lastSeenAt,
      };

  Map<String, dynamic> usage() {
    final today = apps.fold<int>(0, (sum, a) => sum + (a["usageTodayMs"] as int));
    return {
      "todayMs": today,
      "weekMs": today * 6,
      "prevWeekMs": today * 7,
      "dailyAvgMs": (today * 6) ~/ 7,
      "weekTrendPct": -14,
    };
  }

  Map<String, dynamic> location() => {
        "lat": lat,
        "lng": lng,
        "capturedAt": _lastSeenAt,
      };

  Map<String, dynamic> networkHistory() {
    final now = DateTime.now().toUtc();
    const visits = [
      ["youtube.com", "com.android.chrome", "Chrome", 5],
      ["wikipedia.org", "com.android.chrome", "Chrome", 18],
      ["khanacademy.org", "com.android.chrome", "Chrome", 40],
      ["roblox.com", "com.roblox.client", "Roblox", 65],
      ["minecraft.net", "com.android.chrome", "Chrome", 90],
      ["nationalgeographic.com", "com.android.chrome", "Chrome", 130],
      ["coolmathgames.com", "com.android.chrome", "Chrome", 200],
      ["spotify.com", "com.spotify.music", "Spotify", 260],
    ];
    final items = [
      for (final v in visits)
        {
          "time": now.subtract(Duration(minutes: v[3] as int)).toIso8601String(),
          "domain": v[0],
          "app": {"pkg": v[1], "name": v[2]},
        }
    ];
    return {
      "websites": {"items": items, "total": items.length},
      "dataUsage": [
        {"pkg": "com.google.android.youtube", "rxBytes": 820000000, "txBytes": 31000000},
        {"pkg": "com.zhiliaoapp.musically", "rxBytes": 410000000, "txBytes": 22000000},
        {"pkg": "com.roblox.client", "rxBytes": 150000000, "txBytes": 40000000},
      ],
      "networkLoggingEnabled": true,
      "vpnActive": false,
      "lastHistoryUploadAt": now.subtract(const Duration(minutes: 3)).toIso8601String(),
      "unmanagedBrowsers": [],
    };
  }
}
