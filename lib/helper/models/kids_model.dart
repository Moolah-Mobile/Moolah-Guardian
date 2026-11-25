import 'dart:convert';
import 'package:moolah/helper/models/thread_model.dart';
import 'app_usage_model.dart';
import 'blocked_url_model.dart';
import 'device_detail_model.dart';
import 'network_history_model.dart';

Kid kidFromJson(String str) => Kid.fromJson(json.decode(str));

String kidToJson(Kid data) => json.encode(data.toJson());

class Kid {
  String? kidId;
  // api2's child ID (kidDeviceAccountUserID); kidId holds the MDM device number.
  String? kidUserId;
  List<App> installedApps = [];
  // Packages in the device's "always-off" MDM rule.
  Set<String> blockedPackages = {};
  // Packages with an uninstall sent to the device that it hasn't finished yet.
  Set<String> pendingUninstalls = {};
  // Names of every app seen on the device, kept after an app stops being reported.
  Map<String, String> appNames = {};
  NetworkHistory? networkHistory;
  // Bytes the device sent and received over the MDM's network-history window (the last 7 days); null until loaded.
  int? dataUsageBytes;
  String? name;
  String? deviceType;
  String? batteryStatus;
  String? privateKey;
  String? connectId;
  String? dataUsageStatus;
  String? lastActive;
  String? kidPic;
  bool? walletEnabled;
  AppUsage? appUsage;
  DeviceDetail? deviceDetail;
  bool? msmsMonitoringStatus;
  List<ThreadModel> threads;
  BlockedUrlModel? blockedUrls;
  DeviceDetail? deviceData;

  Kid({
    this.kidId,
    this.name,
    this.deviceType,
    this.batteryStatus,
    this.privateKey,
    this.connectId,
    this.dataUsageStatus,
    this.lastActive,
    this.kidPic,
    this.walletEnabled,
    this.appUsage,
    this.deviceDetail,
    this.threads = const [],
    this.blockedUrls,
    this.deviceData,
    this.msmsMonitoringStatus,
  });

  Kid copyWith({
    String? kidId,
    String? name,
    String? deviceType,
    String? batteryStatus,
    String? privateKey,
    String? connectId,
    String? dataUsageStatus,
    String? lastActive,
    String? kidPic,
    bool? walletEnabled,
    AppUsage? appUsage,
    DeviceDetail? deviceDetail,
    List<ThreadModel>? threads,
    BlockedUrlModel? blockedUrls,
    DeviceDetail? deviceData,
    bool? msmsMonitoringStatus,
  }) =>
      Kid(
        kidId: kidId ?? this.kidId,
        name: name ?? this.name,
        deviceType: deviceType ?? this.deviceType,
        batteryStatus: batteryStatus ?? this.batteryStatus,
        privateKey: privateKey ?? this.privateKey,
        connectId: connectId ?? this.connectId,
        dataUsageStatus: dataUsageStatus ?? this.dataUsageStatus,
        lastActive: lastActive ?? this.lastActive,
        kidPic: kidPic ?? this.kidPic,
        walletEnabled: walletEnabled ?? this.walletEnabled,
        appUsage: appUsage ?? this.appUsage,
        deviceDetail: deviceDetail ?? this.deviceDetail,
        threads: threads ?? this.threads,
        blockedUrls: blockedUrls ?? this.blockedUrls,
        deviceData: deviceData ?? this.deviceData,
        msmsMonitoringStatus: msmsMonitoringStatus ?? this.msmsMonitoringStatus,
      );

  factory Kid.fromJson(Map<String, dynamic> json) {
    return Kid(
      kidId: (json["deviceId"] ?? json["kidID"])?.toString(),
      name: json["label"] ?? json["name"] ?? json["model"] ?? "Device",
      deviceType: json["model"] ?? json["deviceType"],
      batteryStatus: (json["batteryPct"] ?? json["batteryStatus"])?.toString() ?? "0",
      connectId: (json["kidDeviceAccountConnectID"] ?? json["connectID"])?.toString(),
      dataUsageStatus: json["dataUsageStatus"]?.toString() ?? "0",
      lastActive: lastSeenText(json["lastSeenAt"]?.toString()) ?? json["lastActive"]?.toString(),
      kidPic: json["kidPic"],
      walletEnabled: json["walletEnabled"] ?? false,
      msmsMonitoringStatus: json["msmsMonitoringStatus"] ?? false,
    );
  }

  /// The MDM's `lastSeenAt` (UTC, ISO-8601) as "Just now", "5m ago", "3h ago" or "2d ago"; null if unreadable.
  static String? lastSeenText(String? lastSeenAt) {
    final seen = DateTime.tryParse(lastSeenAt ?? "");
    if (seen == null) return null;
    final diff = DateTime.now().toUtc().difference(seen.toUtc());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Map<String, dynamic> toJson() => {
        "kidID": kidId,
        "name": name,
        "deviceType": deviceType,
        "batteryStatus": batteryStatus,
        "connectID": connectId,
        "dataUsageStatus": dataUsageStatus,
        "lastActive": lastActive,
        "kidPic": kidPic,
        "walletEnabled": walletEnabled,
        "deviceDetail": deviceDetail?.toJson(),
        "deviceData": deviceData?.toJson(),
        "msmsMonitoringStatus": msmsMonitoringStatus,
      };
}
