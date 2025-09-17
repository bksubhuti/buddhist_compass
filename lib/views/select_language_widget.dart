import 'package:buddhist_compass/prefs.dart';
import 'package:buddhist_compass/src/provider/locale_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectLanguageWidget extends StatelessWidget {
  SelectLanguageWidget({Key? key}) : super(key: key);
  final _languageItmes = <String>[
    'English',
    'မြန်မာ',
    'සිංහල',
    'ខ្មែរ',
    'हिन्दी',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: _languageItmes[Prefs.localeVal],
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        isDense: false,
        onChanged: (newValue) {
          Prefs.localeVal = _languageItmes.indexOf(newValue!);
          final localeProvider =
              Provider.of<LocaleChangeNotifier>(context, listen: false);
          localeProvider.localeVal = Prefs.localeVal;
        },
        items: _languageItmes.map<DropdownMenuItem<String>>(
          (String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                    color: (true) // (!Prefs.darkThemeOn)
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            );
          },
        ).toList());
  }
}
