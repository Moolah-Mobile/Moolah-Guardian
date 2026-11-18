import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/kids_model.dart';

void main() {
  HomeController withDevices() {
    final c = HomeController();
    c.connectedKids = [
      Kid(kidId: "EMULATOR36X4X9X0", connectId: "EMULATOR36X4X9X0", name: "First"),
      Kid(kidId: "C67202408008378", connectId: "C67202408008378", name: "Second"),
    ];
    return c;
  }

  test("finds a device by its MDM device number or connect ID", () {
    final c = withDevices();
    expect(c.findKid("C67202408008378")?.name, "Second");
    expect(c.getSelectedKidIndex("EMULATOR36X4X9X0"), 0);
    expect(c.connectIdFor("C67202408008378"), "C67202408008378");
  });

  test("an unknown device never resolves to the first device", () {
    final c = withDevices();
    expect(c.getSelectedKidIndex("UNKNOWN"), -1);
    expect(c.findKid("UNKNOWN"), isNull);
    expect(c.connectIdFor("UNKNOWN"), isNull);
  });

  test("screens get an empty placeholder for an unknown device, not another device's data", () {
    final c = withDevices();
    final kid = c.getSelectedKid("UNKNOWN");
    expect(kid.kidId, "UNKNOWN");
    expect(kid.name, isNull);
    expect(kid.installedApps, isEmpty);
    expect(c.connectedKids.length, 2);
  });

  test("an empty device list resolves nothing", () {
    final c = HomeController();
    expect(c.findKid("C67202408008378"), isNull);
    expect(c.getSelectedKidIndex("C67202408008378"), -1);
  });
}
