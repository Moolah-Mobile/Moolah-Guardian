import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/env.dart';
import 'package:moolah/helper/repo/connectDeviceRepo.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/helper/sharedHelper.dart';
import '../util/customtoast.dart';

class ConnectDeviceController extends BaseController {
  /// Pairing goes through only when this phone is within 1 mile of the child's device, so someone who
  /// doesn't have the child's phone with them can't pair with it.
  static const pairRadiusMeters = 1609.344;

  /// How far this phone was from the child's device when the last attempt was refused for distance.
  double? tooFarMeters;

  /// What pairing is doing right now, shown while it works.
  String? progressText;

  void _progress(String? text) {
    progressText = text;
    update();
  }

  /// This phone's position, asking for location permission when needed; null (with a message) when it
  /// can't be had.
  Future<Position?> _parentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      errorToast("Turn on location on this phone. Pairing checks you're within 1 mile of your child's device.");
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      errorToast("Allow location for Moolah Guardian. Pairing checks you're within 1 mile of your child's device.");
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
    } catch (_) {
      errorToast("Couldn't find this phone's location. Move somewhere with a clearer signal and try again.");
      return null;
    }
  }

  /// The child's device's last reported position from the MDM, or null when it has none.
  Future<({double lat, double lng})?> _childPosition(String deviceNumber) async {
    final res = await HomeRepo.getSyncedKidDeviceLocation(deviceNumber);
    final data = res.isSuccessful ? (res.data?["data"]) : null;
    final lat = (data?["lat"] as num?)?.toDouble();
    final lng = (data?["lng"] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return (lat: lat, lng: lng);
  }

  /// Takes back api2's link when pairing is refused, so the device doesn't show up half-paired.
  Future<void> _undoApi2Link(dynamic linkData, String connectId) async {
    var kidUserId = _findKey(linkData, "kidDeviceAccountUserID");
    if (kidUserId == null) {
      final devices = await _parentDevices() ?? [];
      final match = devices.where((d) => d["kidDeviceAccountConnectID"]?.toString() == connectId);
      kidUserId = match.isEmpty ? null : match.first["kidDeviceAccountUserID"]?.toString();
    }
    if (kidUserId == null) {
      print("--- [CONNECT] Could not undo the api2 link for $connectId: no child user ID ---");
      return;
    }
    final res = await HomeRepo.unpairKidDevice(kidUserId: kidUserId, connectId: connectId);
    if (!res.isSuccessful) print("--- [CONNECT] Undoing the api2 link for $connectId failed: ${res.message} ---");
  }

  Future<bool> linkKidByConnectCode({
    required BuildContext context,
    required String code, // Connect code shown on the child's device
    required String label, // e.g. "Kid's Tablet"
  }) async {
    tooFarMeters = null;
    isLoading = true;
    // Debug builds started with SKIP_PAIRING_DISTANCE neither ask for location nor check the distance.
    const checkDistance = !Env.skipPairingDistance;
    Position? parent;
    if (checkDistance) {
      _progress("Finding your location…");
      parent = await _parentPosition();
      if (parent == null) {
        isLoading = false;
        _progress(null);
        return false;
      }
    } else {
      debugPrint("--- [CONNECT] SKIP_PAIRING_DISTANCE: not checking the 1-mile distance (debug build) ---");
    }

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
      _progress(null);
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
      _progress(null);
      errorToast("This child is already linked to your account. To add another device, sign in to "
          "Moolah Wallet on it with a different child account.");
      return false;
    }
    if (connectId == null) {
      isLoading = false;
      _progress(null);
      errorToast("Device linked, but its connect ID could not be found. Please try again.");
      return false;
    }

    // The MDM finds the tablet by its device number, IMEI or serial. api2's response may carry one;
    // without it the connect ID is sent, which is how devices were linked before.
    final deviceNumber = _findKey(api2Res.data, "deviceId") ??
        _findKey(api2Res.data, "imei") ??
        _findKey(api2Res.data, "serial") ??
        connectId;

    // Only someone with the child's phone nearby may pair: compare this phone's position with the one the
    // child's device last reported. api2 has already linked by now, so a refusal takes that link back.
    if (parent != null) {
      _progress("Checking you're near the device…");
      final child = await _childPosition(deviceNumber);
      if (child == null) {
        await _undoApi2Link(api2Res.data, connectId);
        isLoading = false;
        _progress(null);
        errorToast("Couldn't find where your child's device is. Make sure it's on, online and has location "
            "turned on, then try again.");
        return false;
      }
      final distance = Geolocator.distanceBetween(parent.latitude, parent.longitude, child.lat, child.lng);
      print("--- [CONNECT] Parent is ${distance.round()} m from device $deviceNumber ---");
      if (distance > pairRadiusMeters) {
        await _undoApi2Link(api2Res.data, connectId);
        tooFarMeters = distance;
        isLoading = false;
        _progress(null);
        return false;
      }
    }

    _progress("Linking the device…");
    String externalMoolahId = Prefs.userId.get();
    print("--- [CONNECT] Starting Provision for Parent ID: $externalMoolahId ---");

    // Step 2: Provision Parent on MDM
    final provisionRes = await ConnectDeviceRepo.provisionDevice(
      externalMoolahId: externalMoolahId,
    );

    if (!provisionRes.isSuccessful) {
      isLoading = false;
      _progress(null);
      errorToast(provisionRes.message ?? "Provisioning failed. Please try again.");
      return false;
    }

    print("--- [CONNECT] Provision Success. Linking device $deviceNumber as $connectId ---");
    // Step 3: Link Child Device to Parent, under the connect ID api2 uses for it
    final linkRes = await ConnectDeviceRepo.linkDevice(
      externalMoolahId: externalMoolahId,
      deviceId: deviceNumber,
      connectId: connectId,
      label: label,
    );

    isLoading = false;
    _progress(null);

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
