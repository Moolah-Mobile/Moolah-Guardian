import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/util/customtoast.dart';

import '../helper/endpoints.dart';
import '../helper/network.dart';
import 'baseController.dart';

/// Holds the parent's plan and takes payment for it through Stripe.
///
/// Payment uses the existing `/createPaymentIntent` endpoint, which charges a one-off amount; the backend
/// has no subscription or plan-status endpoint. So a payment unlocks its plan for [planLength], the
/// purchase is recorded on this phone, and the parent renews by paying again.
class SubscriptionController extends BaseController {
  static const planLength = Duration(days: 30);

  Plan currentPlan = Plan.free;

  /// When the current paid plan runs out; null on the Free plan.
  DateTime? expiresAt;

  @override
  void onInit() {
    super.onInit();
    loadSubscription();
  }

  bool allows(Feature feature) => currentPlan.allows(feature);

  bool canAddDevice(int connectedDevices) => currentPlan.canAddDevice(connectedDevices);

  /// Purchases are kept per account, so a different parent logging in on this phone starts on Free.
  String? get _account {
    try {
      final email = Prefs.email.get().trim().toLowerCase();
      if (email.isNotEmpty) return email;
      final id = Prefs.userId.get();
      return id.isNotEmpty && id != "0" ? id : null;
    } catch (_) {
      return null; // Prefs not initialised, e.g. in tests.
    }
  }

  /// Reads the purchase recorded for the logged-in parent and drops it once it has expired.
  Future<void> loadSubscription() async {
    currentPlan = Plan.free;
    expiresAt = null;
    final account = _account;
    if (account != null) {
      final parts = (Prefs.purchase(account).getSafe() ?? "").split("|");
      final plan = Plan.fromId(parts.first);
      final expiry = parts.length > 1 ? DateTime.tryParse(parts[1]) : null;
      if (plan.isPaid && expiry != null && expiry.isAfter(DateTime.now())) {
        currentPlan = plan;
        expiresAt = expiry;
      }
    }
    update();
  }

  /// Charges for [plan] and unlocks it for [planLength]. Returns true when the payment went through.
  Future<bool> subscribe(Plan plan) async {
    if (isLoading || !plan.isPaid) return false;
    final account = _account;
    if (account == null) {
      errorToast("Please log in again before subscribing.");
      return false;
    }

    isLoading = true;
    try {
      final res = await Network.post(EndPoints.createSubscription, body: {
        "amount": (plan.monthlyPrice * 100).round(),
      });
      if (!res.isSuccessful) {
        apiToast(res);
        return false;
      }
      final clientSecret = res.data?["clientSecret"]?.toString();
      if (clientSecret == null || clientSecret.isEmpty) {
        errorToast("Payment could not be started. Please try again.");
        return false;
      }
      if (!await _collectPayment(clientSecret)) return false;

      // Renewing the same plan adds a month to whatever time is left; any other plan starts a fresh month.
      final now = DateTime.now();
      final from = plan == currentPlan && expiresAt != null && expiresAt!.isAfter(now) ? expiresAt! : now;
      final expiry = from.add(planLength);
      Prefs.purchase(account).set("${plan.id}|${expiry.toIso8601String()}");
      await loadSubscription();
      successToast("You are now on the ${plan.title} plan");
      return true;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> _collectPayment(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Moolah Guardian',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        errorToast("Payment failed: ${e.error.localizedMessage}");
      }
      return false;
    } catch (e) {
      errorToast("Payment failed. Please try again.");
      return false;
    }
  }
}
