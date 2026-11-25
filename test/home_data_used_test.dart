import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/helper/models/network_history_model.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/screens/home/widget/SyncDevice.dart';

// The Home card shows how much data the child's phone used over the last 7 days (the MDM has no speed).
void main() {
  test('gigabytes have two decimals', () {
    expect(formatGb(1473000000), "1.47");
    expect(formatGb(0), "0.00");
  });

  test('Home loads each device\'s data used from its network history', () async {
    SharedPreferences.setMockInitialValues({"mock_mode": true});
    await Prefs.init();
    final home = HomeController();
    Get.put(home);
    home.connectedKids = [Kid(kidId: "1", connectId: "MOCK-CONNECT-1", name: "Emma")];

    await home.getDataUsage();

    // The demo device's YouTube, TikTok and Roblox traffic: 851 + 432 + 190 MB.
    expect(home.connectedKids.first.dataUsageBytes, 1473000000);
    Get.reset();
  });

  Future<void> pumpCard(WidgetTester tester, String? gb) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SyncDevice(kidId: "1", name: "Emma", image: null, active: "now", battery: "80", dataUsedGb: gb),
      ),
    ));
  }

  testWidgets('the card shows GB, and a dash until it has loaded', (tester) async {
    await pumpCard(tester, "1.47");
    expect(find.text("1.47 GB"), findsOneWidget);
    expect(find.textContaining("Mb/s"), findsNothing);

    await pumpCard(tester, null);
    expect(find.text("– GB"), findsOneWidget);
  });
}
