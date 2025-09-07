import 'package:buddhist_compass/prefs.dart';
import 'package:buddhist_compass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlaceSelector extends StatefulWidget {
  final Function()? onLocationChanged;

  const PlaceSelector({Key? key, this.onLocationChanged}) : super(key: key);

  @override
  _PlaceSelectorState createState() => _PlaceSelectorState();
}

class _PlaceSelectorState extends State<PlaceSelector> {
  // Stable IDs -> coordinates
  final Map<String, Map<String, double>> _placeById = const {
    'bodhGaya': {'latitude': 24.6967, 'longitude': 84.9918},
    'shwedagonPagoda': {'latitude': 16.7983, 'longitude': 96.1498},
    'mahaCetiya': {'latitude': 8.3499986, 'longitude': 80.391165102},
  };

  // Read previously saved selection; migrate old value if it was a localized name
  late String _selectedId = _normalizeSavedTarget(Prefs.targetName);

  String _normalizeSavedTarget(String saved) {
    // if already a known ID, use it
    if (_placeById.containsKey(saved)) return saved;

    // migrate legacy human-readable names -> IDs
    switch (saved) {
      case 'Bodh Gaya':
        return 'bodhGaya';
      case 'Swedagon Pagoda':
      case 'Shwedagon Pagoda':
        return 'shwedagonPagoda';
      case 'Maha Cetiya':
        return 'mahaCetiya';
      default:
        // fallback
        return 'bodhGaya';
    }
  }

  String _labelFor(String id, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (id) {
      case 'bodhGaya':
        return t.place_bodhGaya;
      case 'shwedagonPagoda':
        return t.place_shwedagonPagoda;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      default:
        return id;
    }
  }

  void _onPlaceSelected(String? id) {
    if (id == null) return;

    setState(() {
      _selectedId = id;
    });

    final coords = _placeById[id]!;
    // Save the stable ID; derive the display name at render time
    Prefs.targetName = id; // store ID (migration from old human text)
    Prefs.targetLat = coords['latitude']!;
    Prefs.targetLong = coords['longitude']!;

    widget.onLocationChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedId,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.black, fontSize: 18),
      underline: Container(height: 2, color: Colors.grey),
      onChanged: _onPlaceSelected,
      items: _placeById.keys.map((id) {
        return DropdownMenuItem<String>(
          value: id,
          child: Text(_labelFor(id, context)),
        );
      }).toList(),
    );
  }
}
