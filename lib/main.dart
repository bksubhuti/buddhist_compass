import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:buddhist_compass/prefs.dart';
import 'package:buddhist_compass/l10n/app_localizations.dart'; // flutter gen-l10n output
import 'package:buddhist_compass/src/provider/locale_change_notifier.dart'; // make sure this exists
import 'package:flutter_localizations/flutter_localizations.dart';

import 'views/compass_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  runApp(const CompassApp());
}

class CompassApp extends StatelessWidget {
  const CompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleChangeNotifier>(
          create: (_) => LocaleChangeNotifier(),
        ),
      ],
      builder: (context, _) {
        final localeChange = context.watch<LocaleChangeNotifier>();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Compass App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: _fontForLocale(localeChange.localeString),
          ),
          locale: Locale(localeChange.localeString, ''),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('si', ''), // Sinhala
            Locale('my', ''), // Myanmar (Burmese)
            Locale('km', ''), // Khmer
            Locale('hi', ''), // Hindi
          ],
          home: const CompassPage(),
        );
      },
    );
  }

  String? _fontForLocale(String locale) {
    switch (locale) {
      case 'my':
        return 'NotoSansMyanmar';
      case 'si':
        return 'NotoSansSinhala';
      case 'km':
        return 'NotoSansKhmer';
      default:
        return null; // system default
    }
  }
}
