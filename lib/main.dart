import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:flutter_ironsource_x/ironsource.dart';
import 'package:get/get.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:moolah/helper/route_helper.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/screens/main_menu_profile/main_menu_profile.dart';
import 'package:moolah/screens/splash/splash.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/mixpanel_events.dart';
import 'package:moolah/util/theme/app_theme.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import './helper/get_di/get_di.dart' as get_di;
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw Google Maps natively (hybrid composition) on Android. Through a texture, some phones' graphics
  // drivers show only the map's overlays (the Google logo) and never the map itself, while lite maps
  // still draw.
  final maps = GoogleMapsFlutterPlatform.instance;
  if (maps is GoogleMapsFlutterAndroid) maps.useAndroidViewSurface = true;
  await Prefs.init();
  // Set before anything can open the payment sheet; initSDKS() below isn't awaited.
  Stripe.publishableKey = getStripeSecretKey();
  get_di.init();
  initSDKS();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: RouteHelper.routes,
      initialRoute: Splash.screenName,
      // Debug builds print GetX's route and controller create/delete messages to logcat.
      enableLog: kDebugMode,
      logWriterCallback: (text, {bool isError = false}) {
        if (kDebugMode) debugPrint("[GETX] $text");
      },
    );
  }
}


void initSDKS() async {

  /// Firebase
  print("Initializing Firebase");
  await Firebase.initializeApp();
  initCrashlytics();

  /// Mixpanel SDK
  print("Initializing Mixpanel");
  await Mixpanel.init("b2c2ea88edf4da993cb3572c6f126f6c", trackAutomaticEvents: true);

  /// OneSignal SDK
  print("Initializing OneSignal");
  initOneSignal();

  ///Mixpanel
  await Get.find<MixPanelEventsController>().init();


}



void initCrashlytics() {

  FlutterError.onError = (errorDetails) {
      // Debug builds also print the error and its stack to the console (logcat); otherwise only
      // Crashlytics sees it.
      if (kDebugMode) FlutterError.presentError(errorDetails);
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  };
}


Future<void> initOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("476bba3d-a3d6-4b7c-b5c2-4eaefdb30bc3");
  print("OneSignal.Notifications.permission");
  print(OneSignal.Notifications.permission);
  if(!OneSignal.Notifications.permission) {
    print("OneSignal.Notifications.permission::1");
    await OneSignal.Notifications.requestPermission(true);
    print("OneSignal.Notifications.permission::2");
    OneSignal.Notifications.addPermissionObserver((permission) {
      print("Has permission $permission");

      if(!permission){
        OneSignal.Notifications.requestPermission(true);
      }
    });
  }
}
