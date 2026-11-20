import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/blockRulesController.dart';
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
        kid.lastActive = Kid.lastSeenText(deviceJson["lastSeenAt"]?.toString()) ?? kid.lastActive;
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

  // Uses the MDM's "system" flag. Older MDM responses have no flag, so fall back to the package prefixes
  // preinstalled apps use on these devices.
  static bool isSystemApp(App app) {
    if (app.systemApp != null) return app.systemApp!;
    final pkg = app.packageName ?? "";
    return pkg.startsWith("android.") ||
        pkg.startsWith("com.android.") ||
        pkg.startsWith("com.google.android.") ||
        pkg.startsWith("com.mediatek.") ||
        pkg.startsWith("com.umidigi.");
  }

  // Apps the Apps tab lists: ones the child can open (they have a screen to launch) that aren't system apps
  // or Moolah's own. When the MDM doesn't send "launchable", the app is treated as openable.
  static bool isUserApp(App app) => hiddenReason(app) == null;

  // Why the Apps tab hides [app], or null when it is shown.
  static String? hiddenReason(App app) {
    if (isMoolahApp(app.packageName)) return "moolah";
    // A blocked app is hidden on the phone and reports itself as not launchable; it's still the child's app.
    if (app.launchable == false && app.state != "hidden") return "not launchable";
    if (isSystemApp(app)) return app.systemApp == null ? "system (guessed from package)" : "system";
    return null;
  }

  // Moolah's own apps on the child's device: the MDM agent, home screen, wallet and the rest.
  static bool isMoolahApp(String? pkg) =>
      isProtectedApp(pkg) || pkg!.startsWith("com.moolahmobile.");

  // Blocking or removing these would cut the child's device off from the MDM.
  static bool isProtectedApp(String? pkg) =>
      pkg == null ||
      pkg.startsWith("io.fieldx.") ||
      pkg.startsWith("com.moolahwireless.") ||
      pkg == "com.moolahmobile.moolahmobilehomescreen";

  static const _alwaysOffId = "always-off";
  static const _alwaysOffLastMinuteId = "always-off-last-minute";

  Set<String> _alwaysOffPackages(List rules) {
    for (final r in rules) {
      if (r is Map && r["id"] == _alwaysOffId) {
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
    final alwaysOff = rules.indexWhere((r) => r["id"] == _alwaysOffId);
    final packages = alwaysOff < 0
        ? <String>[]
        : List<String>.from(rules[alwaysOff]["packages"] as List? ?? []);
    packages.remove(appPackage);
    if (blocked) packages.add(appPackage);

    // A rule's window can't cover a whole day, so "always off" is two rules: 00:00–23:59 and the
    // last minute, 23:59–00:00.
    rules.removeWhere((r) => r["id"] == _alwaysOffId || r["id"] == _alwaysOffLastMinuteId);
    if (packages.isNotEmpty) {
      rules.add({"id": _alwaysOffId, "type": "time", "packages": packages, "from": "00:00", "to": "23:59"});
      rules.add({"id": _alwaysOffLastMinuteId, "type": "time", "packages": packages, "from": "23:59", "to": "00:00"});
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
    // Reload the apps and rules, so the lists show what the device has now.
    if (res.isSuccessful) await getInstalledApps(kidId: kidId);
  }

  // Debug builds only: one line per app with the MDM's flags and whether the Apps tab shows it.
  static void _logInstalledApps(List<App> apps) {
    final shown = apps.where(isUserApp).length;
    debugPrint("📱 [APPS] ${apps.length} from MDM, $shown shown, ${apps.length - shown} hidden");
    for (final a in apps) {
      final reason = hiddenReason(a);
      debugPrint("📱 [APPS] ${reason == null ? "SHOW" : "HIDE"} ${a.pkg} \"${a.name}\""
          " system=${a.systemApp} launchable=${a.launchable} removable=${a.removable}"
          " icon=${a.iconUrl != null}${reason == null ? "" : " ← $reason"}");
    }
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
      if (kDebugMode) _logInstalledApps(kid.installedApps);
    } else {
      apiToast(appsRes);
    }

    ResponseModel rulesRes = await HomeRepo.getDeviceRestrictions(connectId);
    if (rulesRes.isSuccessful) {
      kid.blockedPackages = _alwaysOffPackages(rulesRes.data?["data"]?["rules"] as List? ?? []);
    }
    await _loadPendingUninstalls(kid);
    isLoading = false;
    update();
  }

  /// Marks apps whose uninstall the device hasn't finished, so their rows say "Uninstall pending".
  Future<void> _loadPendingUninstalls(Kid kid) async {
    ResponseModel res = await HomeRepo.getPendingCommands(_connectIdOf(kid));
    if (!res.isSuccessful) return;
    kid.pendingUninstalls = (res.data?["data"]?["commands"] as List? ?? [])
        .whereType<Map>()
        .where((c) => c["type"] == "deleteApp" && c["pkg"] != null)
        .map((c) => c["pkg"].toString())
        .toSet();
  }

  /// Follows an uninstall: when the device reports it failed (some phones need on-screen confirmation),
  /// tells the parent and clears the pending mark; when done, drops the app from the list.
  Future<void> _followUninstall(Kid kid, String commandId, String appPackage) async {
    for (int attempt = 0; attempt < 6; attempt++) {
      await Future.delayed(const Duration(seconds: 20));
      ResponseModel res = await HomeRepo.getCommandStatus(commandId);
      final status = res.data?["data"]?["status"]?.toString();
      if (status == "done") {
        kid.pendingUninstalls.remove(appPackage);
        kid.installedApps.removeWhere((app) => app.pkg == appPackage);
        kid.deviceDetail?.data?.apps?.removeWhere((app) => app.pkg == appPackage);
        update();
        return;
      }
      if (status == "failed" || status == "cancelled") {
        kid.pendingUninstalls.remove(appPackage);
        update();
        errorToast("Couldn't uninstall ${kid.appNames[appPackage] ?? appPackage}. Block it instead.");
        return;
      }
    }
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
      final cancellable = res.data?["data"]?["cancellable"] != false;
      successToast(cancellable
          ? "Wipe scheduled. You can cancel it for the next 5 minutes."
          : "Wipe sent. The device will be erased as soon as it is online.");
    } else {
      // 403 says why: the device isn't this parent's, or wipe isn't switched on for it yet.
      apiToast(res);
    }
  }

  /// Removes the child's device from this parent's account. On success it leaves the device list and its
  /// schedules and places saved on this phone are dropped. Returns whether it was unpaired.
  Future<bool> unpairDevice({required String kidId}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return false;
    final kidUserId = kid.kidUserId;
    if (kidUserId == null || kidUserId.isEmpty) {
      errorToast("Couldn't unpair this device right now. Go back to Home, open it again and try once more.");
      return false;
    }
    final connectId = _connectIdOf(kid);
    isLoading = true;
    update();
    final res = await HomeRepo.unpairKidDevice(kidUserId: kidUserId, connectId: connectId);
    if (!res.isSuccessful) {
      isLoading = false;
      update();
      apiToast(res);
      return false;
    }
    // api2 only removes the device from this account. The MDM keeps the tablet's rules (and VPN/Private DNS
    // locks) until it's unlinked there too, so the phone would go on blocking apps and the rules would come
    // back if it's paired again. Unlinking clears them unless another parent still manages the tablet.
    // "Device not found" means it's already unlinked (api2 may do this itself).
    final unlink = await HomeRepo.unlinkGuardianDevice(connectId: connectId, externalMoolahId: Prefs.userId.get());
    final freed = unlink.isSuccessful || (unlink.message ?? "").contains("Device not found");
    isLoading = false;
    connectedKids.removeWhere((k) => k.connectId == kid.connectId && k.kidId == kid.kidId);
    Get.find<BlockRulesController>().forgetDevice(connectId);
    update();
    if (freed) {
      successToast("Device unpaired");
    } else {
      errorToast("Device unpaired, but its schedules, places and blocked apps couldn't be removed from the "
          "phone. Contact support to have them removed.");
    }
    return true;
  }

  /// Takes back a wipe from [wipeDevice], until the device has received it.
  Future<void> cancelWipe({required String kidId}) async {
    final kid = _deviceForAction(kidId);
    if (kid == null) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.cancelWipe(
        connectId: _connectIdOf(kid), externalMoolahId: Prefs.userId.get());
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast("Wipe cancelled. Nothing was erased.");
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

    // The app stays listed, marked pending, until the device has removed it: the uninstall can fail
    // (some phones ask for on-screen confirmation), and then the parent needs to see it is still there.
    if (res.isSuccessful) kid.pendingUninstalls.add(appPackage);
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast("Uninstall sent to the device");
      final commandId = res.data?["data"]?["commandId"]?.toString();
      if (commandId != null) _followUninstall(kid, commandId, appPackage);
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
    if (index < 0 && kDebugMode) {
      debugPrint("--- [DEVICES] No device for '$kidId'; list has "
          "${connectedKids.map((k) => "kidId=${k.kidId} connectId=${k.connectId}").toList()} ---");
    }
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
