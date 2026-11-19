import '../endpoints.dart';
import '../models/response_model.dart';
import '../network.dart';

class ConnectDeviceRepo {
  // api2 keeps the parent's device list, which the home screen reads.
  static Future<ResponseModel> linkKidByConnectCode({
    required String code,
    required String parentFullName,
  }) async {
    return await Network.post(EndPoints.linkKidByConnectCode, body: {
      "code": code,
      "parentFullName": parentFullName,
    });
  }

  // 1. Create or reuse a parent
  static Future<ResponseModel> provisionDevice({
    required String externalMoolahId,
  }) async {
    return await Network.post(EndPoints.provisionDevice, body: {
      "externalMoolahId": externalMoolahId,
    });
  }

  // 2. Link a child's tablet. [deviceId] is the tablet's device number, IMEI or serial; [connectId] is
  // the ID api2 already uses for this parent–tablet pair, which the MDM stores as is.
  static Future<ResponseModel> linkDevice({
    required String externalMoolahId,
    required String deviceId,
    required String connectId,
    required String label,
  }) async {
    return await Network.post(EndPoints.linkDevice, body: {
      "externalMoolahId": externalMoolahId,
      "deviceId": deviceId,
      "kidDeviceAccountConnectID": connectId,
      "label": label
    });
  }
}
