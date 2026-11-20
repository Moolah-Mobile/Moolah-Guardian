/// Subscription plans and the features each one unlocks.
///
/// The app uses this to show or lock features. The checks run on the phone only.
enum Feature {
  pairDevice,
  location,
  battery,
  appUsage,
  deleteApps,
  blockApps,
  browserHistory,
  urlBlacklist,
  wallet,
  deviceActions,
}

enum Plan {
  free(
    id: "free",
    title: "Free",
    monthlyPrice: 0,
    deviceLimit: 1,
    highlights: ["Pair 1 device", "See device location"],
  ),
  basic(
    id: "basic",
    title: "Basic",
    monthlyPrice: 3.99,
    deviceLimit: 1,
    highlights: ["Everything in Free", "Battery level", "App usage stats"],
  ),
  premium(
    id: "premium",
    title: "Premium",
    monthlyPrice: 8.99,
    deviceLimit: 1,
    highlights: [
      "Everything in Basic",
      "Delete and block apps",
      "Browser history and URL blocking",
      "Wallet, sync and reboot",
      "Delete apps by location and time (coming soon)",
    ],
  ),
  ultimate(
    id: "ultimate",
    title: "Ultimate",
    monthlyPrice: 19.99,
    deviceLimit: 5,
    highlights: ["Everything in Premium", "Manage up to 5 devices"],
  );

  const Plan({
    required this.id,
    required this.title,
    required this.monthlyPrice,
    required this.deviceLimit,
    required this.highlights,
  });

  /// The value the backend sends and receives for this plan.
  final String id;
  final String title;
  final double monthlyPrice;
  final int deviceLimit;
  final List<String> highlights;

  String get priceLabel => monthlyPrice == 0 ? "Free" : "\$${monthlyPrice.toStringAsFixed(2)}/month";

  bool get isPaid => this != Plan.free;

  static Plan fromId(String? id) =>
      Plan.values.firstWhere((p) => p.id == id?.toLowerCase().trim(), orElse: () => Plan.free);

  /// The lowest plan that includes [feature].
  static Plan requiredFor(Feature feature) {
    switch (feature) {
      case Feature.pairDevice:
      case Feature.location:
        return Plan.free;
      case Feature.battery:
      case Feature.appUsage:
        return Plan.basic;
      case Feature.deleteApps:
      case Feature.blockApps:
      case Feature.browserHistory:
      case Feature.urlBlacklist:
      case Feature.wallet:
      case Feature.deviceActions:
        return Plan.premium;
    }
  }

  /// Plans are ordered, so each one includes every feature of the plans below it.
  bool allows(Feature feature) => index >= requiredFor(feature).index;

  bool canAddDevice(int connectedDevices) => connectedDevices < deviceLimit;

  /// The lowest plan that allows [devices] devices, or null when no plan does.
  static Plan? requiredForDevices(int devices) {
    for (final plan in Plan.values) {
      if (devices <= plan.deviceLimit) return plan;
    }
    return null;
  }
}
