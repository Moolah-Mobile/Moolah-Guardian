import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/connect_device/connect_device_screen.dart';
import 'package:moolah/screens/forgot_password/verify_reset_otp_screen.dart';
import 'package:moolah/screens/forgot_password/widget/check_your_email.dart';
import 'package:moolah/screens/home/home.dart';
import 'package:moolah/screens/login/login.dart';
import 'package:moolah/screens/login/screens/enter_email_login.dart';
import 'package:moolah/screens/login/screens/enter_password_login.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/widget/password_reset.dart';
import 'package:moolah/screens/main_menu_profile/screens/contact_us/contact_us.dart';
import 'package:moolah/screens/main_menu_profile/screens/edit_profile/edit_profile.dart';
import 'package:moolah/screens/main_menu_profile/screens/profile/profile.dart';
import 'package:moolah/screens/onboard/onboard.dart';
import 'package:moolah/screens/signup/screens/enter_dob.dart';
import 'package:moolah/screens/signup/screens/enter_email.dart';
import 'package:moolah/screens/signup/screens/enter_full_name.dart';
import 'package:moolah/screens/signup/screens/enter_password.dart';
import 'package:moolah/screens/signup/screens/enter_phone_number.dart';
import 'package:moolah/screens/signup/screens/enter_username.dart';
import 'package:moolah/screens/signup/signup.dart';
import 'package:moolah/screens/subscription_screen/subscription_screen.dart';
import 'package:moolah/screens/sync_device_detail_screen/screens/live_location.dart';

import '../screens/forgot_password/forgot_password.dart';
import '../screens/main_menu_profile/main_menu_profile.dart';
import '../screens/main_menu_profile/screens/change_password/change_password.dart';
import '../screens/main_menu_profile/screens/feedback/feedback.dart';
import '../screens/main_menu_profile/screens/privacy_policy/privacy_policy.dart';
import '../screens/main_menu_profile/screens/tutorial_screen/tutorial_screen.dart';
import '../screens/otp_verification/otp_verification.dart';
import '../screens/splash/splash.dart';
import '../screens/sync_device_detail_screen/sync_device_detail_screen.dart';

class RouteHelper {
  static Map<String, WidgetBuilder> routes = {
    Splash.screenName: (_) => const Splash(),
    OnBoard.screenName: (_) => const OnBoard(),
    SignUp.screenName: (_) => const SignUp(),
    EnterEmailSignUp.screenName: (_) => const EnterEmailSignUp(),
    EnterFullNameSignUp.screenName: (_) => const EnterFullNameSignUp(),
    EnterPasswordSignUp.screenName: (_) => const EnterPasswordSignUp(),
    EnterPhoneNumberSignUp.screenName: (_) => const EnterPhoneNumberSignUp(),
    EnterDobSignUp.screenName: (_) => const EnterDobSignUp(),
    EnterUsernameSignUp.screenName: (_) => const EnterUsernameSignUp(),
    SubscriptionScreen.screenName: (_) => const SubscriptionScreen(),
    Home.screenName: (_) => const Home(),
    Login.screenName: (c) => Login(fromSignup: _args(c)?["fromSignup"] ?? false),
    EnterEmailLogin.screenName: (c) => EnterEmailLogin(fromSignup: _args(c)?["fromEnterEmailSignUp"] ?? false),
    EnterPasswordLogin.screenName: (c) => EnterPasswordLogin(fromSignup: _args(c)?["fromSignup"] ?? false),
    ConnectDeviceScreen.screenName: (_) => const ConnectDeviceScreen(),
    SyncDeviceDetailScreen.screenName: (c) => SyncDeviceDetailScreen(kidId: _args(c)?["kidId"]?.toString() ?? ""),
    MainMenuProfile.screenName: (_) => const MainMenuProfile(),
    Profile.screenName: (_) => const Profile(),
    EditProfile.screenName: (_) => const EditProfile(),
    ChangePassword.screenName: (_) => const ChangePassword(),
    PasswordReset.screenName: (_) => const PasswordReset(),
    ForgotPassword.screenName: (_) => const ForgotPassword(),
    CheckYourEmail.screenName: (_) => const CheckYourEmail(),
    VerifyResetOTPScreen.screenName: (_) => const VerifyResetOTPScreen(),
    OtpVerification.screenName: (_) => const OtpVerification(),
    LiveLocation.screenName: (c) => LiveLocation(
          lat: (_args(c)?["lat"] as num?)?.toDouble(),
          long: (_args(c)?["long"] as num?)?.toDouble(),
          deviceId: _args(c)?["deviceId"]?.toString() ?? "",
        ),
    FeedbackScreen.screenName: (_) => const FeedbackScreen(),
    ContactUsScreen.screenName: (_) => const ContactUsScreen(),
    PrivacyScreen.screenName: (_) => const PrivacyScreen(),
    TutorialScreen.screenName: (_) => const TutorialScreen(),
  };
}

/// The arguments this route was opened with. `Get.arguments` holds the arguments of the latest navigation,
/// so a page rebuilt after another screen opened (for example Blocked Apps) lost its own: the device summary
/// then had no device ID, crashed, and earlier sent actions to the first device in the list.
Map? _args(BuildContext context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  return arguments is Map ? arguments : null;
}
