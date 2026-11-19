import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/network_history_model.dart';

WebsiteVisit visit(String domain, String? pkg, {String? name, int minute = 0}) => WebsiteVisit(
      domain: domain,
      appPkg: pkg,
      appName: name,
      time: DateTime(2026, 11, 19, 10, minute),
    );

void main() {
  test('hides lookups the phone makes by itself', () {
    final background = [
      visit("androidattestationvalidation-pa.googleapis.com", "com.google.android.as.oss"),
      visit("moolahmdm.com", "io.fieldx.app.devices", name: "Moolah Connect"),
      visit("notifications-pa.googleapis.com", "com.google.uid.shared:10120"),
      visit("localhost", "com.google.uid.shared:10120"),
      visit("connectivitycheck.gstatic.com", "android.uid.networkstack:1073"),
      visit("www.google.cn", "android.uid.networkstack:1073"),
      visit("clientapi-moolah.dtignite.com", "com.dti.moolah"),
      visit("192.168.1.1", "com.android.chrome"),
      visit("example.org", "com.google.android.gms"),
    ];
    expect(background.where((v) => !v.isBackground).map((v) => v.domain), isEmpty);
  });

  test('keeps sites opened in browsers and apps, including Chrome', () {
    final real = [
      visit("www.youtube.com", "com.android.chrome", name: "Chrome"),
      visit("en.wikipedia.org", "org.mozilla.firefox", name: "Firefox"),
      visit("i.pinimg.com", "com.pinterest", name: "Pinterest"),
      visit("www.google.com", "com.opera.browser", name: "Opera"),
    ];
    expect(real.where((v) => v.isBackground), isEmpty);
  });

  test('groups by domain ignoring www, newest first, with visit counts', () {
    final sites = groupVisits([
      visit("youtube.com", "com.android.chrome", name: "Chrome", minute: 1),
      visit("www.youtube.com", "com.android.chrome", name: "Chrome", minute: 5),
      visit("moolahmdm.com", "io.fieldx.app.devices", minute: 9),
      visit("en.wikipedia.org", "org.mozilla.firefox", name: "Firefox", minute: 3),
    ]);
    expect(sites.map((s) => s.domain), ["youtube.com", "en.wikipedia.org"]);
    expect(sites.first.visits, 2);
    expect(sites.first.lastVisit, DateTime(2026, 11, 19, 10, 5));
    expect(sites.first.appName, "Chrome");
  });

  test('parses the API item shape', () {
    final history = NetworkHistory.fromJson({
      "websites": {
        "total": 3,
        "items": [
          {"time": "2026-11-19T11:07:17Z", "domain": "moolahmdm.com", "app": {"pkg": "io.fieldx.app.devices", "name": "Moolah Connect"}},
          {"time": "2026-11-19T11:05:00Z", "domain": "WWW.Example.com", "app": {"pkg": "com.android.chrome", "name": "Chrome"}},
          {"time": "2026-11-19T11:04:00Z", "domain": "localhost", "app": {"pkg": "com.google.uid.shared:10120", "name": null}},
        ]
      },
      "dataUsage": [],
    });
    expect(history.visitedSites.map((s) => s.domain), ["example.com"]);
    expect(history.hiddenLookups, 2);
  });
}
