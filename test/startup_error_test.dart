import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/env.dart';
import 'package:moolah/screens/startup_error/startup_error.dart';

void main() {
  test("a build without the config file is missing every key", () {
    // Tests run without --dart-define-from-file.
    expect(Env.missingKeys(), [
      'API_BASE_URL',
      'MDM_BASE_URL',
      'MDM_API_KEY',
      'STRIPE_PUBLISHABLE_KEY',
      'MIXPANEL_TOKEN',
      'ONESIGNAL_APP_ID',
      'IRONSOURCE_APP_KEY',
    ]);
  });

  testWidgets("missing keys: plain message, no key names anywhere", (tester) async {
    await tester.pumpWidget(StartupErrorApp.missingConfig());
    await tester.pumpAndSettle();

    expect(find.text("This version can't start"), findsOneWidget);
    expect(find.textContaining("Install the latest version"), findsOneWidget);
    expect(find.text("Close app"), findsOneWidget);
    expect(find.textContaining("_KEY"), findsNothing);

    await tester.ensureVisible(find.text("Details for support"));
    await tester.tap(find.text("Details for support"));
    await tester.pumpAndSettle();
    expect(find.text("Missing build config."), findsOneWidget);
    expect(find.textContaining("_KEY"), findsNothing);
    expect(find.textContaining("_URL"), findsNothing);
    expect(find.text("Hide details"), findsOneWidget);
  });

  testWidgets("a startup crash says to reopen and keeps long errors short", (tester) async {
    await tester.pumpWidget(StartupErrorApp.crashed(StateError("x" * 1000)));
    await tester.pumpAndSettle();

    expect(find.text("Something went wrong"), findsOneWidget);
    expect(find.textContaining("Close it and open it again"), findsOneWidget);

    await tester.ensureVisible(find.text("Details for support"));
    await tester.tap(find.text("Details for support"));
    await tester.pumpAndSettle();
    final details = tester.widget<SelectableText>(find.byType(SelectableText)).data!;
    expect(details, startsWith("Startup error: Bad state: x"));
    expect(details.length, lessThan(450));
  });

  testWidgets("fits a small phone with large text", (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(StartupErrorApp.missingConfig());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Details for support"));
    await tester.tap(find.text("Details for support"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("Missing build config."), findsOneWidget);
  });
}
