import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/blocked_url_model.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/helper/models/message_model.dart';
import 'package:moolah/helper/models/network_history_model.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/models/thread_model.dart';
import 'package:moolah/helper/network.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:moolah/helper/sharedHelper.dart';
import '../helper/repo/singleKidRepo.dart';

class HomeController extends BaseController {
  List<Kid> connectedKids = [];

  Future<void> getSyncedKidDevices() async {
    print("--- [MDM] Fetching Synced Devices ---");

    // The MDM API key is shared by every parent, so the MDM cannot list a parent's devices;
    // the parent's connect IDs come from api2 and each one is looked up on the MDM.
    ResponseModel parentRes = await HomeRepo.getParentKidDevices();
    if (!parentRes.isSuccessful || parentRes.data == null) {
      apiToast(parentRes);
      update();
      return;
    }

    List<Kid> temp = [];
    for (var link in (parentRes.data["devices"] as List? ?? [])) {
      final String? connectId = link["kidDeviceAccountConnectID"]?.toString();
      if (connectId == null || connectId.isEmpty) continue;

      ResponseModel responseModel = await HomeRepo.getSyncedKidDevices(connectId: connectId);
      final devices = responseModel.isSuccessful ? responseModel.data?["data"]?["devices"] : null;
      if (devices == null) {
        print("--- [MDM] No device for connect ID $connectId: ${responseModel.message} ---");
        continue;
      }

      for (var dev in devices as List) {
        Kid kid = Kid.fromJson(dev);
        kid.name = link["kidFullName"] ?? kid.name;
        kid.kidUserId = link["kidDeviceAccountUserID"]?.toString();
        temp.add(kid);
      }
    }
    connectedKids = temp;

    for (var kid in connectedKids) {
      if (kid.kidId != null) {
        getDeviceDetail(kidId: kid.kidId!);
      }
    }
    update();
  }

  Future<void> getDeviceDetail({required String kidId}) async {
    final kid = findKid(kidId);
    if (kid == null) return;
    ResponseModel responseModel = await HomeRepo.getSingleDeviceDetail(kid.kidId ?? kidId);

    if (responseModel.isSuccessful && responseModel.data != null) {
      final deviceJson = responseModel.data["data"];

      // getSingleDeviceDetail has no apps, usage or location, so it must not replace the getDeviceDetails result.
      kid.deviceDetail ??= DeviceDetail.fromJson(responseModel.data);

      if (deviceJson != null) {
        if (deviceJson["batteryPct"] != null) {
          kid.batteryStatus = deviceJson["batteryPct"].toString();
        }
        if (deviceJson["lastSeenAt"] != null) {
          try {
            DateTime lastSeen = DateTime.parse(deviceJson["lastSeenAt"]);
            Duration diff = DateTime.now().difference(lastSeen);
            kid.lastActive = "${diff.inMinutes}m ago";
          } catch (e) {
            kid.lastActive = "Now";
          }
        }
      }
    }
    update();
  }

  /// The connect ID of the device for [kidId], or null when that device isn't in the list.
  String? connectIdFor(String kidId) {
    final kid = findKid(kidId);
    return kid == null ? null : _connectIdOf(kid);
  }

  Future<void> blacklistApp({required String kidId, required String appPackage}) =>
      setAppBlocked(kidId: kidId, appPackage: appPackage, blocked: true);

  // The MDM's app lists carry no system flag; preinstalled apps on these devices use these package prefixes.
  static bool isSystemApp(App app) {
    final pkg = app.packageName ?? "";
    return app.systemApp == true ||
        pkg.startsWith("android.") ||
        pkg.startsWith("com.android.") ||
        pkg.startsWith("com.google.android.") ||
        pkg.startsWith("com.mediatek.") ||
        pkg.startsWith("com.umidigi.");
  }

  // Blocking or removing these would cut the child's device off from the MDM.
  static bool isProtectedApp(String? pkg) =>
      pkg == null ||
      pkg.startsWith("io.fieldx.") ||
      pkg.startsWith("com.moolahwireless.") ||
      pkg == "com.moolahmobile.moolahmobilehomescreen";

  Set<String> _alwaysOffPackages(List rules) {
    for (final r in rules) {
      if (r is Map && r["id"] == "always-off") {
        return Set<String>.from(r["packages"] as List? ?? []);
      }
    }
    return {};
  }

  Future<void> setAppBlocked({required String kidId, required String appPackage, required bool blocked}) async {
    if (blocked && isProtectedApp(appPackage)) return;
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    final connectId = _connectIdOf(kid);

    // setDeviceRestrictions replaces the device's whole rule list, so start from the current rules.
    ResponseModel current = await HomeRepo.getDeviceRestrictions(connectId);
    if (!current.isSuccessful) {
      apiToast(current);
      isLoading = false;
      update();
      return;
    }
    final rules = (current.data?["data"]?["rules"] as List? ?? [])
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    final alwaysOff = rules.indexWhere((r) => r["id"] == "always-off");
    final packages = alwaysOff < 0
        ? <String>[]
        : List<String>.from(rules[alwaysOff]["packages"] as List? ?? []);
    packages.remove(appPackage);
    if (blocked) packages.add(appPackage);

    if (alwaysOff >= 0) rules.removeAt(alwaysOff);
    if (packages.isNotEmpty) {
      rules.add({
        "id": "always-off",
        "type": "time",
        "packages": packages,
        "from": "00:00",
        "to": "23:59"
      });
    }

    ResponseModel res = await HomeRepo.setDeviceRestrictions(
      connectId: connectId,
      rules: rules
    );

    apiToast(res);
    if (res.isSuccessful) {
      kid.blockedPackages = packages.toSet();
    }
    isLoading = false;
    update();
  }

  Future<void> getInstalledApps({required String kidId}) async {
    final kid = findKid(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    final connectId = _connectIdOf(kid);

    ResponseModel appsRes = await HomeRepo.getInstalledApps(connectId);
    if (appsRes.isSuccessful) {
      kid.installedApps = (appsRes.data?["data"]?["apps"] as List? ?? [])
          .map((a) => App.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
      for (final app in kid.installedApps) {
        if (app.pkg != null && app.name != null) kid.appNames[app.pkg!] = app.name!;
      }
    } else {
      apiToast(appsRes);
    }

    ResponseModel rulesRes = await HomeRepo.getDeviceRestrictions(connectId);
    if (rulesRes.isSuccessful) {
      kid.blockedPackages = _alwaysOffPackages(rulesRes.data?["data"]?["rules"] as List? ?? []);
    }
    isLoading = false;
    update();
  }

  Future<void> getNetworkHistory({required String kidId}) async {
    final kid = findKid(kidId);
    if (kid == null) return;
    ResponseModel res = await HomeRepo.getNetworkHistory(_connectIdOf(kid));
    if (res.isSuccessful && res.data?["data"] is Map) {
      kid.networkHistory = NetworkHistory.fromJson(Map<String, dynamic>.from(res.data["data"]));
    }
    update();
  }

  Future<void> sendDeviceAction({required String kidId, required String action, required String successMessage}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.sendActionToDevice(action: action, deviceId: kid.kidId!);
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast(successMessage);
    } else {
      apiToast(res);
    }
  }

  /// Asks the MDM to factory reset the child's device. Everything on it is erased once it is online.
  Future<void> wipeDevice({required String kidId}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.wipeDevice(
        connectId: _connectIdOf(kid), externalMoolahId: Prefs.userId.get());
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast("Wipe sent. The device will be erased as soon as it is online.");
    } else if ((res.message ?? "").contains("404")) {
      errorToast("Device wipe isn't available on the server yet.");
    } else {
      apiToast(res);
    }
  }

  Future<void> deleteApp({required String kidId, required String appPackage}) async {
    if (isProtectedApp(appPackage) || isSystemApp(App(pkg: appPackage))) return;
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();

    ResponseModel res = await HomeRepo.deleteApp(
      connectId: _connectIdOf(kid),
      packageName: appPackage
    );

    if (res.isSuccessful) {
      // The MDM's app reports still list the app until the device reports again, so drop it here.
      kid.installedApps.removeWhere((app) => app.pkg == appPackage);
      kid.deviceDetail?.data?.apps?.removeWhere((app) => app.pkg == appPackage);
    }
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast("Uninstall sent to the device");
    } else {
      apiToast(res);
    }
  }

  Future<void> getAppUsage({required String kidId}) async {
    final kid = findKid(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.getAppUsage(_connectIdOf(kid));
    if (res.isSuccessful && res.data != null) {
      kid.deviceDetail = DeviceDetail.fromJson(res.data);
      for (final app in kid.deviceDetail?.data?.apps ?? <App>[]) {
        if (app.pkg != null && app.name != null) kid.appNames[app.pkg!] = app.name!;
      }
    }
    isLoading = false;
    update();
  }

  Future<void> enableMSMSMonitoring({required String kidId, required bool value}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await SingleKidRepo.enableMSMSMonitoring(kidId: kid.kidUserId ?? kidId, enable: value);
    apiToast(res);
    if (res.isSuccessful) {
      kid.msmsMonitoringStatus = value;
    }
    isLoading = false;
    update();
  }

  Future<void> enableWallet({required String kidId, required bool value}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await SingleKidRepo.enableWallet(kidId: kid.kidUserId ?? kidId, enable: value);
    apiToast(res);
    if (res.isSuccessful) {
      kid.walletEnabled = value;
    }
    isLoading = false;
    update();
  }

  Future<void> getMSMSMonitoringStatus({required String kidId}) async {
    ResponseModel responseModel = await SingleKidRepo.getMSMSMonitoringStatus(kidId: kidId);
    final kid = findKid(kidId);
    if (kid != null && responseModel.isSuccessful && responseModel.data != null) {
      kid.msmsMonitoringStatus = responseModel.data["msmsMonitoringStatus"];
    }
    update();
  }

  Future<void> getWalletStatus({required String kidId}) async {
    ResponseModel responseModel = await SingleKidRepo.getWalletStatus(kidId: kidId);
    final kid = findKid(kidId);
    if (kid != null && responseModel.isSuccessful && responseModel.data != null) {
      kid.walletEnabled = responseModel.data["walletEnabled"];
    }
    update();
  }

  Future<void> getBlacklistUrls({String? kidId}) async {
    if (kidId == null) return;
    final kid = findKid(kidId);
    if (kid == null) return;
    ResponseModel responseModel = await SingleKidRepo.getBlacklistUrls(kidId: kid.kidUserId ?? "");
    if (responseModel.isSuccessful && responseModel.data != null) {
      kid.blockedUrls = BlockedUrlModel.fromJson(responseModel.data);
    }
    update();
  }

  Future<void> addBlacklistUrl({String? kidId, String? url}) async {
    if (kidId == null || (url ?? "").isEmpty) return;
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel responseModel = await SingleKidRepo.addBlacklistUrl(kidId: kid.kidUserId, url: url);
    apiToast(responseModel);
    if (responseModel.isSuccessful) {
      kid.blockedUrls?.blockedUrlsData?.blockedUrls?.add(url ?? "");
    }
    isLoading = false;
    update();
  }

  Future<void> getMessageThreads({String? kidId}) async {
    update();
  }

  Future<List<MessageModel>> getMessages({String? threadId}) async {
    return []; 
  }

  /// Index of the device whose MDM device number or connect ID is [kidId], or -1. This used to fall back to
  /// the first device, which sent actions (uninstall, block, reboot, wipe) to the wrong child's device.
  int getSelectedKidIndex(String kidId) => connectedKids
      .indexWhere((kid) => kid.kidId != null && (kidId == kid.kidId || kidId == kid.connectId));

  /// The device for [kidId], or null. Never another device.
  Kid? findKid(String kidId) {
    final index = getSelectedKidIndex(kidId);
    return index < 0 ? null : connectedKids[index];
  }

  /// For screens: the device, or an empty placeholder, so a screen never shows another device's data.
  Kid getSelectedKid(String kidId) => findKid(kidId) ?? Kid(kidId: kidId);

  /// For anything that changes a device: the device, or null after telling the parent why nothing was sent.
  Kid? _deviceForAction(String kidId) {
    final kid = findKid(kidId);
    if (kid == null) {
      errorToast("This device isn't in your device list right now, so nothing was sent. "
          "Go back to Home and open it again.");
    }
    return kid;
  }

  static String _connectIdOf(Kid kid) => kid.connectId ?? kid.kidId!;

  void logout() {
    connectedKids.clear();
  }
}
