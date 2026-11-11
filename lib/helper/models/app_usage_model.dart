import 'dart:convert';

AppUsage appUsageFromJson(String str) => AppUsage.fromJson(json.decode(str));

class AppUsage {
  int? installedAppsCount;
  String? deviceDailyAvgUsage;
  String? deviceDailyAvgUsageChange;
  List<ListOfInstalledApp>? listOfInstalledApps;
  String? msg;
  bool? success;

  AppUsage({
    this.installedAppsCount,
    this.deviceDailyAvgUsage,
    this.deviceDailyAvgUsageChange,
    this.listOfInstalledApps,
    this.msg,
    this.success,
  });

  factory AppUsage.fromJson(Map<String, dynamic> json) {
    var usage = json["usage"];
    var apps = json["apps"] as List?;

    String formatMs(int? ms) {
      if (ms == null) return "0m";
      Duration d = Duration(milliseconds: ms);
      if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes % 60}m";
      return "${d.inMinutes}m";
    }

    return AppUsage(
      installedAppsCount: apps?.length,
      deviceDailyAvgUsage: usage != null ? formatMs(usage["dailyAvgMs"]) : "0m",
      deviceDailyAvgUsageChange: usage != null ? "${usage["weekTrendPct"] ?? 0}% from last week" : "0%",
      listOfInstalledApps: apps?.map((x) => ListOfInstalledApp.fromMdm(x)).toList() ?? [],
      success: json["success"] ?? true,
    );
  }
}

class ListOfInstalledApp {
  String? packageName;
  String? appName;
  String? appIcon;
  int? usageMs;
  String? durationOfUsage;
  int? percentUsage; // Added for UI compatibility

  ListOfInstalledApp({
    this.packageName,
    this.appName,
    this.appIcon,
    this.usageMs,
    this.durationOfUsage,
    this.percentUsage = 0,
  });

  factory ListOfInstalledApp.fromMdm(Map<String, dynamic> json) {
    int ms = json["usageTodayMs"] ?? 0;
    Duration d = Duration(milliseconds: ms);
    return ListOfInstalledApp(
      packageName: json["pkg"],
      appName: json["name"],
      usageMs: ms,
      durationOfUsage: d.inHours > 0 ? "${d.inHours}h ${d.inMinutes % 60}m" : "${d.inMinutes}m",
      percentUsage: 0, // Calculate if needed
    );
  }
}
