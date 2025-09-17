import 'package:buddhist_compass/prefs.dart';
import 'package:flutter/material.dart';

class LocaleChangeNotifier extends ChangeNotifier {
  int _localeVal = Prefs.localeVal;

  String get localeString {
    String localeString = "en";
    switch (_localeVal) {
      case 0:
        localeString = "en";
        break;
      case 1:
        localeString = "my";
        break;
      case 2:
        localeString = "si";
        break;
      case 3:
        localeString = "km";
        break;
      case 4:
        localeString = "hi";
        break;
      default:
        localeString = "en";
    }

    return localeString;
  }

  set localeVal(int val) {
    _localeVal = Prefs.localeVal = val;
    notifyListeners();
  }
}
