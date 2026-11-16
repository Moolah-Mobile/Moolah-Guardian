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
  String? couponUsed;

  @override
  Future<void> loadSubscription() async {}

  @override
  Future<void> loadPlans() async {}

  @override
  Future<bool> subscribe(Plan plan, {String couponCode = ""}) async {
    subscribedTo = plan;
    couponUsed = couponCode;
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

  testWidgets('a free user subscribes to the plan they pick, with a coupon', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Subscribe to Basic'), findsOneWidget);

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.text('Delete apps by location and time (coming soon)'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('coupon_code')), 'SAVE2');
    await tester.tap(find.text('Subscribe to Premium'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, Plan.premium);
    expect(controller.couponUsed, 'SAVE2');
  });

  testWidgets('server prices replace the built-in ones', (tester) async {
    controller.prices[Plan.basic] = 2.49;
    await pumpScreen(tester);
    expect(find.text('\$2.49'), findsOneWidget);
    expect(find.text('\$3.99'), findsNothing);
  });

  testWidgets('a paid user cannot buy their own plan again, and confirms before switching', (tester) async {
    controller.currentPlan = Plan.basic;
    controller.expiresAt = DateTime(2030, 1, 20);
    await pumpScreen(tester);
    expect(find.text('Current plan: Basic'), findsOneWidget);
    expect(find.text('Renews on 20/1/2030'), findsOneWidget);
    expect(find.byKey(const ValueKey('coupon_code')), findsNothing);

    await tester.tap(find.text('Your current plan'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, isNull);

    await tester.tap(find.text('Ultimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Ultimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, Plan.ultimate);
  });

  testWidgets('cancelling the switch dialog changes nothing', (tester) async {
    controller.currentPlan = Plan.premium;
    await pumpScreen(tester);
    await tester.tap(find.text('Basic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Basic'));
    await tester.pumpAndSettle();
    expect(find.text('Switch to Basic?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.subscribedTo, isNull);
  });

  testWidgets('a failed renewal shows a warning', (tester) async {
    controller.currentPlan = Plan.basic;
    controller.isPastDue = true;
    await pumpScreen(tester);
    expect(find.textContaining("Your last payment didn't go through"), findsOneWidget);
  });

  testWidgets('opens with the plan a locked feature needs already picked', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: Text('Home')),
      routes: {SubscriptionScreen.screenName: (_) => const SubscriptionScreen()},
    ));
    Get.toNamed(SubscriptionScreen.screenName, arguments: Plan.premium);
    await tester.pumpAndSettle();
    expect(find.text('Subscribe to Premium'), findsOneWidget);
  });

  testWidgets('Logout calls AuthController.logout', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect((Get.find<AuthController>() as MockAuthController).logoutCalled, isTrue);
    expect(find.text('OnBoard Screen'), findsOneWidget);
  });
}
