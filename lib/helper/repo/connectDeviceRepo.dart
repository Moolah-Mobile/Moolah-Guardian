import '../endpoints.dart';
import '../models/response_model.dart';
import '../network.dart';

class ConnectDeviceRepo {
  // 1. Create or reuse a parent
  static Future<ResponseModel> provisionDevice({
    required String externalMoolahId,
  }) async {
    return await Network.post(EndPoints.provisionDevice, body: {
      "externalMoolahId": externalMoolahId,
    });
  }

  // 2. Link a child's tablet
  static Future<ResponseModel> linkDevice({
    required String externalMoolahId,
    required String connectId,
    required String label,
  }) async {
    return await Network.post(EndPoints.linkDevice, body: {
      "externalMoolahId": externalMoolahId,
      "deviceId": connectId,
      "kidDeviceAccountConnectID": connectId,
      "label": label
    });
  }
}
