import 'package:buddhist_compass/l10n/app_localizations.dart';
import 'package:buddhist_compass/views/select_language_widget.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
          elevation: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50, width: 50.0),
              Text("${AppLocalizations.of(context)!.language}:",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 40.0),
              SelectLanguageWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
