# Bug Fix: MDM Endpoint Parameter Correction

**Date:** 2026-11-13
**Issue:** Incorrect query parameter for `getConnectedKidDevices` endpoint
**Status:** ✅ Fixed

---

## 🐛 Problem

The app was calling the MDM `getConnectedKidDevices` endpoint with the wrong parameter:

**❌ Incorrect (Before):**
```
moolahmdm.com/rest/getConnectedKidDevices?externalMoolahId=14
```

**✅ Correct (After):**
```
moolahmdm.com/rest/getConnectedKidDevices?kidDeviceAccountConnectID=EMULATOR36X4X9X0
```

Or call without parameters to get all devices for the authenticated guardian:
```
moolahmdm.com/rest/getConnectedKidDevices
```

---

## 📋 Changes Made

### 1. Updated `lib/helper/repo/homeRepo.dart`

**Before:**
```dart
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
```

**After:**
```dart
static Future<ResponseModel> getSyncedKidDevices({String? connectId}) async {
  String url = EndPoints.getSyncedKidDevicesUrl;

  if (connectId != null) {
    url += "?kidDeviceAccountConnectID=$connectId";
  }

  return await Network.get(url);
}
```

**Changes:**
- ❌ Removed incorrect `externalMoolahId` parameter
- ✅ Kept only `kidDeviceAccountConnectID` (connectId)
- ✅ Supports calling without parameters for listing all guardian devices

---

### 2. Updated `lib/controllers/homeController.dart`

**Before:**
```dart
Future<void> getSyncedKidDevices() async {
  print("--- [MDM] Fetching Synced Devices ---");
  String parentId = Prefs.userId.get();

  ResponseModel responseModel = await HomeRepo.getSyncedKidDevices(externalMoolahId: parentId);
  apiToast(responseModel);
```

**After:**
```dart
Future<void> getSyncedKidDevices() async {
  print("--- [MDM] Fetching Synced Devices ---");

  // Call without parameters to get all devices for this authenticated parent
  // The API key in the header identifies the parent/guardian
  ResponseModel responseModel = await HomeRepo.getSyncedKidDevices();
  apiToast(responseModel);
```

**Changes:**
- ❌ Removed `parentId` variable (no longer needed)
- ❌ Removed incorrect `externalMoolahId: parentId` parameter
- ✅ Now calls without parameters to get all devices
- ✅ Authentication is handled via API key in headers

---

## 🔍 Root Cause

The code was incorrectly trying to use `externalMoolahId` (the parent/guardian ID) as a query parameter. However, according to the MDM API documentation:

1. The `getConnectedKidDevices` endpoint uses `kidDeviceAccountConnectID` to query a specific device
2. When called without parameters, it returns all devices for the authenticated guardian (identified by the API key in headers)

---

## ✅ Verification

The API key is properly set and auto-injected into all MDM requests:

**API Key Configuration:** `lib/helper/endpoints.dart:6`
```dart
static String mdmApiKey = "d927eaf4dbfffdd18836301d5698e4772d75505c9cc464761920c04df45b09af";
```

**Auto-Injection:** `lib/helper/network.dart:87-89`
```dart
if (url.contains(EndPoints.mdmBaseUrl)) {
  header.addAll({"x-api-key": EndPoints.mdmApiKey});
}
```

---

## 📊 Expected Behavior

### Scenario 1: Get All Devices for Guardian
```dart
await HomeRepo.getSyncedKidDevices();
```
**URL:** `https://moolahmdm.com/rest/getConnectedKidDevices`
**Returns:** All devices linked to the authenticated guardian

### Scenario 2: Get Specific Device
```dart
await HomeRepo.getSyncedKidDevices(connectId: "EMULATOR36X4X9X0");
```
**URL:** `https://moolahmdm.com/rest/getConnectedKidDevices?kidDeviceAccountConnectID=EMULATOR36X4X9X0`
**Returns:** Single device with that connect ID

---

## 🧪 Testing

To verify the fix:

1. **Launch the app**
2. **Navigate to Home screen**
3. **Check console logs for:**
   ```
   --- [MDM] Fetching Synced Devices ---
   🔵 GET REQUEST
   📍 URL: https://moolahmdm.com/rest/getConnectedKidDevices
   📋 Headers: {x-api-key: d927eaf4...}
   ```
4. **Verify the API response includes the device list**

---

## 📝 Notes

- The MDM API uses the `x-api-key` header for guardian authentication
- The `externalMoolahId` is used during the `/guardian/provision` step, not for querying devices
- The correct flow is:
  1. `POST /guardian/provision` with `externalMoolahId` → Creates guardian
  2. `POST /guardian/link` → Links device to guardian
  3. `GET /getConnectedKidDevices` → Lists devices (no parameters needed if using API key auth)

---

**Fixed By:** Claude Code
**Verified:** Ready for testing
