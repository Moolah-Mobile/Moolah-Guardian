import '../endpoints.dart';
import '../models/response_model.dart';
import '../network.dart';

class HomeRepo {
  // The parent's linked devices come from api2: the MDM can only look a device up by its connect ID.
  static Future<ResponseModel> getParentKidDevices() async =>
      await Network.get(EndPoints.getParentKidDevicesUrl);

  // Removes the child's device from the parent's account on api2.
  static Future<ResponseModel> unpairKidDevice({required String kidUserId, required String connectId}) async =>
      await Network.post(EndPoints.unpairKidDevice, body: {
        "kidDeviceAccountUserID": kidUserId,
        "kidDeviceAccountConnectID": connectId,
      });

  // 3. Get the child's device(s)
  // API requires kidDeviceAccountConnectID parameter
  static Future<ResponseModel> getSyncedKidDevices({String? connectId}) async {
    String url = EndPoints.getSyncedKidDevicesUrl;

    if (connectId != null) {
      url += "?kidDeviceAccountConnectID=$connectId";
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

  // Factory reset of the child's device; the server checks the device belongs to this parent.
  static Future<ResponseModel> wipeDevice({required String connectId, required String externalMoolahId}) async =>
      await Network.post(EndPoints.wipeDeviceUrl, body: {
    'kidDeviceAccountConnectID': connectId,
    'externalMoolahId': externalMoolahId,
  });

  // Takes back a pending wipe, until the device has received it.
  // Frees the tablet on the MDM after unpairing: if no other parent is linked, its Guardian rules, VPN and
  // Private DNS locks and pending wipe are removed. The connect ID stops working ("Device not found").
  static Future<ResponseModel> unlinkGuardianDevice({required String connectId, required String externalMoolahId}) async =>
      await Network.post(EndPoints.unlinkDevice, body: {
    'kidDeviceAccountConnectID': connectId,
    'externalMoolahId': externalMoolahId,
  });

  static Future<ResponseModel> cancelWipe({required String connectId, required String externalMoolahId}) async =>
      await Network.post(EndPoints.cancelWipeUrl, body: {
    'kidDeviceAccountConnectID': connectId,
    'externalMoolahId': externalMoolahId,
  });

  // Status of one command: queued, delivered, done, failed or cancelled.
  static Future<ResponseModel> getCommandStatus(String commandId) async =>
      await Network.get("${EndPoints.getCommandStatusUrl}?commandId=${Uri.encodeQueryComponent(commandId)}");

  // The device's queued and delivered commands, newest first.
  static Future<ResponseModel> getPendingCommands(String connectId) async =>
      await Network.get("${EndPoints.getPendingCommandsUrl}?kidDeviceAccountConnectID=$connectId");

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
  static Future<ResponseModel> getNetworkHistory(String connectId, {int limit = 1000}) async =>
      await Network.get("${EndPoints.getNetworkHistoryUrl}?kidDeviceAccountConnectID=$connectId&limit=$limit");

  // 8. Screen time and device details
  static Future<ResponseModel> getAppUsage(String connectId) async =>
      await Network.get("${EndPoints.getAppUsageUrl}?kidDeviceAccountConnectID=$connectId");
      
  // 10. Basic device status
  static Future<ResponseModel> getSingleDeviceDetail(String deviceId) async =>
      await Network.get("${EndPoints.getDeviceDetails}?deviceId=$deviceId");
}
