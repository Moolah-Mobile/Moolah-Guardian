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

  /// Fails at startup, not on the first request, when the app was built without the config file.
  static void ensureConfigured() {
    const missing = {
      'API_BASE_URL': apiBaseUrl,
      'MDM_BASE_URL': mdmBaseUrl,
      'MDM_API_KEY': mdmApiKey,
      'STRIPE_PUBLISHABLE_KEY': stripePublishableKey,
      'MIXPANEL_TOKEN': mixpanelToken,
      'ONESIGNAL_APP_ID': oneSignalAppId,
      'IRONSOURCE_APP_KEY': ironSourceAppKey,
    };
    final empty = [for (final e in missing.entries) if (e.value.isEmpty) e.key];
    if (empty.isNotEmpty) {
      throw StateError('Missing build config ${empty.join(', ')}. '
          'Run with --dart-define-from-file=config/prod.json');
    }
  }
}
