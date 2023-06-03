import 'package:buddhist_compass/prefs.dart';
import 'package:flutter/material.dart';

import 'compass_page.dart';

void main() async {
// Required for async calls in `main`
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SharedPrefs instance.
  await Prefs.init();

  runApp(CompassApp());
}

class CompassApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compass App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CompassPage(),
    );
  }
}
