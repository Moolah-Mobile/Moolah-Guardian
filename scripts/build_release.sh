#!/usr/bin/env bash
# Builds the Play Store release (AAB + APK) with the app config injected and the Dart code obfuscated.
#
# Needs (none of these are in git):
#   config/prod.json            app hosts and SDK keys (copy config/example.json)
#   android/secrets.properties  MAPS_API_KEY=...
#   android/key.properties      upload keystore
#
# Keep build/symbols/ for every release you ship: it is the only way to read obfuscated stack traces.
set -euo pipefail
cd "$(dirname "$0")/.."

for f in config/prod.json android/secrets.properties android/key.properties; do
  [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done

ARGS=(--release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/prod.json)

flutter build appbundle "${ARGS[@]}"
flutter build apk "${ARGS[@]}"

echo
echo "AAB:     build/app/outputs/bundle/release/app-release.aab"
echo "APK:     build/app/outputs/flutter-apk/app-release.apk"
echo "Symbols: build/symbols  (upload to Crashlytics: firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> build/symbols)"
