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
      var r = await AuthRepo.login(emailGlob, passwordGlob);
      if (r.isSuccessful && r.data != null && r.data["data"] != null && r.data["data"].isNotEmpty) {
        final userData = r.data["data"][0];
        user1 = UserModel1.fromJson(userData);

        if (r.data["tokens"] != null) {
          Prefs.accessToken.set(r.data["tokens"]["access"]?["token"] ?? '');
          Prefs.refreshToken.set(r.data["tokens"]["refresh"]?["token"] ?? '');
        }
        
        Prefs.userId.set((userData["id"] ?? 0).toString());
        Prefs.isLoggedIn.set(true);
        Prefs.email.set(userData["email"] ?? '');
        Prefs.firstName.set(user1?.firstName ?? "");
        Prefs.lastName.set(user1?.lastName ?? "");
        Prefs.phone.set(user1?.phone ?? "");
        Get.offAllNamed(SubscriptionScreen.screenName);
      } else {
        Get.find<MixPanelEventsController>().track(MixEvents.errorLogin);
        errorToastShow(r.data);
      }
    } catch (e) {
      errorToast("An unexpected error occurred during login.");
    }

    isLoading = false;
  }


  Future<void> signup() async {
    Prefs.accessToken.clear();
    if (isLoading) return;
    try {
      isLoading = true;
      var r = await AuthRepo.signUp(emailGlob, passwordGlob, fullNameGlob, fullNameGlob, phoneGlob, dobGlob, usernameGlob);
      if (r.isSuccessful && r.data != null && r.data["data"] != null && r.data["data"].isNotEmpty) {
        final userData = r.data["data"][0];

        user1 = UserModel1.fromJson(userData);

        if (r.data['tokens'] != null) {
          Prefs.accessToken.set(r.data["tokens"]["access"]?["token"] ?? '');
          Prefs.refreshToken.set(r.data["tokens"]["refresh"]?["token"] ?? '');
        }

        Prefs.userId.set((userData["id"] ?? 0).toString()); 
        Prefs.isLoggedIn.set(true);
        Prefs.email.set(userData["email"] ?? '');
        Prefs.phone.set(phoneGlob);
        
        Prefs.firstName.set(user1?.firstName ?? "");
        Prefs.lastName.set(user1?.lastName ?? "");

        var res1 = await AuthRepo.sendMobileOtp(phoneGlob);
        if (res1.isSuccessful) {
          successToast("OTP sent!");
        }
        Prefs.verificationPending.set(true);
        Get.offAllNamed(OtpVerification.screenName);
      } else {
        Get.find<MixPanelEventsController>().track(MixEvents.errorSignUp);
        errorToastShow(r.data);
      }
    } catch (e, stackTrace) {
      Get.find<MixPanelEventsController>().track(MixEvents.errorSignUp);
      print("--- SIGNUP FAILED ---");
      print("Error: $e");
      errorToast("An unexpected error occurred during signup.");
    }

    isLoading = false;
  }

  Future<void> verifyOtp(String otp) async {
    isLoading = true;
    var res = await AuthRepo.verifyMobileOtp(phoneGlob ,otp);
    apiToast(res);
    if(res.isSuccessful){
      Prefs.verificationPending.set(false);
      Get.offAllNamed(SubscriptionScreen.screenName);
    }
    isLoading = false;
  }

  Future<void> forgotPassword(String email) async {
    if (isLoading) return;
    isLoading = true;
    var res = await AuthRepo.forgotPassword(email);
    if (res.isSuccessful) {
      successToast("Reset instructions sent to your email");
      Get.toNamed(CheckYourEmail.screenName, arguments: email);
    } else {
      errorToastShow(res.data);
    }
    isLoading = false;
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    if (isLoading) return;
    isLoading = true;
    var res = await AuthRepo.resetPassword(email, otp, password);
    if (res.isSuccessful) {
      successToast("Password reset successfully");
      Get.offAllNamed(PasswordReset.screenName);
    } else {
      errorToastShow(res.data);
    }
    isLoading = false;
  }

  Future<void>  googleSignIn() async {
    Get.find<MixPanelEventsController>().track(MixEvents.startGoogleSignin);

    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
    );
    try {
      await _googleSignIn.signIn().then((value) => print(value));
    } catch (error) {
      print(error);
    }
  }


  Future<void> refreshToken() async {
    try {
      var res = await AuthRepo.refreshToken(Prefs.refreshToken.get());
      if (res.isSuccessful && res.data != null) {
        if (res.data["access"] != null) {
          Prefs.accessToken.set(res.data["access"]["token"] ?? "");
        }
        if (res.data["refresh"] != null) {
          Prefs.refreshToken.set(res.data["refresh"]["token"] ?? "");
        }
        print("Token Refreshed Successfully");
      } else {
        print("Token Refresh Failed: ${res.data}");
      }
    } catch (e) {
      print("Error in refreshToken: $e");
    }
  }

  Future<void> logout() async {
    Prefs.accessToken.clear();
    Prefs.refreshToken.clear();
    Prefs.userId.clear();
    Prefs.isLoggedIn.clear();
    Prefs.email.clear();
    Prefs.firstName.clear();
    Prefs.lastName.clear();
    Get.find<HomeController>().logout();
    IronSource.hideBanner();
  }
}
