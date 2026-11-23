import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/helper/env.dart';

class MixPanelEventsController extends BaseController {
  Mixpanel? mixpanel;

  init() async {
    mixpanel = await Mixpanel.init(Env.mixpanelToken,
        trackAutomaticEvents: true);
  }

  track(String event, {Map<String, dynamic>? properties}) {
    if(mixpanel != null) {
      print("MixPanel Event Triggered: $event");
      mixpanel!.track(event, properties: properties);
    }
  }
}

class MixEvents {
  static String viewLanding = "viewLanding";
  static String startGoogleSignin = "startGoogleSignin";
  static String completeGoogleSignin = "completeGoogleSignin";
  static String viewLogin1 = "viewLogin1";
  static String startLoginEmail = "startLoginEmail";
  static String errorLogin = "errorLogin";
  static String viewLogin2 = "viewLogin2";
  static String submitLogin = "submitLogin";
  static String viewSignUp1 = "viewSignUp1";
  static String startSignupEmail = "startSignupEmail";
  static String errorSignUp = "errorSignUp";
  static String viewSignUp2 = "viewSignUp2";
  static String enterFullName = "enterFullName";
  static String viewSignUp3 = "viewSignUp3";
  static String signUpComplete = "signUpComplete";
  static String connectDeviceButton = "connectDeviceButton";
  static String parentSecurityCheckStep1 = "parentSecurityCheckStep1";
  static String enterEmailForParentSecurity = "enterEmailForParentSecurity";
  static String parentSecurityCheckStep2 = "parentSecurityCheckStep2";
  static String enterPasswordForParentSecurity =
      "enterPasswordForParentSecurity";
  static String parentSecurityCheckStep3 = "parentSecurityCheckStep3";
  static String enterBdayForParentSecurity = "enterBdayForParentSecurity";
  static String parentSecurityCheckComplete = "parentSecurityCheckComplete";
  static String scanQR = "scanQR";
  static String cameraOpen = "cameraOpen";
  static String connectComplete = "connectComplete";
  static String parentSecurityError = "parentSecurityError";
  static String getKidDevices = "getKidDevices";
  static String getKidDeviceDetail = "getKidDeviceDetail";
  static String navigateToMessageTab = "navigateToMessageTab";
  static String navigateToBlockedURLsTab = "navigateToBlockedURLsTab";
  static String navigateToAppsTab = "navigateToAppsTab";
  static String viewLocation = "viewLocation";
  static String toggleWalletEnabled = "toggleWalletEnabled";
  static String navigateToMenu = "navigateToMenu";
  static String navigateToEditProfile = "navigateToEditProfile";
  static String profileUpdated = "profileUpdated";
  static String passwordChanged = "passwordChanged";
  static String appRemoved = "appRemoved";
  static String appBlocked = "appBlocked";
  static String urlBlocked = "urlBlocked";
  static String viewKidsMessage = "viewKidsMessage";
  static String viewTutorialVideo = "viewTutorialVideo";
  static String feedbackSend = "feedbackSend";
  static String navigateToPrivacyPolicy = "navigateToPrivacyPolicy";
  static String loggedOut = "loggedOut";
}
