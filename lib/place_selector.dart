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
  final Map<String, Map<String, double>> _placeById = {
    'bodhGaya': {'latitude': 24.6951, 'longitude': 84.9913}, // Bodh Gaya, India
    'lumbiniPagoda': {
      'latitude': 27.4697,
      'longitude': 83.2752
    }, // Lumbini, Nepal
    'sarnath': {'latitude': 25.3811, 'longitude': 83.0214}, // Sarnath, India
    'kushinagar': {
      'latitude': 26.7407,
      'longitude': 83.8886
    }, // Kushinagar, India
    'shwedagonPagoda': {
      'latitude': 16.7984,
      'longitude': 96.1495
    }, // Shwedagon, Myanmar
    'mahaCetiya': {
      'latitude': 8.3500,
      'longitude': 80.3964
    }, // Ruwanwelisaya, Sri Lanka
    'toothRelicPagoda': {
      'latitude': 7.2936,
      'longitude': 80.6413
    }, // Sri Dalada Maligawa, Sri Lanka
  };
  // Read previously saved selection; migrate old value if it was a localized name
  late String _selectedId;

  @override
  void initState() {
    super.initState();

    // Rebuild the map fresh every time PlaceSelector is constructed
    if (Prefs.userDest1.isNotEmpty) {
      _placeById['userDest1'] = {
        'latitude': Prefs.userDest1Lat,
        'longitude': Prefs.userDest1Long,
      };
    }

    _selectedId = _normalizeSavedTarget(Prefs.targetName);
  }

  String _normalizeSavedTarget(String saved) {
    if (_placeById.containsKey(saved)) return saved;
    switch (saved) {
      case 'Bodh Gaya':
        return 'bodhGaya';
      case 'Lumbini Pagoda':
        return 'lumbiniPagoda';
      case 'Sarnath': // Updated from 'saranat'
        return 'sarnath';
      case 'kushinagar':
        return 'kushinagar';
      case 'Swedagon Pagoda':
      case 'Shwedagon Pagoda':
        return 'shwedagonPagoda';
      case 'Maha Cetiya':
        return 'mahaCetiya';
      case 'Tooth Relic Pagoda':
        return 'toothRelicPagoda';
      default:
        return 'bodhGaya';
    }
  }

  String _labelFor(String id, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (id) {
      case 'bodhGaya':
        return t.place_bodhGaya;
      case 'lumbiniPagoda':
        return t.place_lumbiniPagoda;
      case 'sarnath':
        return t.place_sarnath;
      case 'kushinagar':
        return t.place_kushinagar;
      case 'shwedagonPagoda':
        return t.place_shwedagonPagoda;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      case 'toothRelicPagoda':
        return t.place_toothRelicPagoda;
      case 'userDest1':
        return Prefs.userDest1; // <- custom label
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
