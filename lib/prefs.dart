// import to copy////////////////////
//import 'package:tipitaka_pali/services/prefs.dart';

// Shared prefs package import
import 'package:shared_preferences/shared_preferences.dart';

// preference names
const String targetNamePref = "targetName";
const String targetLatPref = "targetLat";
const String targetLongPref = "targetLong";
const String vibeOnPref = 'vibeOn';
const String userDest1Pref = "userDest1";
const String userDest1LatPref = "userDest1Lat";
const String userDest1LongPref = "userDest1Long";

const String defaultTargetName = "Bodh Gaya";
const double defaultTargetLat = 24.6962;
const double defaultTargetLong = 84.9901;
const bool defaultVibeOn = false;
const String defaultUserDest1 = "";
const double defaultUserDest1Lat = 0.0;
const double defaultUserDest1Long = 0.0;

const String LOCALEVAL = "localeVal";
const int DEFAULT_LOCALEVAL = 0;

class Prefs {
  // prevent object creation
  Prefs._();
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  static String get targetName =>
      instance.getString(targetNamePref) ?? defaultTargetName;
  static set targetName(String value) =>
      instance.setString(targetNamePref, value);

  static String get userDest1 =>
      instance.getString(userDest1Pref) ?? defaultUserDest1;
  static set userDest1(String value) =>
      instance.setString(userDest1Pref, value);

  static double get userDest1Lat =>
      instance.getDouble(userDest1LatPref) ?? defaultUserDest1Lat;
  static set userDest1Lat(double value) =>
      instance.setDouble(userDest1LatPref, value);

  static double get userDest1Long =>
      instance.getDouble(userDest1LongPref) ?? defaultUserDest1Long;
  static set userDest1Long(double value) =>
      instance.setDouble(userDest1LongPref, value);

  static double get targetLat =>
      instance.getDouble(targetLatPref) ?? defaultTargetLat;
  static set targetLat(double value) =>
      instance.setDouble(targetLatPref, value);

  static double get targetLong =>
      instance.getDouble(targetLongPref) ?? defaultTargetLong;
  static set targetLong(double value) =>
      instance.setDouble(targetLongPref, value);

  static bool get vibeOn => instance.getBool(vibeOnPref) ?? defaultVibeOn;
  static set vibeOn(bool value) => instance.setBool(vibeOnPref, value);

  static int get localeVal => instance.getInt(LOCALEVAL) ?? DEFAULT_LOCALEVAL;
  static set localeVal(int value) => instance.setInt(LOCALEVAL, value);
}
