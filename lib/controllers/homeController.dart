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
    if (connectedKids.isEmpty) return;
    int index = getSelectedKidIndex(kidId);
    ResponseModel responseModel = await HomeRepo.getSingleDeviceDetail(connectedKids[index].kidId ?? kidId);

    if (responseModel.isSuccessful && responseModel.data != null) {
      final deviceJson = responseModel.data["data"];

      // getSingleDeviceDetail has no apps, usage or location, so it must not replace the getDeviceDetails result.
      connectedKids[index].deviceDetail ??= DeviceDetail.fromJson(responseModel.data);
      
      if (deviceJson != null) {
        if (deviceJson["batteryPct"] != null) {
          connectedKids[index].batteryStatus = deviceJson["batteryPct"].toString();
        }
        if (deviceJson["lastSeenAt"] != null) {
          try {
            DateTime lastSeen = DateTime.parse(deviceJson["lastSeenAt"]);
            Duration diff = DateTime.now().difference(lastSeen);
            connectedKids[index].lastActive = "${diff.inMinutes}m ago";
          } catch (e) {
            connectedKids[index].lastActive = "Now";
          }
        }
      }
    }
    update();
  }

  String connectIdFor(String kidId) => getSelectedKid(kidId).connectId ?? kidId;

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
    if (connectedKids.isEmpty || (blocked && isProtectedApp(appPackage))) return;
    isLoading = true;
    update();
    final connectId = connectIdFor(kidId);

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
      connectedKids[getSelectedKidIndex(kidId)].blockedPackages = packages.toSet();
    }
    isLoading = false;
    update();
  }

  Future<void> getInstalledApps({required String kidId}) async {
    if (connectedKids.isEmpty) return;
    isLoading = true;
    update();
    final connectId = connectIdFor(kidId);
    final kid = connectedKids[getSelectedKidIndex(kidId)];

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
    if (connectedKids.isEmpty) return;
    ResponseModel res = await HomeRepo.getNetworkHistory(connectIdFor(kidId));
    if (res.isSuccessful && res.data?["data"] is Map) {
      connectedKids[getSelectedKidIndex(kidId)].networkHistory =
          NetworkHistory.fromJson(Map<String, dynamic>.from(res.data["data"]));
    }
    update();
  }

  Future<void> sendDeviceAction({required String kidId, required String action, required String successMessage}) async {
    if (connectedKids.isEmpty) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.sendActionToDevice(
        action: action, deviceId: getSelectedKid(kidId).kidId ?? kidId);
    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast(successMessage);
    } else {
      apiToast(res);
    }
  }

  Future<void> deleteApp({required String kidId, required String appPackage}) async {
    if (connectedKids.isEmpty ||
        isProtectedApp(appPackage) ||
        isSystemApp(App(pkg: appPackage))) return;
    isLoading = true;
    update();

    ResponseModel res = await HomeRepo.deleteApp(
      connectId: connectIdFor(kidId),
      packageName: appPackage
    );

    isLoading = false;
    update();
    if (res.isSuccessful) {
      successToast("Uninstall sent to the device");
      getAppUsage(kidId: kidId);
    } else {
      apiToast(res);
    }
  }

  Future<void> getAppUsage({required String kidId}) async {
    if (connectedKids.isEmpty) return;
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.getAppUsage(connectIdFor(kidId));
    if (res.isSuccessful && res.data != null) {
      final kid = connectedKids[getSelectedKidIndex(kidId)];
      kid.deviceDetail = DeviceDetail.fromJson(res.data);
      for (final app in kid.deviceDetail?.data?.apps ?? <App>[]) {
        if (app.pkg != null && app.name != null) kid.appNames[app.pkg!] = app.name!;
      }
    }
    isLoading = false;
    update();
  }

  Future<void> enableMSMSMonitoring({required String kidId, required bool value}) async {
    isLoading = true;
    update();
    ResponseModel res = await SingleKidRepo.enableMSMSMonitoring(kidId: getSelectedKid(kidId).kidUserId ?? kidId, enable: value);
    apiToast(res);
    if(res.isSuccessful) {
       int index = getSelectedKidIndex(kidId);
       connectedKids[index].msmsMonitoringStatus = value;
    }
    isLoading = false;
    update();
  }

  Future<void> enableWallet({required String kidId, required bool value}) async {
    isLoading = true;
    update();
    ResponseModel res = await SingleKidRepo.enableWallet(kidId: getSelectedKid(kidId).kidUserId ?? kidId, enable: value);
    apiToast(res);
    if(res.isSuccessful) {
      int index = getSelectedKidIndex(kidId);
      connectedKids[index].walletEnabled = value;
    }
    isLoading = false;
    update();
  }

  Future<void> getMSMSMonitoringStatus({required String kidId}) async {
    ResponseModel responseModel = await SingleKidRepo.getMSMSMonitoringStatus(kidId: kidId);
    if(responseModel.isSuccessful && responseModel.data != null) {
      int index = getSelectedKidIndex(kidId);
      connectedKids[index].msmsMonitoringStatus = responseModel.data["msmsMonitoringStatus"];
    }
    update();
  }

  Future<void> getWalletStatus({required String kidId}) async {
    ResponseModel responseModel = await SingleKidRepo.getWalletStatus(kidId: kidId);
    if(responseModel.isSuccessful && responseModel.data != null) {
      int index = getSelectedKidIndex(kidId);
      connectedKids[index].walletEnabled = responseModel.data["walletEnabled"];
    }
    update();
  }

  Future<void> getBlacklistUrls({String? kidId}) async {
    if (kidId == null) return;
    ResponseModel responseModel = await SingleKidRepo.getBlacklistUrls(kidId: getSelectedKid(kidId).kidUserId ?? "");
    if (responseModel.isSuccessful && responseModel.data != null) {
      connectedKids[getSelectedKidIndex(kidId)].blockedUrls = BlockedUrlModel.fromJson(responseModel.data);
    }
    update();
  }

  Future<void> addBlacklistUrl({String? kidId, String? url}) async {
    if(kidId == null || (url ?? "").isEmpty) return;
    isLoading = true;
    update();
    ResponseModel responseModel = await SingleKidRepo.addBlacklistUrl(kidId: connectedKids[getSelectedKidIndex(kidId)].kidUserId, url: url);
    apiToast(responseModel);
    if(responseModel.isSuccessful){
      connectedKids[getSelectedKidIndex(kidId)].blockedUrls?.blockedUrlsData?.blockedUrls?.add(url ?? "");
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

  int getSelectedKidIndex(String kidId) {
    for (int i = 0; i < connectedKids.length; i++) {
      if (kidId == connectedKids[i].kidId || kidId == connectedKids[i].connectId) {
        return i;
      }
    }
    return 0;
  }

  Kid getSelectedKid(String kidId) => connectedKids[getSelectedKidIndex(kidId)];

  void logout() {
    connectedKids.clear();
  }
}
