class NetworkHistory {
  final List<WebsiteVisit> websites;
  final int websitesTotal;
  final int dataUsageBytes;

  NetworkHistory({
    required this.websites,
    required this.websitesTotal,
    required this.dataUsageBytes,
  });

  factory NetworkHistory.fromJson(Map<String, dynamic> json) {
    final websites = json["websites"]?["items"] as List? ?? [];
    final usage = json["dataUsage"] as List? ?? [];
    return NetworkHistory(
      websites: websites
          .map((w) => WebsiteVisit.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList(),
      websitesTotal: (json["websites"]?["total"] as num?)?.toInt() ?? websites.length,
      dataUsageBytes: usage.fold<int>(
          0,
          (sum, u) =>
              sum +
              ((u["rxBytes"] as num?)?.toInt() ?? 0) +
              ((u["txBytes"] as num?)?.toInt() ?? 0)),
    );
  }

  String get dataUsageGb => (dataUsageBytes / 1000000000).toStringAsFixed(2);
}

class WebsiteVisit {
  final DateTime? time;
  final String domain;
  final String? appName;

  WebsiteVisit({this.time, required this.domain, this.appName});

  factory WebsiteVisit.fromJson(Map<String, dynamic> json) => WebsiteVisit(
        time: DateTime.tryParse(json["time"]?.toString() ?? "")?.toLocal(),
        domain: json["domain"]?.toString() ?? "",
        appName: (json["app"]?["name"] ?? json["app"]?["pkg"])?.toString(),
      );
}
