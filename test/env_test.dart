import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/env.dart';

// Run as `flutter test test/env_test.dart` and again with `--dart-define=SKIP_PAIRING_DISTANCE=true`.
void main() {
  const passed = bool.fromEnvironment('SKIP_PAIRING_DISTANCE');

  test("SKIP_PAIRING_DISTANCE skips the 1-mile check only in debug builds", () {
    expect(kDebugMode, isTrue); // flutter test runs in debug mode
    expect(Env.skipPairingDistance, passed);
  });

  test("the pairing flag is never a required key", () {
    expect(Env.missingKeys(), isNot(contains('SKIP_PAIRING_DISTANCE')));
  });
}
