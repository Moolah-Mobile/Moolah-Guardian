import 'dart:convert';

DeviceDetail deviceDetailFromJson(String str) => DeviceDetail.fromJson(json.decode(str));
String deviceDetailToJson(DeviceDetail data) => json.encode(data.toJson());

class DeviceDetail {
  bool? success;
  String? message;
  String? deviceId;
  String? kidDeviceAccountConnectID;
  Data? data;

  DeviceDetail({
    this.success,
    this.message,
    this.deviceId,
    this.kidDeviceAccountConnectID,
    this.data,
  });

  factory DeviceDetail.fromJson(Map<String, dynamic> json) {
    var dataJson = json["data"] ?? json;
    return DeviceDetail(
      success: json["success"] ?? (json["status"] == true),
      message: json["message"] ?? json["msg"],
      deviceId: (json["deviceId"] ?? json["device_id"])?.toString(),
      kidDeviceAccountConnectID: (json["kidDeviceAccountConnectID"] ?? json["connectId"])?.toString(),
      data: dataJson is Map<String, dynamic> ? Data.fromJson(dataJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "deviceId": deviceId,
    "kidDeviceAccountConnectID": kidDeviceAccountConnectID,
    "data": data?.toJson(),
  };
}

class Data {
  String? deviceId;
  String? model;
  String? osVersion;
  bool? online;
  int? batteryPct;
  String? lastSeenAt;
  List<App>? apps;
  Usage? usage;
  LocationData? location;

  Data({
    this.deviceId,
    this.model,
    this.osVersion,
    this.online,
    this.batteryPct,
    this.lastSeenAt,
    this.apps,
    this.usage,
    this.location,
  });

  // Backward compatibility getter for legacy UI
  RealTimeStats get realTimeStats => RealTimeStats(
    batteryLevel: batteryPct ?? 0,
    batteryStatus: online == true ? "Online" : "Offline",
    isOnline: online == true ? 1 : 0,
    currentLatitude: location?.lat ?? 0.0,
    currentLongitude: location?.lng ?? 0.0,
    deviceDataUsage: 0,
  );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    deviceId: (json["deviceId"] ?? json["device_id"])?.toString(),
    model: json["model"],
    osVersion: json["osVersion"]?.toString(),
    online: json["online"] ?? (json["isOnline"] == 1),
    batteryPct: (json["batteryPct"] ?? json["batteryLevel"])?.toInt(),
    lastSeenAt: json["lastSeenAt"] ?? json["lastReportedTime"]?.toString(),
    apps: json["apps"] == null ? [] : List<App>.from(json["apps"]!.map((x) => App.fromJson(x))),
    usage: json["usage"] == null ? null : Usage.fromJson(json["usage"]),
    location: json["location"] == null ? null : LocationData.fromJson(json["location"]),
  );

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId,
    "model": model,
    "osVersion": osVersion,
    "online": online,
    "batteryPct": batteryPct,
    "lastSeenAt": lastSeenAt,
    "apps": apps?.map((x) => x.toJson()).toList(),
    "usage": usage?.toJson(),
    "location": location?.toJson(),
  };
}

class App {
  String? pkg;
  String? name;
  int? usageTodayMs;
  bool? systemApp;
  int? isEnabled;

  App({this.pkg, this.name, this.usageTodayMs, this.systemApp = false, this.isEnabled = 1});

  // Backward compatibility getters
  String? get packageName => pkg;
  String? get appName => name;
  int? get lastUsedTime => usageTodayMs;

  factory App.fromJson(Map<String, dynamic> json) => App(
    pkg: json["pkg"] ?? json["packageName"],
    name: json["name"] ?? json["appName"],
    usageTodayMs: (json["usageTodayMs"] ?? json["totalUsedTime"] ?? 0).toInt(),
    systemApp: json["systemApp"] ?? false,
    isEnabled: json["isEnabled"] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    "pkg": pkg, 
    "name": name,
    "usageTodayMs": usageTodayMs,
    "systemApp": systemApp,
    "isEnabled": isEnabled,
  };
}

class RealTimeStats {
  int? batteryLevel;
  String? batteryStatus;
  int? isOnline;
  double? currentLatitude;
  double? currentLongitude;
  int? deviceDataUsage;

  RealTimeStats({this.batteryLevel, this.batteryStatus, this.isOnline, this.currentLatitude, this.currentLongitude, this.deviceDataUsage});

  Map<String, dynamic> toJson() => {
    "batteryLevel": batteryLevel,
    "batteryStatus": batteryStatus,
    "isOnline": isOnline,
    "currentLatitude": currentLatitude,
    "currentLongitude": currentLongitude,
    "deviceDataUsage": deviceDataUsage,
  };
}

class Usage {
  int? todayMs;
  int? dailyAvgMs;

  Usage({this.todayMs, this.dailyAvgMs});

  factory Usage.fromJson(Map<String, dynamic> json) => Usage(
    todayMs: (json["todayMs"] as num?)?.toInt(),
    dailyAvgMs: (json["dailyAvgMs"] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "todayMs": todayMs,
    "dailyAvgMs": dailyAvgMs,
  };
}

class LocationData {
  double? lat;
  double? lng;
  String? capturedAt;

  LocationData({this.lat, this.lng, this.capturedAt});

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    lat: (json["lat"] as num?)?.toDouble(),
    lng: (json["lng"] as num?)?.toDouble(),
    capturedAt: json["capturedAt"],
  );

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
    "capturedAt": capturedAt,
  };
}
