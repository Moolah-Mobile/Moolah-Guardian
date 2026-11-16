import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/models/subscription.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/util/customtoast.dart';

import '../helper/endpoints.dart';
import '../helper/network.dart';
import 'baseController.dart';

typedef GetRequest = Future<ResponseModel> Function(String url);
typedef PostRequest = Future<ResponseModel> Function(String url, {Map<String, dynamic> body});

/// Holds the parent's plan, which the server keeps, and takes payment for plans through Stripe.
///
/// Flow: `POST /guardian/orders/{plan}` creates the order and its Stripe subscription → the Stripe payment
/// sheet collects the card → `POST /guardian/orders/{id}/confirm` → `GET /guardian/subscription` unlocks it.
/// Only the server's answer changes the plan; the phone never decides on its own that a plan was bought.
class SubscriptionController extends BaseController with WidgetsBindingObserver {
  SubscriptionController({GetRequest? get, PostRequest? post, this.confirmRetryDelay = const Duration(seconds: 2)})
      : _get = get ?? Network.get,
        _post = post ?? Network.post;

  final GetRequest _get;
  final PostRequest _post;
  final Duration confirmRetryDelay;

  static const confirmAttempts = 3;

  static const loadTimeout = Duration(seconds: 15);

  /// How stale the plan may get before coming back to the app reloads it.
  static const refreshAfter = Duration(minutes: 5);

  /// How long a cached plan with no end date is trusted while the server can't be reached.
  static const cacheTrust = Duration(days: 3);

  Plan currentPlan = Plan.free;

  /// When the current paid period ends: the next renewal, or the last day if the plan is cancelling.
  DateTime? expiresAt;

  /// Stripe couldn't take the last renewal and is retrying. The plan still works meanwhile.
  bool isPastDue = false;

  /// The plan won't renew and ends at [expiresAt].
  bool cancelAtPeriodEnd = false;

  /// Prices from `/guardian/plans`. Plans missing here use the price in [Plan].
  final Map<Plan, double> prices = {};

  Future<void>? _loading;
  DateTime? _loadedAt;

  /// Bumped on [reset] so a load started for the previous parent can't apply its result.
  int _session = 0;

  /// Only the newest load applies, so one started before a payment can't overwrite the plan after it.
  int _loadSeq = 0;

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {} // No binding in plain unit tests.
    loadSubscription();
  }

  @override
  void onClose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final loadedAt = _loadedAt;
    if (state == AppLifecycleState.resumed && loadedAt != null && DateTime.now().difference(loadedAt) > refreshAfter) {
      loadSubscription();
    }
  }

  bool allows(Feature feature) => currentPlan.allows(feature);

  bool canAddDevice(int connectedDevices) => currentPlan.canAddDevice(connectedDevices);

  double priceOf(Plan plan) => plan.isPaid ? prices[plan] ?? plan.monthlyPrice : 0;

  String priceLabel(Plan plan) => plan.isPaid ? "\$${priceOf(plan).toStringAsFixed(2)}/month" : "Free";

  bool get _loggedIn {
    try {
      return Prefs.accessToken.get().isNotEmpty;
    } catch (_) {
      return false; // Prefs not initialised, e.g. in tests.
    }
  }

  /// The cache is kept per account, so a different parent logging in on this phone never sees it.
  String? get _account {
    try {
      final email = Prefs.email.get().trim().toLowerCase();
      if (email.isNotEmpty) return email;
      final id = Prefs.userId.get();
      return id.isNotEmpty && id != "0" ? id : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the plan from the server. Calls made while one is running share it.
  Future<void> loadSubscription() => _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    final session = _session;
    final seq = ++_loadSeq;
    if (!_loggedIn) {
      _apply(Subscription.none);
      return;
    }
    // Screens wait on this before loading gated data, so a hung request mustn't hold them up.
    final res = await _get(EndPoints.guardianSubscription)
        .timeout(loadTimeout, onTimeout: () => ResponseModel(isSuccessful: false, message: "Timed out"));
    if (session != _session || seq != _loadSeq) return;
    if (res.isSuccessful) {
      final sub = Subscription.fromResponse(res.data);
      _loadedAt = DateTime.now();
      _writeCache(sub);
      _apply(sub);
    } else {
      // Keep what the server last said rather than locking a paying parent out over a network error.
      _apply(_readCache() ?? Subscription.none);
    }
  }

  void _apply(Subscription sub) {
    final plan = sub.effectivePlan(DateTime.now());
    currentPlan = plan;
    expiresAt = plan.isPaid ? sub.renewsAt : null;
    isPastDue = plan.isPaid && sub.isPastDue;
    cancelAtPeriodEnd = plan.isPaid && sub.cancelAtPeriodEnd;
    update();
  }

  void _writeCache(Subscription sub) {
    final account = _account;
    if (account == null) return;
    try {
      if (sub.plan.isPaid) {
        Prefs.subscriptionCache(account).set(jsonEncode({...sub.toCache(), "cachedAt": DateTime.now().toIso8601String()}));
      } else {
        Prefs.subscriptionCache(account).clear();
      }
    } catch (_) {}
  }

  Subscription? _readCache() {
    final account = _account;
    if (account == null) return null;
    try {
      final raw = Prefs.subscriptionCache(account).getSafe();
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      final sub = Subscription.fromResponse(json);
      final cachedAt = DateTime.tryParse(json["cachedAt"]?.toString() ?? "");
      final trusted = sub.renewsAt != null || (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTrust);
      return trusted ? sub : null;
    } catch (_) {
      return null;
    }
  }

  /// Loads prices from `/guardian/plans` once per session. On failure the prices in [Plan] stay.
  Future<void> loadPlans() async {
    if (prices.isNotEmpty || !_loggedIn) return;
    final res = await _get(EndPoints.guardianPlans);
    if (!res.isSuccessful) return;
    prices.addAll(parsePlanPrices(res.data));
    update();
  }

  /// Forgets the plan when the parent logs out. The next parent's plan is loaded after their login.
  void reset() {
    _session++;
    _loading = null;
    _loadedAt = null;
    prices.clear();
    _apply(Subscription.none);
  }

  /// Orders [plan], collects payment and activates it. Returns true once the server reports the plan, or
  /// has accepted the payment and is still activating it.
  Future<bool> subscribe(Plan plan, {String couponCode = ""}) async {
    if (isLoading || !plan.isPaid) return false;
    if (!_loggedIn) {
      errorToast("Please log in again before subscribing.");
      return false;
    }

    isLoading = true;
    try {
      final res = await _post(EndPoints.createOrder(plan.id), body: {"couponCode": couponCode.trim()});
      if (!res.isSuccessful) {
        apiToast(res);
        return false;
      }
      final order = PlanOrder.fromResponse(res.data);
      if (order == null) {
        errorToast("Payment could not be started. Please try again.");
        return false;
      }
      if (order.alreadySubscribed) {
        _loading = null;
        await loadSubscription();
        successToast("You're already on the ${plan.title} plan");
        return currentPlan == plan;
      }

      // No client secret means nothing to pay now, e.g. a 100% coupon; the server still has to confirm it.
      final paid = order.clientSecret != null;
      if (paid && !await collectPayment(order)) return false;

      final confirmed = await _confirm(order);
      _loading = null; // Don't reuse a load that started before the payment.
      await loadSubscription();

      if (currentPlan == plan) {
        successToast("You are now on the ${plan.title} plan");
        return true;
      }
      if (confirmed) {
        successToast("Payment received. Your ${plan.title} plan will unlock shortly.");
        return true;
      }
      errorToast(paid
          ? "Payment received, but your plan isn't active yet. It should unlock shortly. If it doesn't, please contact support."
          : "Your plan could not be activated. Please try again.");
      return false;
    } finally {
      isLoading = false;
    }
  }

  /// The card may already be charged here, so a failure is retried rather than reported straight away.
  Future<bool> _confirm(PlanOrder order) async {
    final intentId = order.intentId;
    final body = <String, dynamic>{
      if (intentId != null) (order.isSetupIntent ? "setupIntentId" : "paymentIntentId"): intentId,
    };
    for (var attempt = 1; attempt <= confirmAttempts; attempt++) {
      final res = await _post(EndPoints.confirmOrder(order.orderId), body: body);
      if (res.isSuccessful) return true;
      if (attempt < confirmAttempts) await Future.delayed(confirmRetryDelay * attempt);
    }
    return false;
  }

  /// Shows the Stripe payment sheet. Returns true when the parent paid.
  @protected
  Future<bool> collectPayment(PlanOrder order) async {
    final secret = order.clientSecret!;
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: order.isSetupIntent ? null : secret,
          setupIntentClientSecret: order.isSetupIntent ? secret : null,
          merchantDisplayName: 'Moolah Guardian',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      debugPrint("💳 Payment sheet: paid (order ${order.orderId})");
      return true;
    } on StripeException catch (e) {
      debugPrint("💳 Payment sheet: ${e.error.code.name} - ${e.error.message} (order ${order.orderId})");
      if (e.error.code != FailureCode.Canceled) {
        errorToast("Payment failed: ${e.error.localizedMessage ?? "please try again."}");
      }
      return false;
    } catch (e) {
      debugPrint("💳 Payment sheet error: $e");
      errorToast("Payment failed. Please try again.");
      return false;
    }
  }
}
