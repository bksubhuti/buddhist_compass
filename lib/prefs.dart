// import to copy////////////////////
//import 'package:tipitaka_pali/services/prefs.dart';

// Shared prefs package import

import 'package:shared_preferences/shared_preferences.dart';

// preference names
const String targetNamePref = "targetName";
const String targetLatPref = "targetLat";
const String targetLongPref = "targetLong";
const String vibeOnPref = 'vibeOn';

const String defaultTargetName = "Bodh Gaya";
const double defaultTargetLat = 24.6962;
const double defaultTargetLong = 84.9901;
const bool defaultVibeOn = false;

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

  // ===========================================================================
  // Helpers
/*
  static Color getChosenColor() {
    switch (Prefs.selectedPageColor) {
      case 0:
        return Color(Colors.white.value);
      case 1:
        return const Color(seypia);
      case 2:
        return Color(Colors.black.value);
      default:
        return Color(Colors.white.value);
    }
  }
  */
}
