import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/helper/models/subscription.dart';

void main() {
  final now = DateTime(2026, 11, 16);

  group('Subscription.fromResponse', () {
    test('reads camelCase, snake_case and nested plan objects', () {
      final a = Subscription.fromResponse({"status": true, "data": {"plan": "Premium", "status": "active", "currentPeriodEnd": "2026-12-16T00:00:00Z"}});
      expect(a.plan, Plan.premium);
      expect(a.renewsAt, DateTime.utc(2026, 12, 16).toLocal());

      final b = Subscription.fromResponse({"subscription": {"plan_id": "basic", "status": "TRIALING", "current_period_end": 1797379200}});
      expect(b.plan, Plan.basic);
      expect(b.status, "trialing");
      expect(b.renewsAt, DateTime.fromMillisecondsSinceEpoch(1797379200 * 1000));

      final c = Subscription.fromResponse({"data": {"subscription": {"plan": {"id": "ultimate", "name": "Ultimate"}, "cancel_at_period_end": true}}});
      expect(c.plan, Plan.ultimate);
      expect(c.cancelAtPeriodEnd, isTrue);
    });

    test('reads the real /guardian/subscription response', () {
      final sub = Subscription.fromResponse({"status": true, "data": {
        "plan": {"code": "free", "name": "Free", "amountCents": 0, "amount": 0, "interval": "month", "deviceLimit": 1},
        "status": "active", "orderId": null, "stripeSubscriptionId": null,
        "currentPeriodStart": null, "currentPeriodEnd": null, "cancelAtPeriodEnd": false, "isFree": true,
      }});
      expect(sub.plan, Plan.free);
      expect(sub.status, "active");
      expect(sub.renewsAt, isNull);

      final paid = Subscription.fromResponse({"status": true, "data": {
        "plan": {"code": "premium", "name": "Premium Plan", "amountCents": 899, "amount": 8.99},
        "status": "active", "currentPeriodEnd": "2026-12-16T18:20:00.000Z", "cancelAtPeriodEnd": false,
      }});
      expect(paid.plan, Plan.premium);
      expect(paid.effectivePlan(DateTime(2026, 11, 20)), Plan.premium);
    });

    test('no subscription, or an unknown plan, is none', () {
      expect(Subscription.fromResponse({"status": true, "data": null}), Subscription.none);
      expect(Subscription.fromResponse({"data": {"plan": "platinum"}}), Subscription.none);
      expect(Subscription.fromResponse(null), Subscription.none);
      expect(Subscription.fromResponse("oops"), Subscription.none);
    });

    test('effective plan follows the status and period end', () {
      Subscription sub(String status, [DateTime? end]) => Subscription(plan: Plan.premium, status: status, renewsAt: end);
      expect(sub("active").effectivePlan(now), Plan.premium);
      expect(sub("").effectivePlan(now), Plan.premium);
      expect(sub("past_due").effectivePlan(now), Plan.premium);
      expect(sub("canceled").effectivePlan(now), Plan.free);
      expect(sub("incomplete").effectivePlan(now), Plan.free);
      expect(sub("active", now.subtract(const Duration(days: 1))).effectivePlan(now), Plan.free);
      expect(sub("active", now.add(const Duration(days: 1))).effectivePlan(now), Plan.premium);
    });
  });

  group('PlanOrder.fromResponse', () {
    test('finds the order id and client secret wherever they sit', () {
      final a = PlanOrder.fromResponse({"status": true, "data": {"orderId": "12", "clientSecret": "pi_9_secret_z"}})!;
      expect(a.orderId, "12");
      expect(a.intentId, "pi_9");
      expect(a.isSetupIntent, isFalse);

      final b = PlanOrder.fromResponse({"data": {"order": {"id": 34, "status": "pending"}, "client_secret": "seti_7_secret_q"}})!;
      expect(b.orderId, "34");
      expect(b.isSetupIntent, isTrue);
      expect(b.intentId, "seti_7");
    });

    test('reads the real /guardian/orders response', () {
      final order = PlanOrder.fromResponse({"status": true, "message": "Guardian order created", "data": {
        "alreadySubscribed": false,
        "order": {"id": 200, "plan_code": "ultimate", "total_cents": 1999, "status": "pending",
          "stripe_subscription_id": "sub_1", "stripe_payment_intent_id": "pi_3Uc", "stripe_invoice_id": "in_1"},
        "subscription": {"plan": {"code": "free"}, "status": "active", "orderId": null},
        "clientSecret": "pi_3Uc_secret_xyz",
      }})!;
      expect(order.orderId, "200");
      expect(order.clientSecret, "pi_3Uc_secret_xyz");
      expect(order.intentId, "pi_3Uc");
      expect(order.alreadySubscribed, isFalse);

      final again = PlanOrder.fromResponse({"data": {"alreadySubscribed": true, "order": {"id": 9}}})!;
      expect(again.alreadySubscribed, isTrue);
    });

    test("a nested Stripe object's id isn't taken as the order id", () {
      expect(PlanOrder.fromResponse({"data": {"id": "pi_123", "clientSecret": "pi_123_secret_a"}}), isNull);
    });

    test('no order id means no order', () {
      expect(PlanOrder.fromResponse({"status": true, "clientSecret": "pi_1_secret_a"}), isNull);
      expect(PlanOrder.fromResponse(null), isNull);
    });

    test('no client secret means nothing to pay', () {
      final order = PlanOrder.fromResponse({"data": {"orderId": "5"}})!;
      expect(order.clientSecret, isNull);
      expect(order.intentId, isNull);
    });
  });

  test('parsePlanPrices reads dollars and cents and skips unknown plans', () {
    final prices = parsePlanPrices({"status": true, "data": {"plans": [
      {"code": "basic", "name": "Basic", "amountCents": 399, "amount": 3.99},
      {"planId": "premium", "unit_amount": 899},
      {"code": "ultimate", "amount": 19.99},
      {"id": "platinum", "price": 50},
      "junk",
    ]}});
    expect(prices, {Plan.basic: 3.99, Plan.premium: 8.99, Plan.ultimate: 19.99});
    expect(parsePlanPrices(null), isEmpty);
  });
}
