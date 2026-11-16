
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs._();

  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static SharedPrefValue<int> get id => SharedPrefValue<int>('id');
  static SharedPrefValue<String> get userId => SharedPrefValue<String>('user_id');
  static SharedPrefValue<bool> get isLoggedIn => SharedPrefValue<bool>('is_logged_in');
  static SharedPrefValue<String> get email => SharedPrefValue<String>('email');
  static SharedPrefValue<String> get firstName => SharedPrefValue<String>('first_name');
  static SharedPrefValue<String> get lastName => SharedPrefValue<String>('last_name');
  static SharedPrefValue<String> get phone => SharedPrefValue<String>('phone');
  static SharedPrefValue<String> get accessToken => SharedPrefValue<String>('access_token');
  static SharedPrefValue<String> get refreshToken => SharedPrefValue<String>('refresh_token');
  static SharedPrefValue<bool> get verificationPending => SharedPrefValue<bool>('verification_pending');
  /// The last subscription `/guardian/subscription` returned for [account], as JSON. Only read when that call
  /// fails, so a paid parent keeps their features through a network error.
  static SharedPrefValue<String> subscriptionCache(String account) => SharedPrefValue<String>('subscription_cache_$account');
  static SharedPrefValue<bool> get verificationPhone => SharedPrefValue<bool>('verification_hone');


  static void clear() {
    prefs.clear();
  }
}

class SharedPrefValue<T> {
  final String key;

  SharedPrefValue(this.key);

  SharedPreferences get prefs => Prefs.prefs;

  ///Sets a value to the key provided in constructor
  void set(T value) {
    switch (T) {
      case int:
        prefs.setInt(key, value as int);
        break;
      case String:
        prefs.setString(key, value as String);
        break;
      case bool:
        prefs.setBool(key, value as bool);
        break;
    }
  }

  ///Returns the value from Shared Preferences if present,
  ///and returns null otherwise
  T? getSafe() {
    return prefs.get(key) as T?;
  }

  ///Returns the value from Shared Preferences if present,
  ///and returns a default provided in arguments otherwise
  T getOrDefault(T def) {
    return getSafe() ?? def;
  }

  ///Returns value from Shared Preferences if present,
  ///and returns a default value otherwise.
  ///Default values for different data types:
  ///int -> -1,
  ///String -> "",
  ///bool -> false,
  T get() {
    return getSafe() ?? _getDefaultValues();
  }

  T _getDefaultValues() {
    switch (T) {
      case int:
        return -1 as T;
      case String:
        return "" as T;
      case bool:
        return false as T;
      default:
        throw Exception('Unrecognized Type T');
    }
  }

  ///Removes value from Shared Preferences
  void clear() {
    prefs.remove(key);
  }
}
