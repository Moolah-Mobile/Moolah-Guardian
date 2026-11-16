import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/models/plan.dart';

void main() {
  test('Free covers pairing and location only', () {
    expect(Plan.free.allows(Feature.pairDevice), isTrue);
    expect(Plan.free.allows(Feature.location), isTrue);
    expect(Plan.free.allows(Feature.battery), isFalse);
    expect(Plan.free.allows(Feature.appUsage), isFalse);
    expect(Plan.free.allows(Feature.deleteApps), isFalse);
  });

  test('Basic adds battery and app usage', () {
    expect(Plan.basic.allows(Feature.location), isTrue);
    expect(Plan.basic.allows(Feature.battery), isTrue);
    expect(Plan.basic.allows(Feature.appUsage), isTrue);
    expect(Plan.basic.allows(Feature.deleteApps), isFalse);
    expect(Plan.basic.allows(Feature.browserHistory), isFalse);
  });

  test('Premium and Ultimate include every feature', () {
    for (final f in Feature.values) {
      expect(Plan.premium.allows(f), isTrue, reason: f.name);
      expect(Plan.ultimate.allows(f), isTrue, reason: f.name);
    }
  });

  test('Only Ultimate manages more than one device', () {
    expect(Plan.free.canAddDevice(0), isTrue);
    expect(Plan.premium.canAddDevice(1), isFalse);
    expect(Plan.ultimate.canAddDevice(4), isTrue);
    expect(Plan.ultimate.canAddDevice(5), isFalse);
    expect(Plan.requiredForDevices(2), Plan.ultimate);
    expect(Plan.requiredForDevices(6), isNull);
  });

  test('Prices match the plans', () {
    expect(Plan.basic.monthlyPrice, 3.99);
    expect(Plan.premium.monthlyPrice, 8.99);
    expect(Plan.ultimate.monthlyPrice, 19.99);
  });

  test('Unknown plan ids fall back to Free', () {
    expect(Plan.fromId('PREMIUM'), Plan.premium);
    expect(Plan.fromId(null), Plan.free);
    expect(Plan.fromId('platinum'), Plan.free);
  });
}
