import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/comms_model.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/network.dart';

/// Calls, messages and emergency contacts on the child's phone, from the MDM.
class CommsRepo {
  static String _q(String v) => Uri.encodeQueryComponent(v);

  static Future<ResponseModel> getCallLog(String connectId) async =>
      await Network.get("${EndPoints.getCallLogUrl}?kidDeviceAccountConnectID=${_q(connectId)}&limit=500");

  static Future<ResponseModel> getMessageThreads(String connectId) async =>
      await Network.get("${EndPoints.getMessageThreadsUrl}?kidDeviceAccountConnectID=${_q(connectId)}&limit=200");

  static Future<ResponseModel> getMessages(String connectId, String number) async => await Network.get(
      "${EndPoints.getMessagesUrl}?kidDeviceAccountConnectID=${_q(connectId)}&number=${_q(number)}&limit=500");

  static Future<ResponseModel> getEmergencyContacts(String connectId) async =>
      await Network.get("${EndPoints.getEmergencyContactsUrl}?kidDeviceAccountConnectID=${_q(connectId)}");

  static Future<ResponseModel> setEmergencyContacts(
          {required String connectId, required bool emergencyOnly, required List<EmergencyContact> contacts}) async =>
      await Network.post(EndPoints.setEmergencyContactsUrl, body: {
        "kidDeviceAccountConnectID": connectId,
        "emergencyOnly": emergencyOnly,
        "contacts": contacts.map((c) => c.toJson()).toList(),
      });
}
