import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/models/subscription.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResponseModel ok(dynamic data) => ResponseModel(isSuccessful: true, message: null, data: data);
ResponseModel fail([String? message]) => ResponseModel(isSuccessful: false, message: message, data: null);

/// Network responses are scripted per URL; the last response repeats.
SubscriptionController controller({
  Map<String, List<ResponseModel>> gets = const {},
  Map<String, List<ResponseModel>> posts = const {},
  bool pays = true,
  List<(String, Map<String, dynamic>)>? sent,
  List<PlanOrder>? sheets,
}) {
  ResponseModel next(Map<String, List<ResponseModel>> script, String url) {
    final queue = script[url];
    if (queue == null || queue.isEmpty) return fail();
    return queue.length > 1 ? queue.removeAt(0) : queue.first;
  }

  return _Scripted(
    get: (url) async => next(gets, url),
    post: (url, {Map<String, dynamic> body = const {}}) async {
      sent?.add((url, body));
      return next(posts, url);
    },
    pays: pays,
    sheets: sheets,
  );
}

class _Scripted extends SubscriptionController {
  _Scripted({required super.get, required super.post, required this.pays, this.sheets})
      : super(confirmRetryDelay: Duration.zero);
  final bool pays;
  final List<PlanOrder>? sheets;

  @override
  Future<bool> collectPayment(PlanOrder order) async {
    sheets?.add(order);
    return pays;
  }
}

Future<void> loggedIn([Map<String, Object> extra = const {}]) async {
  SharedPreferences.setMockInitialValues({'access_token': 'token', 'email': 'parent@example.com', ...extra});
  await Prefs.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Toasts go to a platform channel that doesn't exist in tests.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);

  final future = DateTime.now().add(const Duration(days: 20));
  final subUrl = EndPoints.guardianSubscription;

  group('loadSubscription', () {
    test('uses the plan the server reports', () async {
      await loggedIn();
      final c = controller(gets: {
        subUrl: [ok({"status": true, "data": {"plan": "premium", "status": "active", "currentPeriodEnd": future.toIso8601String()}})]
      });
      await c.loadSubscription();
      expect(c.currentPlan, Plan.premium);
      expect(c.expiresAt, isNotNull);
    });

    test('a canceled subscription is Free', () async {
      await loggedIn();
      final c = controller(gets: {subUrl: [ok({"data": {"plan": "premium", "status": "canceled"}})]});
      await c.loadSubscription();
      expect(c.currentPlan, Plan.free);
    });

    test('past_due keeps the plan and flags it', () async {
      await loggedIn();
      final c = controller(gets: {subUrl: [ok({"data": {"planId": "basic", "status": "past_due"}})]});
      await c.loadSubscription();
      expect(c.currentPlan, Plan.basic);
      expect(c.isPastDue, isTrue);
    });

    test('a network error keeps the plan the server last reported', () async {
      await loggedIn();
      final c = controller(gets: {
        subUrl: [ok({"data": {"plan": "ultimate", "status": "active", "currentPeriodEnd": future.toIso8601String()}}), fail()]
      });
      await c.loadSubscription();
      await c.loadSubscription();
      expect(c.currentPlan, Plan.ultimate);
    });

    test("another parent's cached plan isn't used", () async {
      await loggedIn();
      final first = controller(gets: {
        subUrl: [ok({"data": {"plan": "ultimate", "status": "active", "currentPeriodEnd": future.toIso8601String()}})]
      });
      await first.loadSubscription();

      Prefs.email.set('other@example.com');
      final second = controller(gets: {subUrl: [fail()]});
      await second.loadSubscription();
      expect(second.currentPlan, Plan.free);
    });

    test('no login means Free without calling the server', () async {
      SharedPreferences.setMockInitialValues({});
      await Prefs.init();
      var called = false;
      final c = _Scripted(get: (_) async {
        called = true;
        return fail();
      }, post: (url, {Map<String, dynamic> body = const {}}) async => fail(), pays: true);
      await c.loadSubscription();
      expect(c.currentPlan, Plan.free);
      expect(called, isFalse);
    });

    test('reset drops the plan', () async {
      await loggedIn();
      final c = controller(gets: {subUrl: [ok({"data": {"plan": "premium", "status": "active"}})]});
      await c.loadSubscription();
      c.reset();
      expect(c.currentPlan, Plan.free);
      expect(c.expiresAt, isNull);
    });
  });

  group('loadPlans', () {
    test('reads server prices and keeps the built-in ones otherwise', () async {
      await loggedIn();
      final c = controller(gets: {
        EndPoints.guardianPlans: [ok({"data": [{"code": "basic", "amount": 2.99}, {"code": "premium", "amountCents": 799}]})]
      });
      await c.loadPlans();
      expect(c.priceOf(Plan.basic), 2.99);
      expect(c.priceOf(Plan.premium), 7.99);
      expect(c.priceOf(Plan.ultimate), 19.99);
      expect(c.priceLabel(Plan.free), "Free");
    });
  });

  group('subscribe', () {
    final orderUrl = EndPoints.createOrder("premium");
    final confirmUrl = EndPoints.confirmOrder("ord_1");
    final active = ok({"data": {"plan": "premium", "status": "active", "currentPeriodEnd": future.toIso8601String()}});

    test('orders, pays, confirms with the payment intent id, then reloads the plan', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final sheets = <PlanOrder>[];
      final c = controller(
        gets: {subUrl: [ok({"data": null}), active]},
        posts: {
          orderUrl: [ok({"status": true, "data": {"orderId": "ord_1", "clientSecret": "pi_123_secret_abc"}})],
          confirmUrl: [ok({"status": true})],
        },
        sent: sent,
        sheets: sheets,
      );
      await c.loadSubscription();
      expect(c.currentPlan, Plan.free);

      expect(await c.subscribe(Plan.premium, couponCode: " save2 "), isTrue);
      expect(sent[0].$1, orderUrl);
      expect(sent[0].$2, {"couponCode": "save2"});
      expect(sheets.single.clientSecret, "pi_123_secret_abc");
      expect(sent[1].$1, confirmUrl);
      expect(sent[1].$2, {"paymentIntentId": "pi_123"});
      expect(c.currentPlan, Plan.premium);
      expect(c.isLoading, isFalse);
    });

    test('closing the payment sheet stops before confirm', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final c = controller(
        posts: {orderUrl: [ok({"data": {"orderId": "ord_1", "clientSecret": "pi_1_secret_x"}})]},
        pays: false,
        sent: sent,
      );
      expect(await c.subscribe(Plan.premium), isFalse);
      expect(sent.map((s) => s.$1), [orderUrl]);
      expect(c.currentPlan, Plan.free);
    });

    test('a failed order shows no payment sheet', () async {
      await loggedIn();
      final sheets = <PlanOrder>[];
      final c = controller(posts: {orderUrl: [fail("Coupon expired")]}, sheets: sheets);
      expect(await c.subscribe(Plan.premium), isFalse);
      expect(sheets, isEmpty);
    });

    test('confirm is retried after a failure', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final c = controller(
        gets: {subUrl: [active]},
        posts: {
          orderUrl: [ok({"data": {"orderId": "ord_1", "clientSecret": "pi_1_secret_x"}})],
          confirmUrl: [fail(), ok({"status": true})],
        },
        sent: sent,
      );
      expect(await c.subscribe(Plan.premium), isTrue);
      expect(sent.where((s) => s.$1 == confirmUrl).length, 2);
    });

    test('nothing to pay skips the payment sheet but still confirms', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final sheets = <PlanOrder>[];
      final c = controller(
        gets: {subUrl: [active]},
        posts: {orderUrl: [ok({"data": {"orderId": "ord_1"}})], confirmUrl: [ok({"status": true})]},
        sent: sent,
        sheets: sheets,
      );
      expect(await c.subscribe(Plan.premium, couponCode: "FREE100"), isTrue);
      expect(sheets, isEmpty);
      expect(sent.last.$1, confirmUrl);
      expect(sent.last.$2, isEmpty);
    });

    test('the admin coupon unlocks the plan without any server call (debug builds)', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final sheets = <PlanOrder>[];
      final c = controller(gets: {subUrl: [ok({"data": {"plan": {"code": "free"}, "status": "active"}})]}, sent: sent, sheets: sheets);
      expect(await c.subscribe(Plan.ultimate, couponCode: " MOOLAHGUARDIANADMIN123\$ "), isTrue);
      expect(sent, isEmpty);
      expect(sheets, isEmpty);
      expect(c.currentPlan, Plan.ultimate);

      // A reload from the server (still Free) keeps the unlocked plan.
      await c.loadSubscription();
      expect(c.currentPlan, Plan.ultimate);
      expect(c.expiresAt, isNotNull);
    });

    test('a wrong admin-looking code goes to the server as a normal coupon', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      final c = controller(posts: {orderUrl: [fail("Invalid coupon")]}, sent: sent);
      expect(await c.subscribe(Plan.premium, couponCode: "MoolahGuardianAdmin124\$"), isFalse);
      expect(sent.single.$1, orderUrl);
      expect(c.currentPlan, Plan.free);
    });

    test('Free and logged-out parents never create an order', () async {
      await loggedIn();
      final sent = <(String, Map<String, dynamic>)>[];
      expect(await controller(sent: sent).subscribe(Plan.free), isFalse);
      SharedPreferences.setMockInitialValues({});
      await Prefs.init();
      expect(await controller(sent: sent).subscribe(Plan.basic), isFalse);
      expect(sent, isEmpty);
    });
  });
}
