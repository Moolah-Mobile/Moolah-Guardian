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

  /// The sites the child visited: background lookups dropped, one entry per domain, most recent first.
  List<VisitedSite> get visitedSites => groupVisits(websites);

  /// How many lookups [visitedSites] left out as background traffic.
  int get hiddenLookups => websites.where((w) => w.isBackground).length;
}

class WebsiteVisit {
  final DateTime? time;
  final String domain;
  final String? appPkg;
  final String? appName;

  WebsiteVisit({this.time, required this.domain, this.appPkg, this.appName});

  factory WebsiteVisit.fromJson(Map<String, dynamic> json) => WebsiteVisit(
        time: DateTime.tryParse(json["time"]?.toString() ?? "")?.toLocal(),
        domain: (json["domain"]?.toString() ?? "").trim().toLowerCase(),
        appPkg: json["app"]?["pkg"]?.toString(),
        appName: json["app"]?["name"]?.toString(),
      );

  /// A lookup the phone made on its own (system services, Google Play services, the Moolah agent,
  /// connectivity checks, ads and analytics) rather than a site the child opened.
  bool get isBackground => _isBackgroundDomain(domain) || _isBackgroundApp(appPkg);
}

/// One row in Browser History: a domain, when it was last visited, how often, and from which app.
class VisitedSite {
  final String domain;
  final DateTime? lastVisit;
  final int visits;
  final String? appName;

  VisitedSite({required this.domain, this.lastVisit, required this.visits, this.appName});
}

/// Drops background lookups and merges the rest by domain ("www." ignored), newest first.
List<VisitedSite> groupVisits(List<WebsiteVisit> visits) {
  final byDomain = <String, List<WebsiteVisit>>{};
  for (final visit in visits) {
    if (visit.isBackground) continue;
    final domain = visit.domain.startsWith("www.") ? visit.domain.substring(4) : visit.domain;
    byDomain.putIfAbsent(domain, () => []).add(visit);
  }
  final sites = byDomain.entries.map((entry) {
    final latest = entry.value.reduce((a, b) => _later(a.time, b.time) ? a : b);
    return VisitedSite(
      domain: entry.key,
      lastVisit: latest.time,
      visits: entry.value.length,
      appName: latest.appName ?? entry.value.map((v) => v.appName).whereType<String>().firstOrNull,
    );
  }).toList();
  sites.sort((a, b) => _later(a.lastVisit, b.lastVisit) ? -1 : (_later(b.lastVisit, a.lastVisit) ? 1 : 0));
  return sites;
}

bool _later(DateTime? a, DateTime? b) => a != null && (b == null || a.isAfter(b));

/// Domains (and their subdomains) that phones look up by themselves: Google services, Android's
/// connectivity checks, ads and analytics, and Moolah's own servers.
const _backgroundDomains = [
  "googleapis.com",
  "gstatic.com",
  "gvt1.com",
  "gvt2.com",
  "gvt3.com",
  "google.cn",
  "googlesyndication.com",
  "googleadservices.com",
  "doubleclick.net",
  "google-analytics.com",
  "app-measurement.com",
  "crashlytics.com",
  "firebaseio.com",
  "firebaseinstallations.googleapis.com",
  "mtalk.google.com",
  "android.clients.google.com",
  "play.googleapis.com",
  "xtrapath1.izatcloud.net",
  "xtrapath2.izatcloud.net",
  "xtrapath3.izatcloud.net",
  "time.android.com",
  "pool.ntp.org",
  "moolahmdm.com",
  "moolahmobile.com",
  "dtignite.com",
];

bool _isBackgroundDomain(String domain) {
  if (domain.isEmpty || domain == "localhost" || !domain.contains(".")) return true;
  if (domain.endsWith(".local") || domain.endsWith(".arpa")) return true;
  if (RegExp(r'^[0-9.]+$').hasMatch(domain) || domain.contains(":")) return true; // IP address
  return _backgroundDomains.any((d) => domain == d || domain.endsWith(".$d"));
}

/// Apps whose lookups are never the child browsing: Android system services, shared system UIDs
/// (reported as "android.uid.…" / "….uid.shared:…" with no name), Google Play services and Moolah's own apps.
const _backgroundApps = [
  "android",
  "com.android.",
  "com.google.android.gms",
  "com.google.android.gsf",
  "com.google.android.as",
  "com.google.android.adservices",
  "com.google.android.apps.messaging",
  "com.google.android.ims",
  "com.google.android.networkstack",
  "com.mediatek.",
  "io.fieldx.app.devices",
  "com.dti.moolah",
  "com.moolahmobile.",
];

/// Browsers that share a system package prefix above but are where the child actually browses.
const _browserApps = {"com.android.chrome", "com.android.browser", "com.google.android.googlequicksearchbox"};

bool _isBackgroundApp(String? pkg) {
  if (pkg == null || pkg.isEmpty || _browserApps.contains(pkg)) return false;
  if (pkg.startsWith("android.uid.") || pkg.contains(".uid.shared") || pkg.contains(":")) return true;
  return _backgroundApps.any((p) => p.endsWith(".") ? pkg.startsWith(p) : (pkg == p || pkg.startsWith("$p.")));
}
