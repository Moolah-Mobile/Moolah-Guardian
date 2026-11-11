import 'dart:convert';
import 'package:moolah/helper/models/thread_model.dart';
import 'app_usage_model.dart';
import 'blocked_url_model.dart';
import 'device_detail_model.dart';

Kid kidFromJson(String str) => Kid.fromJson(json.decode(str));

String kidToJson(Kid data) => json.encode(data.toJson());

class Kid {
  String? kidId;
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
      lastActive: json["lastSeenAt"] ?? json["lastActive"],
      kidPic: json["kidPic"],
      walletEnabled: json["walletEnabled"] ?? false,
      msmsMonitoringStatus: json["msmsMonitoringStatus"] ?? false,
    );
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
