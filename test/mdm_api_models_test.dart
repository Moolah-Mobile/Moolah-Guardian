import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/helper/models/network_history_model.dart';

void main() {
  group("Kid.lastSeenText", () {
    String ago(Duration d) => DateTime.now().toUtc().subtract(d).toIso8601String();

    test("formats the MDM's UTC lastSeenAt as a short age", () {
      expect(Kid.lastSeenText(ago(const Duration(seconds: 20))), "Just now");
      expect(Kid.lastSeenText(ago(const Duration(minutes: 5))), "5m ago");
      expect(Kid.lastSeenText(ago(const Duration(hours: 3))), "3h ago");
      expect(Kid.lastSeenText(ago(const Duration(days: 2))), "2d ago");
    });

    test("returns null for a missing or unreadable time", () {
      expect(Kid.lastSeenText(null), isNull);
      expect(Kid.lastSeenText("not a date"), isNull);
    });

    test("getConnectedKidDevices rows show the age, not the raw timestamp", () {
      final kid = Kid.fromJson({
        "deviceId": "DEVICE-NUMBER",
        "kidDeviceAccountConnectID": "CONNECT-ID",
        "batteryPct": 82,
        "lastSeenAt": ago(const Duration(minutes: 10)),
      });
      expect(kid.lastActive, "10m ago");
      expect(kid.connectId, "CONNECT-ID");
      expect(kid.batteryStatus, "82");
    });
  });

  group("getNetworkHistory health fields", () {
    Map<String, dynamic> body({List browsers = const [], bool? logging, bool? vpn}) => {
          "websites": {"total": 0, "items": []},
          "dataUsage": [],
          "unmanagedBrowsers": browsers,
          "lastHistoryUploadAt": "2026-11-20T09:30:00Z",
          "networkLoggingEnabled": logging,
          "vpnActive": vpn,
        };

    test("no warning when the history is complete", () {
      final h = NetworkHistory.fromJson(body(logging: true, vpn: false));
      expect(h.gapWarning, isNull);
      expect(h.lastUploadAt, isNotNull);
    });

    test("names browsers that can hide sites", () {
      final h = NetworkHistory.fromJson(body(browsers: [
        {"pkg": "org.mozilla.firefox", "name": "Firefox"}
      ]));
      expect(h.unmanagedBrowsers, ["Firefox"]);
      expect(h.gapWarning, contains("Firefox"));
    });

    test("logging off and VPN on are reported, logging first", () {
      expect(NetworkHistory.fromJson(body(logging: false, vpn: true)).gapWarning, contains("isn't recording"));
      expect(NetworkHistory.fromJson(body(vpn: true)).gapWarning, contains("VPN"));
    });

    test("older agents (fields missing) give no warning", () {
      expect(NetworkHistory.fromJson({"websites": {"items": []}}).gapWarning, isNull);
    });
  });

  test("getInstalledApps app state and getDeviceDetails prevWeekMs are read", () {
    final app = App.fromJson({"pkg": "com.roblox.client", "name": "Roblox", "state": "hidden", "removable": false});
    expect(app.state, "hidden");
    expect(app.removable, isFalse);
    final usage = Usage.fromJson({"todayMs": 5400000, "weekMs": 31200000, "prevWeekMs": 28800000, "weekTrendPct": 8});
    expect(usage.prevWeekMs, 28800000);
  });
}
