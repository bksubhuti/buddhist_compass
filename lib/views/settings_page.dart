import 'package:buddhist_compass/l10n/app_localizations.dart';
import 'package:buddhist_compass/prefs.dart';
import 'package:buddhist_compass/views/select_language_widget.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = Prefs.userDest1;
    _latController.text = Prefs.userDest1Lat.toString();
    _longController.text = Prefs.userDest1Long.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  void _addLocation() {
    final name = _nameController.text;
    final lat = double.tryParse(_latController.text) ?? 0.0;
    final long = double.tryParse(_longController.text) ?? 0.0;

    if (name.isNotEmpty && lat != 0.0 && long != 0.0) {
      setState(() {
        Prefs.userDest1 = name;
        Prefs.userDest1Lat = lat;
        Prefs.userDest1Long = long;
        Prefs.targetName = "userDest1";
        Prefs.targetLat = lat;
        Prefs.targetLong = long;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      Prefs.userDest1 = "";
      Prefs.userDest1Lat = 0.0;
      Prefs.userDest1Long = 0.0;
      _nameController.clear();
      _latController.clear();
      _longController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              elevation: 2,
              child: Row(
                children: [
                  const SizedBox(
                      height: 50,
                      width: 50.0), // keep if you need the icon space
                  Expanded(
                    child: Text(
                      "${AppLocalizations.of(context)!.language}:",
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.visible, // don’t clip
                      softWrap: true, // wrap if needed
                    ),
                  ),
                  const SizedBox(width: 10), // smaller gap
                  Flexible(child: SelectLanguageWidget()),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 300, // Increased card height
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.locationName),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _latController,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.latitude),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _longController,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.longitude),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _addLocation,
                            child: Text(AppLocalizations.of(context)!.save),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(140, 60), // Larger button
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _clearLocation,
                            child: Text(AppLocalizations.of(context)!.clear),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(140, 60), // Larger button
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
