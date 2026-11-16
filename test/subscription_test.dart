import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/screens/onboard/onboard.dart';
import 'package:moolah/screens/subscription_screen/subscription_screen.dart';

class MockSubscriptionController extends SubscriptionController {
  Plan? subscribedTo;

  @override
  Future<void> loadSubscription() async {}

  @override
  Future<bool> subscribe(Plan plan) async {
    subscribedTo = plan;
    return true;
  }
}

class MockAuthController extends AuthController {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  late MockSubscriptionController controller;

  setUp(() {
    controller = MockSubscriptionController();
    Get.put<SubscriptionController>(controller);
    Get.put<AuthController>(MockAuthController());
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      home: const SubscriptionScreen(),
      routes: {
        OnBoard.screenName: (_) => const Scaffold(body: Text('OnBoard Screen')),
      },
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('lists all four plans with their prices', (tester) async {
    await pumpScreen(tester);
    for (final plan in Plan.values) {
      expect(find.text(plan.title), findsOneWidget);
    }
    expect(find.text('\$3.99'), findsOneWidget);
    expect(find.text('\$8.99'), findsOneWidget);
    expect(find.text('\$19.99'), findsOneWidget);
    expect(find.text('Current plan: Free'), findsOneWidget);
  });

  testWidgets('a free user subscribes to the plan they pick', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Subscribe to Basic'), findsOneWidget);

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.text('Delete apps by location and time (coming soon)'), findsOneWidget);

    await tester.tap(find.text('Subscribe to Premium'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, Plan.premium);
  });

  testWidgets('a paid user can renew, and confirms before switching', (tester) async {
    controller.currentPlan = Plan.basic;
    controller.expiresAt = DateTime(2030, 1, 20);
    await pumpScreen(tester);
    expect(find.text('Current plan: Basic'), findsOneWidget);
    expect(find.text('Active until 20/1/2030'), findsOneWidget);

    await tester.tap(find.text('Renew Basic (+1 month)'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, Plan.basic);

    await tester.tap(find.text('Ultimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Ultimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, Plan.ultimate);
  });

  testWidgets('Logout calls AuthController.logout', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect((Get.find<AuthController>() as MockAuthController).logoutCalled, isTrue);
    expect(find.text('OnBoard Screen'), findsOneWidget);
  });
}
