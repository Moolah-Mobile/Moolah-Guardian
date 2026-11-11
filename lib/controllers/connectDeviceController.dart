import 'package:flutter/material.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/repo/connectDeviceRepo.dart';
import 'package:moolah/helper/sharedHelper.dart';
import '../util/customtoast.dart';

class ConnectDeviceController extends BaseController {

  Future<bool> linkKidByConnectCode({
    required BuildContext context,
    required String code, // This is the Device ID entered by user
    required String label, // e.g. "Kid's Tablet"
  }) async {
    isLoading = true;
    update();
    
    String externalMoolahId = Prefs.userId.get();
    print("--- [CONNECT] Starting Provision for Parent ID: $externalMoolahId ---");
    
    // Step 1: Provision Parent on MDM
    final provisionRes = await ConnectDeviceRepo.provisionDevice(
      externalMoolahId: externalMoolahId,
    );

    if (!provisionRes.isSuccessful) {
      isLoading = false;
      update();
      errorToast(provisionRes.message ?? "Provisioning failed. Please try again.");
      return false;
    }

    print("--- [CONNECT] Provision Success. Linking Device: $code ---");
    // Step 2: Link Child Device to Parent
    final linkRes = await ConnectDeviceRepo.linkDevice(
      externalMoolahId: externalMoolahId,
      deviceId: code,
      label: label,
    );

    isLoading = false;
    update();

    if (linkRes.isSuccessful) {
      successToast("Device linked successfully! You can now monitor it from your dashboard.");
      return true;
    } else {
      errorToast(linkRes.message ?? "Linking failed. Please check the Device ID.");
      return false;
    }
  }
}
