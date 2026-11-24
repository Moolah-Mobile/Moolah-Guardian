import 'package:flutter_test/flutter_test.dart';
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/mock/mock_api.dart';
import 'package:moolah/helper/models/comms_model.dart';

// The demo account's mock backend answers the calls, messages and emergency-contact endpoints, so they can
// be tried in a debug build before the MDM has them.
void main() {
  const connect = "MOCK-CONNECT-1";
  Map<String, dynamic>? data(res) => Map<String, dynamic>.from(res.data["data"] as Map);

  test('calls and messages come back in the shape Guardian reads', () async {
    final calls = await MockApi.handle("GET", "${EndPoints.getCallLogUrl}?kidDeviceAccountConnectID=$connect");
    final page = CommsPage.fromJson(data(calls), CallEntry.fromJson);
    expect(page.items.length, 6);
    expect(page.items.first.emergencyContact, isTrue); // Mom is on the list

    final threads =
        await MockApi.handle("GET", "${EndPoints.getMessageThreadsUrl}?kidDeviceAccountConnectID=$connect");
    final t = CommsPage.fromJson(data(threads), MessageThread.fromJson).items;
    expect(t.map((x) => x.who), contains("Mom"));

    final messages = await MockApi.handle(
        "GET", "${EndPoints.getMessagesUrl}?kidDeviceAccountConnectID=$connect&number=${Uri.encodeQueryComponent(t.first.number)}");
    expect(CommsPage.fromJson(data(messages), MessageEntry.fromJson).items, isNotEmpty);
  });

  test('emergency contacts are kept, and the limits are checked', () async {
    final saved = await MockApi.handle("POST", EndPoints.setEmergencyContactsUrl, {
      "kidDeviceAccountConnectID": connect,
      "emergencyOnly": true,
      "contacts": [
        {"name": "Mom", "number": "+12125550147"},
        {"name": "Dad", "number": "(212) 555-0199"},
      ],
    });
    expect(saved.isSuccessful, isTrue);
    final read = await MockApi.handle("GET", "${EndPoints.getEmergencyContactsUrl}?kidDeviceAccountConnectID=$connect");
    final settings = EmergencySettings.fromJson(data(read));
    expect(settings.emergencyOnly, isTrue);
    expect(settings.contacts.map((c) => c.name), ["Mom", "Dad"]);

    final calls = await MockApi.handle("GET", "${EndPoints.getCallLogUrl}?kidDeviceAccountConnectID=$connect");
    expect(CommsPage.fromJson(data(calls), CallEntry.fromJson).items.where((c) => c.direction == CallDirection.blocked),
        isNotEmpty);

    final empty = await MockApi.handle("POST", EndPoints.setEmergencyContactsUrl,
        {"kidDeviceAccountConnectID": connect, "emergencyOnly": true, "contacts": []});
    expect(empty.isSuccessful, isFalse);
  });
}
