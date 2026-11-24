/// Build-time configuration, injected with `--dart-define-from-file=config/prod.json`
/// (see scripts/build_release.sh). Nothing here is committed to git.
///
/// These values still ship inside the app binary, as every client-side key does; obfuscation only makes
/// them harder to pull out. Treat each one as public, and keep real secrets on the server.
class Env {
  Env._();

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const mdmBaseUrl = String.fromEnvironment('MDM_BASE_URL');
  static const mdmApiKey = String.fromEnvironment('MDM_API_KEY');
  static const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  static const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const ironSourceAppKey = String.fromEnvironment('IRONSOURCE_APP_KEY');

  /// The keys the app was built without, so startup can say so instead of failing on the first request.
  /// Empty when the build had the whole config file.
  static List<String> missingKeys() {
    const keys = {
      'API_BASE_URL': apiBaseUrl,
      'MDM_BASE_URL': mdmBaseUrl,
      'MDM_API_KEY': mdmApiKey,
      'STRIPE_PUBLISHABLE_KEY': stripePublishableKey,
      'MIXPANEL_TOKEN': mixpanelToken,
      'ONESIGNAL_APP_ID': oneSignalAppId,
      'IRONSOURCE_APP_KEY': ironSourceAppKey,
    };
    return [for (final e in keys.entries) if (e.value.isEmpty) e.key];
  }
}
