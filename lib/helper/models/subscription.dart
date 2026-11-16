import 'plan.dart';

/// Parsing for the `/guardian/plans`, `/guardian/orders` and `/guardian/subscription` responses.
///
/// The exact field names of these responses aren't documented yet, so each reader accepts the common
/// spellings (camelCase, snake_case) and payloads wrapped in `data`, `subscription`, `order` or `plans`.

/// The parent's subscription as the server reports it.
class Subscription {
  const Subscription({required this.plan, this.status = "", this.renewsAt, this.cancelAtPeriodEnd = false});

  static const none = Subscription(plan: Plan.free);

  final Plan plan;

  /// Stripe's subscription status, lower case: active, trialing, past_due, canceled, incomplete…
  final String status;

  /// When the current paid period ends (the next renewal, or the end date if cancelling).
  final DateTime? renewsAt;

  final bool cancelAtPeriodEnd;

  bool get isPastDue => status == "past_due" || status == "unpaid";

  /// The plan the parent can use right now.
  ///
  /// active, trialing and past_due (Stripe is still retrying the card) keep the plan. A missing status
  /// counts as active while the period hasn't ended. Anything else, or a period end in the past, is Free.
  Plan effectivePlan(DateTime now) {
    if (!plan.isPaid) return Plan.free;
    final end = renewsAt;
    if (end != null && !end.isAfter(now)) return Plan.free;
    const usable = {"", "active", "trialing", "past_due"};
    return usable.contains(status) ? plan : Plan.free;
  }

  /// Reads a `/guardian/subscription` body. Returns [none] when it holds no subscription.
  static Subscription fromResponse(dynamic body) {
    final map = _unwrap(body, const ["subscription", "data", "currentSubscription"]);
    if (map == null) return none;
    final planId = _planId(map["plan"]) ?? _planId(map["planId"]) ?? _planId(map["plan_id"]) ??
        _planId(map["planName"]) ?? _planId(map["plan_name"]);
    if (planId == null) return none;
    return Subscription(
      plan: Plan.fromId(planId),
      status: (map["status"] ?? map["subscriptionStatus"] ?? map["subscription_status"] ?? "").toString().trim().toLowerCase(),
      renewsAt: parseDate(map["currentPeriodEnd"] ?? map["current_period_end"] ?? map["renewsAt"] ??
          map["renews_at"] ?? map["expiresAt"] ?? map["expires_at"] ?? map["endDate"] ?? map["end_date"] ??
          map["periodEnd"] ?? map["period_end"]),
      cancelAtPeriodEnd: map["cancelAtPeriodEnd"] == true || map["cancel_at_period_end"] == true,
    );
  }

  Map<String, dynamic> toCache() => {
        "plan": plan.id,
        "status": status,
        if (renewsAt != null) "currentPeriodEnd": renewsAt!.toIso8601String(),
        "cancelAtPeriodEnd": cancelAtPeriodEnd,
      };

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.plan == plan &&
      other.status == status &&
      other.renewsAt == renewsAt &&
      other.cancelAtPeriodEnd == cancelAtPeriodEnd;

  @override
  int get hashCode => Object.hash(plan, status, renewsAt, cancelAtPeriodEnd);
}

/// What `POST /guardian/orders/{planId}` returns.
class PlanOrder {
  const PlanOrder({required this.orderId, this.clientSecret, this.paymentIntentId, this.alreadySubscribed = false});

  final String orderId;

  /// The order's PaymentIntent id as the server stored it (`order.stripe_payment_intent_id`).
  final String? paymentIntentId;

  /// The parent already has this plan; the server created no new charge.
  final bool alreadySubscribed;

  /// Secret for the Stripe payment sheet. Null when there's nothing to pay (e.g. a 100% coupon).
  final String? clientSecret;

  /// A SetupIntent (`seti_…`) is returned instead of a PaymentIntent when nothing is charged today, e.g. a trial.
  bool get isSetupIntent => clientSecret?.startsWith("seti_") ?? false;

  /// The intent id the server stored, or else the part of the client secret before `_secret_`
  /// ("pi_123_secret_abc" → "pi_123").
  String? get intentId {
    if (paymentIntentId != null && !isSetupIntent) return paymentIntentId;
    final secret = clientSecret;
    if (secret == null) return null;
    final i = secret.indexOf("_secret_");
    return i > 0 ? secret.substring(0, i) : null;
  }

  /// Null when the body has no order id, since the order can't be confirmed without one.
  static PlanOrder? fromResponse(dynamic body) {
    String? stripeFree(dynamic v) {
      final id = _string(v);
      // A nested Stripe object's id is not the order id.
      return id == null || RegExp(r"^(pi|seti|sub|in|cus)_").hasMatch(id) ? null : id;
    }

    final order = _find(body, const ["order"], wantMap: true);
    final id = stripeFree(_find(body, const ["orderId", "order_id"])) ??
        stripeFree(_find(body, const ["order"], wantMap: true)?["id"]) ??
        stripeFree(_find(body, const ["order"], wantMap: true)?["_id"]) ??
        stripeFree(_find(body, const ["data"], wantMap: true)?["id"]) ??
        stripeFree(_find(body, const ["data"], wantMap: true)?["_id"]);
    if (id == null) return null;
    final intent = _string(order?["stripe_payment_intent_id"] ?? order?["stripePaymentIntentId"] ??
        _find(body, const ["paymentIntentId", "payment_intent_id"]));
    return PlanOrder(
      orderId: id,
      paymentIntentId: intent != null && intent.startsWith("pi_") ? intent : null,
      alreadySubscribed: _find(body, const ["alreadySubscribed", "already_subscribed"]) == true,
      clientSecret: _string(_find(body, const [
        "clientSecret",
        "client_secret",
        "paymentIntentClientSecret",
        "setupIntentClientSecret",
      ])),
    );
  }
}

/// Reads plan prices from a `/guardian/plans` body. Plans the app doesn't know are skipped.
///
/// `amountCents`/`unit_amount` are read as cents; `price`/`amount`/`monthlyPrice` as dollars, as the API sends them.
Map<Plan, double> parsePlanPrices(dynamic body) {
  dynamic list = body;
  for (var i = 0; i < 3 && list is Map; i++) {
    list = list["plans"] ?? list["data"] ?? list["results"];
  }
  final prices = <Plan, double>{};
  if (list is! List) return prices;
  for (final item in list) {
    if (item is! Map) continue;
    final id = _planId(item["code"]) ?? _planId(item["id"]) ?? _planId(item["planId"]) ??
        _planId(item["plan_id"]) ?? _planId(item["slug"]) ?? _planId(item["name"]);
    final plan = Plan.values.where((p) => p.id == id).firstOrNull;
    if (plan == null) continue;
    // Cents are exact, so they win over dollar amounts when both are sent.
    final cents = _number(item["amountCents"] ?? item["amount_cents"] ?? item["unit_amount"] ?? item["unitAmount"]);
    final dollars = _number(item["price"] ?? item["amount"] ?? item["monthlyPrice"] ?? item["monthly_price"]);
    final price = cents != null ? cents / 100 : dollars;
    if (price != null && price >= 0) prices[plan] = price;
  }
  return prices;
}

/// Accepts ISO 8601 strings and Unix timestamps in seconds (Stripe) or milliseconds.
DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  final n = value is num ? value : num.tryParse(value.toString());
  if (n != null) {
    final ms = n > 100000000000 ? n.toInt() : (n * 1000).toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// Steps into the first of [keys] that holds a map, up to two levels deep.
Map<String, dynamic>? _unwrap(dynamic body, List<String> keys) {
  if (body is! Map) return null;
  Map map = body;
  for (var depth = 0; depth < 2; depth++) {
    final next = keys.map((k) => map[k]).whereType<Map>().firstOrNull;
    if (next == null) break;
    map = next;
  }
  return Map<String, dynamic>.from(map);
}

/// The first value under any of [keys], searching nested maps breadth-first up to three levels deep.
dynamic _find(dynamic body, List<String> keys, {bool wantMap = false}) {
  var level = <Map>[if (body is Map) body];
  for (var depth = 0; depth < 4 && level.isNotEmpty; depth++) {
    for (final map in level) {
      for (final k in keys) {
        final v = map[k];
        if (v != null && (!wantMap || v is Map)) return v;
      }
    }
    level = [for (final map in level) ...map.values.whereType<Map>()];
  }
  return null;
}

/// A plan id from a string ("Premium") or a nested plan object ({"id": "premium"}).
String? _planId(dynamic value) {
  if (value is Map) value = value["code"] ?? value["id"] ?? value["planId"] ?? value["slug"] ?? value["name"];
  final id = _string(value)?.toLowerCase();
  return id == null || !Plan.values.any((p) => p.id == id) ? null : id;
}

String? _string(dynamic value) {
  final s = value?.toString().trim();
  return s == null || s.isEmpty || s == "null" ? null : s;
}

double? _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? "");
