import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/blocked_url_model.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/helper/models/message_model.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/models/thread_model.dart';
import 'package:moolah/helper/network.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/util/customtoast.dart';
import '../helper/repo/singleKidRepo.dart';

class HomeController extends BaseController {
  List<Kid> connectedKids = [];

  Future<void> getSyncedKidDevices() async {
    print("--- [MDM] Fetching Synced Devices ---");
    ResponseModel responseModel = await HomeRepo.getSyncedKidDevices();
    apiToast(responseModel);

    if (responseModel.isSuccessful && responseModel.data != null) {
      final data = responseModel.data["data"];
      if (data != null && data["devices"] != null) {
        List<Kid> temp = [];
        var devicesList = data["devices"] as List;
        
        for (var dev in devicesList) {
          temp.add(Kid.fromJson(dev));
        }
        connectedKids = temp;

        // Automatically fetch deep details for each device
        for (var kid in connectedKids) {
          if (kid.connectId != null) {
            getDeviceDetail(kidId: kid.connectId!);
          }
        }
      }
    }
    update();
  }

  Future<void> getDeviceDetail({required String kidId}) async {
    ResponseModel responseModel = await HomeRepo.getSingleDeviceDetail(kidId);
    
    if (responseModel.isSuccessful && responseModel.data != null) {
      final deviceJson = responseModel.data["data"];
      int index = getSelectedKidIndex(kidId);
      
      connectedKids[index].deviceDetail = DeviceDetail.fromJson(responseModel.data);
      
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
    update();
  }

  Future<void> blacklistApp({required String kidId, required String appPackage}) async {
    isLoading = true;
    update();

    final rules = [
      {
        "id": "always-off",
        "type": "time",
        "packages": [appPackage],
        "from": "00:00",
        "to": "23:59"
      }
    ];

    ResponseModel res = await HomeRepo.setDeviceRestrictions(
      connectId: kidId, 
      rules: rules
    );
    
    apiToast(res);
    isLoading = false;
    update();
    if (res.isSuccessful) getDeviceDetail(kidId: kidId);
  }

  Future<void> deleteApp({required String kidId, required String appPackage}) async {
    isLoading = true;
    update();
    
    ResponseModel res = await HomeRepo.deleteApp(
      connectId: kidId, 
      packageName: appPackage
    );
    
    apiToast(res);
    isLoading = false;
    update();
    if (res.isSuccessful) getDeviceDetail(kidId: kidId);
  }

  Future<void> getAppUsage({required String kidId}) async {
    isLoading = true;
    update();
    ResponseModel res = await HomeRepo.getAppUsage(kidId);
    if (res.isSuccessful && res.data != null) {
       // Optional: Update detailed usage models here
    }
    isLoading = false;
    update();
  }

  Future<void> enableMSMSMonitoring({required String kidId, required bool value}) async {
    isLoading = true;
    update();
    ResponseModel res = await SingleKidRepo.enableMSMSMonitoring(kidId: kidId, enable: value);
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
    ResponseModel res = await SingleKidRepo.enableWallet(kidId: kidId, enable: value);
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
    ResponseModel responseModel = await SingleKidRepo.getBlacklistUrls(kidId: getSelectedKid(kidId).kidId ?? "");
    if (responseModel.isSuccessful && responseModel.data != null) {
      connectedKids[getSelectedKidIndex(kidId)].blockedUrls = BlockedUrlModel.fromJson(responseModel.data);
    }
    update();
  }

  Future<void> addBlacklistUrl({String? kidId, String? url}) async {
    if(kidId == null || (url ?? "").isEmpty) return;
    isLoading = true;
    update();
    ResponseModel responseModel = await SingleKidRepo.addBlacklistUrl(kidId: connectedKids[getSelectedKidIndex(kidId)].kidId, url: url);
    apiToast(responseModel);
    if(responseModel.isSuccessful){
      connectedKids[getSelectedKidIndex(kidId)].blockedUrls?.blockedUrlsData?.blockedUrls?.add(url ?? "");
    }
    isLoading = false;
    update();
  }

  Future<void> getMessageThreads({String? kidId}) async {
    // MDM doesn't currently provide threads, stubbed for UI
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
