import 'package:flutter/material.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/repo/connectDeviceRepo.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/helper/sharedHelper.dart';
import '../util/customtoast.dart';

class ConnectDeviceController extends BaseController {

  Future<bool> linkKidByConnectCode({
    required BuildContext context,
    required String code, // Connect code shown on the child's device
    required String label, // e.g. "Kid's Tablet"
  }) async {
    isLoading = true;
    update();

    // Note the parent's devices before linking, so the newly linked one can be told apart.
    final before = await _parentDevices();
    final knownIds = before?.map((d) => d["kidDeviceAccountConnectID"]?.toString()).toSet() ?? {};

    // Step 1: Register the link with api2, which the home screen reads its device list from.
    final parentFullName = "${Prefs.firstName.get()} ${Prefs.lastName.get()}".trim();
    print("--- [CONNECT] Linking on api2 with code: $code ---");
    final api2Res = await ConnectDeviceRepo.linkKidByConnectCode(
      code: code,
      parentFullName: parentFullName,
    );
    print("--- [CONNECT] api2 link response: ${api2Res.data} ---");
    if (!api2Res.isSuccessful) {
      isLoading = false;
      update();
      errorToast(api2Res.message ?? "Invalid code. Please check and try again.");
      return false;
    }

    // The MDM knows the device by its connect ID, never by the code.
    final connectId = _findKey(api2Res.data, "kidDeviceAccountConnectID") ??
        await _connectIdFromParentDevices(api2Res.data, knownIds);

    // api2 links a parent to a child account, not to each tablet, so a second tablet signed in
    // with the same child account gets "Connection already exists" and nothing new is added.
    final alreadyLinked =
        (api2Res.message ?? "").toLowerCase().contains("already exists") ||
            (connectId != null && knownIds.contains(connectId));
    if (alreadyLinked) {
      isLoading = false;
      update();
      errorToast("This child is already linked to your account. To add another device, sign in to "
          "Moolah Wallet on it with a different child account.");
      return false;
    }
    if (connectId == null) {
      isLoading = false;
      update();
      errorToast("Device linked, but its connect ID could not be found. Please try again.");
      return false;
    }

    String externalMoolahId = Prefs.userId.get();
    print("--- [CONNECT] Starting Provision for Parent ID: $externalMoolahId ---");

    // Step 2: Provision Parent on MDM
    final provisionRes = await ConnectDeviceRepo.provisionDevice(
      externalMoolahId: externalMoolahId,
    );

    if (!provisionRes.isSuccessful) {
      isLoading = false;
      update();
      errorToast(provisionRes.message ?? "Provisioning failed. Please try again.");
      return false;
    }

    // The MDM finds the tablet by its device number, IMEI or serial. api2's response may carry one;
    // without it the connect ID is sent, which is how devices were linked before.
    final deviceNumber = _findKey(api2Res.data, "deviceId") ??
        _findKey(api2Res.data, "imei") ??
        _findKey(api2Res.data, "serial") ??
        connectId;
    print("--- [CONNECT] Provision Success. Linking device $deviceNumber as $connectId ---");
    // Step 3: Link Child Device to Parent, under the connect ID api2 uses for it
    final linkRes = await ConnectDeviceRepo.linkDevice(
      externalMoolahId: externalMoolahId,
      deviceId: deviceNumber,
      connectId: connectId,
      label: label,
    );

    isLoading = false;
    update();

    // Relinking the same parent and tablet returns the existing link, whose connect ID may differ from
    // api2's. Every MDM call uses api2's ID, so a mismatch means this device's data won't load.
    final mdmConnectId = linkRes.data?["data"]?["connectId"]?.toString();
    if (linkRes.isSuccessful && mdmConnectId != null && mdmConnectId != connectId) {
      print("--- [CONNECT] MDM connect ID $mdmConnectId differs from api2's $connectId ---");
    }

    if (linkRes.isSuccessful) {
      successToast("Device linked successfully! You can now monitor it from your dashboard.");
      return true;
    } else {
      errorToast(linkRes.message ?? "Linking failed. Please check the Device ID.");
      return false;
    }
  }

  Future<List<Map>?> _parentDevices() async {
    final res = await HomeRepo.getParentKidDevices();
    if (!res.isSuccessful || res.data == null) return null;
    return (res.data["devices"] as List? ?? []).whereType<Map>().toList();
  }

  // api2's link response may not carry the connect ID, so find the device in the parent's list:
  // by the child's user ID if the response has one, else the one device that wasn't there before.
  // Never fall back to an existing device: that would re-link the old tablet and report success.
  Future<String?> _connectIdFromParentDevices(dynamic linkData, Set<String?> knownIds) async {
    final devices = await _parentDevices();
    if (devices == null || devices.isEmpty) return null;
    String? idOf(Map d) => d["kidDeviceAccountConnectID"]?.toString();

    final kidUserId = _findKey(linkData, "kidDeviceAccountUserID");
    if (kidUserId != null) {
      final match = devices.where((d) => d["kidDeviceAccountUserID"]?.toString() == kidUserId);
      if (match.isNotEmpty) return idOf(match.first);
    }

    final added = devices.where((d) => !knownIds.contains(idOf(d))).toList();
    return added.length == 1 ? idOf(added.first) : null;
  }

  // The api2 link response format is not documented, so look for the key at any depth.
  String? _findKey(dynamic data, String key, [int depth = 0]) {
    if (depth > 4) return null;
    if (data is Map) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
      for (final v in data.values) {
        final found = _findKey(v, key, depth + 1);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (final v in data) {
        final found = _findKey(v, key, depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }
}
