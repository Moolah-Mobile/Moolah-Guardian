import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/models/user_model1.dart';
import 'package:moolah/helper/repo/authRepo.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/screens/home/home.dart';
import 'package:moolah/screens/login/login.dart';
import 'package:moolah/screens/otp_verification/otp_verification.dart';
import 'package:moolah/util/customtoast.dart';

import '../helper/models/user_model.dart';
import '../screens/forgot_password/widget/check_your_email.dart';
import '../screens/main_menu_profile/screens/change_password/widget/password_reset.dart';
import '../screens/subscription_screen/subscription_screen.dart';
import '../util/mixpanel_events.dart';
import 'homeController.dart';

class AuthController extends BaseController {
  UserModel? user;
  UserModel1? user1;

  String emailGlob = "";
  String passwordGlob = "";
  String fullNameGlob = "";
  String phoneGlob = "";
  String phoneWithoutCC = "";
  String countryCode = "";
  String dobGlob = "";
  DateTime? dobGlobDateTime;
  String usernameGlob = "";


  Future<void> login() async {
    if (isLoading) return;
    try {
      isLoading = true;
      update(); 
      
      print("--- [LOGIN] Starting for: $emailGlob ---");
      var r = await AuthRepo.login(emailGlob.trim(), passwordGlob);
      apiToast(r);
      
      if (r.isSuccessful && r.data != null) {
        var userData;
        if (r.data["data"] is List && r.data["data"].isNotEmpty) {
          userData = r.data["data"][0];
        } else if (r.data["data"] is Map) {
          userData = r.data["data"];
        } else {
          userData = r.data["user"] ?? r.data;
        }

        if (userData != null && (userData["id"] != null || userData["email"] != null)) {
          try {
            print("--- [LOGIN] Parsing Model ---");
            user1 = UserModel1.fromJson(userData);
            
            // Save Session
            if (r.data["tokens"] != null) {
              Prefs.accessToken.set(r.data["tokens"]["access"]?["token"]?.toString() ?? '');
              Prefs.refreshToken.set(r.data["tokens"]["refresh"]?["token"]?.toString() ?? '');
            } else if (userData["token"] != null) {
              Prefs.accessToken.set(userData["token"].toString());
            }
            
            Prefs.userId.set((userData["id"] ?? userData["_id"] ?? 0).toString());
            Prefs.isLoggedIn.set(true);
            Prefs.email.set(userData["email"]?.toString() ?? emailGlob);
            Prefs.firstName.set(user1?.firstName ?? "");
            Prefs.lastName.set(user1?.lastName ?? "");
            Prefs.phone.set(user1?.phone ?? "");
            
            print("--- [LOGIN] SUCCESS. Releasing UI... ---");
            
            isLoading = false;
            update();
            
            await Future.delayed(const Duration(milliseconds: 200));
            
            print("--- [LOGIN] Navigating to Subscription ---");
            Get.offAllNamed(SubscriptionScreen.screenName);
            return; 
          } catch (e) {
            print("--- [LOGIN] Data Parsing Crash: $e ---");
            errorToast("System mismatch: Data format error.");
          }
        } else {
          errorToast("User account details not found.");
        }
      }
    } catch (e) {
      print("--- [LOGIN] Critical Error: $e ---");
      errorToast("Connection timeout. Please retry.");
    } finally {
      isLoading = false;
      update(); 
    }
  }


  Future<void> signup() async {
    if (isLoading) return;
    try {
      isLoading = true;
      update();
      var r = await AuthRepo.signUp(emailGlob.trim(), passwordGlob, fullNameGlob, fullNameGlob, phoneGlob, dobGlob, usernameGlob);
      apiToast(r);
      if (r.isSuccessful && r.data != null) {
        var userData = (r.data["data"] is List && r.data["data"].isNotEmpty) ? r.data["data"][0] : r.data["data"];
        userData ??= r.data["user"];

        if (userData != null) {
          user1 = UserModel1.fromJson(userData);
          
          if (r.data is Map && r.data['tokens'] != null) {
            Prefs.accessToken.set(r.data["tokens"]["access"]?["token"] ?? '');
            Prefs.refreshToken.set(r.data["tokens"]["refresh"]?["token"] ?? '');
          }

          Prefs.userId.set((userData["id"] ?? userData["_id"] ?? 0).toString()); 
          Prefs.isLoggedIn.set(true);
          Prefs.email.set(userData["email"]?.toString() ?? emailGlob);
          Prefs.phone.set(phoneGlob);
          
          await AuthRepo.sendMobileOtp(phoneGlob);
          Prefs.verificationPending.set(true);
          
          isLoading = false;
          update();
          Get.offAllNamed(OtpVerification.screenName);
          return;
        }
      }
    } catch (e) {
      errorToast("Registration failed.");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> verifyOtp(String otp) async {
    try {
      isLoading = true;
      update();
      var res = await AuthRepo.verifyMobileOtp(phoneGlob, otp);
      apiToast(res);
      if(res.isSuccessful){
        Prefs.verificationPending.set(false);
        isLoading = false;
        update();
        Get.offAllNamed(SubscriptionScreen.screenName);
      }
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> forgotPassword(String email) async {
    if (isLoading) return;
    try {
      isLoading = true;
      update();
      var res = await AuthRepo.forgotPassword(email.trim());
      apiToast(res);
      if (res.isSuccessful) {
        isLoading = false;
        update();
        Get.toNamed(CheckYourEmail.screenName, arguments: email.trim());
      }
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    if (isLoading) return;
    try {
      isLoading = true;
      update();
      var res = await AuthRepo.resetPassword(email.trim(), otp, password);
      apiToast(res);
      if (res.isSuccessful) {
        isLoading = false;
        update();
        Get.offAllNamed(PasswordReset.screenName);
      }
    } catch (e) {
      errorToast("Reset failed. Check OTP.");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> googleSignIn() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> refreshToken() async {
    try {
      var res = await AuthRepo.refreshToken(Prefs.refreshToken.get());
      if (res.isSuccessful && res.data != null) {
        if (res.data["access"] != null) Prefs.accessToken.set(res.data["access"]["token"] ?? "");
        if (res.data["refresh"] != null) Prefs.refreshToken.set(res.data["refresh"]["token"] ?? "");
      }
    } catch (e) {
      print("Refresh Error: $e");
    }
  }

  Future<void> logout() async {
    Prefs.accessToken.clear();
    Prefs.refreshToken.clear();
    Prefs.userId.clear();
    Prefs.isLoggedIn.clear();
    Prefs.email.clear();
    Get.find<HomeController>().logout();
    IronSource.hideBanner();
  }
}
