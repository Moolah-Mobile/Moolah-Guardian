import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SubscriptionController> controllerWith(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await Prefs.init();
  final c = SubscriptionController();
  await c.loadSubscription();
  return c;
}

void main() {
  final future = DateTime.now().add(const Duration(days: 10)).toIso8601String();
  final past = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();

  test('an unexpired purchase unlocks its plan', () async {
    final c = await controllerWith({'email': 'Parent@Example.com', 'purchase_parent@example.com': 'premium|$future'});
    expect(c.currentPlan, Plan.premium);
    expect(c.expiresAt, isNotNull);
  });

  test('an expired purchase falls back to Free', () async {
    final c = await controllerWith({'email': 'parent@example.com', 'purchase_parent@example.com': 'premium|$past'});
    expect(c.currentPlan, Plan.free);
    expect(c.expiresAt, isNull);
  });

  test("another account's purchase doesn't apply", () async {
    final c = await controllerWith({'email': 'other@example.com', 'purchase_parent@example.com': 'ultimate|$future'});
    expect(c.currentPlan, Plan.free);
  });

  test('no logged-in parent means Free', () async {
    final c = await controllerWith({});
    expect(c.currentPlan, Plan.free);
  });
}
