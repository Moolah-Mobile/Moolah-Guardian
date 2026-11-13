import '../endpoints.dart';
import '../models/response_model.dart';
import '../network.dart';

class HomeRepo {
  // 3. Get the child's device(s)
  // Supports listing all for a parent (externalMoolahId) or a specific device (connectId)
  static Future<ResponseModel> getSyncedKidDevices({String? externalMoolahId, String? connectId}) async {
    String url = EndPoints.getSyncedKidDevicesUrl;
    List<String> params = [];
    if (externalMoolahId != null) params.add("externalMoolahId=$externalMoolahId");
    if (connectId != null) params.add("kidDeviceAccountConnectID=$connectId");
    
    if (params.isNotEmpty) {
      url += "?${params.join("&")}";
    }
    return await Network.get(url);
  }

  // 11. Last known location
  static Future<ResponseModel> getSyncedKidDeviceLocation(String deviceId) async => 
      await Network.get("${EndPoints.getDeviceLocation}?deviceId=$deviceId");

  // 12. Send a command to the device
  static Future<ResponseModel> sendActionToDevice(
      {required String action, required String deviceId}) async => 
      await Network.post(EndPoints.sendActionToDevice, body: {
    'action': action,
    'deviceId': deviceId
  });

  // 4. List installed apps
  static Future<ResponseModel> getInstalledApps(String connectId) async =>
      await Network.get("${EndPoints.getInstalledAppsUrl}?kidDeviceAccountConnectID=$connectId");

  // 7. Uninstall an app
  static Future<ResponseModel> deleteApp({required String connectId, required String packageName}) async =>
      await Network.post(EndPoints.deleteAppUrl, body: {
    'kidDeviceAccountConnectID': connectId,
    'pkg': packageName
  });

  // 6. Replace app-blocking rules
  static Future<ResponseModel> setDeviceRestrictions({required String connectId, required List rules}) async =>
      await Network.post(EndPoints.blacklistAppUrl, body: {
    'kidDeviceAccountConnectID': connectId,
    'rules': rules
  });

  // 5. Read app-blocking rules
  static Future<ResponseModel> getDeviceRestrictions(String connectId) async =>
      await Network.get("${EndPoints.getBlacklistedAppsUrl}?kidDeviceAccountConnectID=$connectId");

  // 9. Network history
  static Future<ResponseModel> getNetworkHistory(String connectId) async =>
      await Network.get("${EndPoints.getNetworkHistoryUrl}?kidDeviceAccountConnectID=$connectId&limit=50");

  // 8. Screen time and device details
  static Future<ResponseModel> getAppUsage(String connectId) async =>
      await Network.get("${EndPoints.getAppUsageUrl}?kidDeviceAccountConnectID=$connectId");
      
  // 10. Basic device status
  static Future<ResponseModel> getSingleDeviceDetail(String deviceId) async =>
      await Network.get("${EndPoints.getDeviceDetails}?deviceId=$deviceId");
}
