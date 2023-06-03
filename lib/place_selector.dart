import 'package:buddhist_compass/prefs.dart';
import 'package:flutter/material.dart';

class PlaceSelector extends StatefulWidget {
  final Function()? onLocationChanged;

  const PlaceSelector({Key? key, this.onLocationChanged}) : super(key: key);

  @override
  _PlaceSelectorState createState() => _PlaceSelectorState();
}

class _PlaceSelectorState extends State<PlaceSelector> {
  String? _selectedPlace = 'Bodh Gaya';
  Map<String, Map<String, double>> _placeCoordinates = {
    'Bodh Gaya': {'latitude': 24.6967, 'longitude': 84.9918},
    'Swedagon Pagoda': {'latitude': 16.7983, 'longitude': 96.1498},
    'Maha Cetiya': {'latitude': 7.2938, 'longitude': 81.8644},
  };

  void _onPlaceSelected(String? value) {
    if (value != null) {
      setState(() {
        _selectedPlace = value;
      });

      Map<String, double> coordinates = _placeCoordinates[value]!;
      Prefs.targetName = value;
      Prefs.targetLat = coordinates['latitude']!;
      Prefs.targetLong = coordinates['longitude']!;

      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(); // Call the onLocationChanged callback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedPlace,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.black, fontSize: 18),
      underline: Container(
        height: 2,
        color: Colors.grey,
      ),
      onChanged: _onPlaceSelected,
      items:
          _placeCoordinates.keys.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
