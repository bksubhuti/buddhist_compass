import 'package:buddhist_compass/place_selector.dart';
import 'package:buddhist_compass/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;
//import 'package:vector_math/vector_math.dart' as vm;
import 'dart:async';

class CompassPage extends StatefulWidget {
  @override
  _CompassPageState createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage>
    with TickerProviderStateMixin {
  double _direction = 0.0;
  double _bearing = 0.0;
  double _distance = 0.0;
  double _userLatitude = 0.0;
  double _userLongitude = 0.0;
  double _targetLatitude = Prefs.targetLat;
  double _targetLongitude = Prefs.targetLong;
  late AnimationController _controller;
  bool _vibrationEnabled = false;
  final int limits = 3;
  bool _isLoadingLocation = true;
  bool _isChangingLocation = false;
  StreamSubscription<Position>? _posSub;
  bool _wasOnTarget = false;
  Timer? _pulseTimer;
  DateTime? _lastVibeAt;
  final _minVibeGap = const Duration(milliseconds: 300);

  double _angDiff(double a, double b) {
    final d = (a - b) % 360;
    return (d + 540) % 360 - 180; // now in range [-180,180)
  }

  bool _isWithinLimits() {
    return _angDiff(_bearing, _direction).abs() <= limits;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/compass_normal.png'), context);
    precacheImage(
        const AssetImage('assets/images/compass_on_target.png'), context);
  }

  Future<void> _getLocation() async {
    // Ask for location permission
    final permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, // was desiredAccuracy
            distanceFilter: 0, // report immediately
          ),
        );

        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          _isLoadingLocation = false;
        });
      } catch (e) {
        // Handle errors like GPS not enabled
        debugPrint("Error getting location: $e");
      }
    } else if (permissionStatus.isDenied) {
      // User denied once
      debugPrint("Location permission denied.");
    } else if (permissionStatus.isPermanentlyDenied) {
      // User selected "Don't ask again" → open app settings
      await openAppSettings();
    }
  }

  Future<void> _ensureLocationPermissionAndStart() async {
    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      _startLocationStream(); //  start stream after permission
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      setState(
          () => _isLoadingLocation = false); //  let UI show even without GPS
    } else {
      setState(() => _isLoadingLocation = false); //  show UI; bearing may be 0
    }
  }

  void _startCompass() {
    FlutterCompass.events?.listen((event) async {
      setState(() {
        _targetLatitude = Prefs.targetLat;
        _targetLongitude = Prefs.targetLong;

        _direction = event.heading ?? 0.0;
        _direction = (_direction < 0) ? _direction + 360 : _direction;
        _bearing = _calculateBearing(
          _userLatitude,
          _userLongitude,
          _targetLatitude,
          _targetLongitude,
        );
      });

      double newDistance = await _calculateDistance(
        _userLatitude,
        _userLongitude,
        _targetLatitude,
        _targetLongitude,
      );

      setState(() {
        _distance = newDistance;
      });

      final onTarget = _isWithinLimits();

      if (onTarget != _wasOnTarget) {
        _wasOnTarget = onTarget;

        if (_vibrationEnabled) {
          await Vibration.cancel();
          if (onTarget) {
            // start repeating pulse every 2 seconds
            _pulseTimer?.cancel();
            _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
              if (await _canVibrate()) Vibration.vibrate(duration: 100);
            });
          } else {
            // stop pulsing and buzz once long
            _pulseTimer?.cancel();
            _pulseTimer = null;
            if (await _canVibrate()) Vibration.vibrate(duration: 250);
          }
        } else {
          //  vibration disabled: ensure nothing is running
          _pulseTimer?.cancel();
          _pulseTimer = null;
          await Vibration.cancel();
        }
      }
    });
  }

  Future<bool> _canVibrate() async {
    if (!_vibrationEnabled) return false;
    if (!(await Vibration.hasVibrator() ?? false)) return false;
    final now = DateTime.now();
    if (_lastVibeAt != null && now.difference(_lastVibeAt!) < _minVibeGap)
      return false;
    _lastVibeAt = now;
    return true;
  }

  double vasilBearing(double lat1, double lon1, double lat2, double lon2) {
    final double phi1 = lat1 * math.pi / 180.0;
    final double phi2 = lat2 * math.pi / 180.0;
    double deltaLambda = (lon2 - lon1) * math.pi / 180.0;
    if (deltaLambda.abs() > math.pi) {
      deltaLambda = deltaLambda > 0
          ? -(2 * math.pi - deltaLambda)
          : (2 * math.pi + deltaLambda);
    }

    final double deltaPhi = math.log(
        math.tan(phi2 / 2 + math.pi / 4) / math.tan(phi1 / 2 + math.pi / 4));

    final double theta = math.atan2(deltaLambda, deltaPhi);

    double bearing = theta * 180 / math.pi;
    if (0 <= bearing && bearing < 360) {
      return bearing;
    }
    final double x = bearing, a = 180, p = 360;
    return (((2 * a * x / p) % p) + p) % p;
  }

  double _calculateBearing(
      double startLat, double startLng, double endLat, double endLng) {
    double startLatRad = startLat * (math.pi / 180);
    double startLngRad = startLng * (math.pi / 180);
    double endLatRad = endLat * (math.pi / 180);
    double endLngRad = endLng * (math.pi / 180);

    double dLng = endLngRad - startLngRad;

    double y = math.sin(dLng) * math.cos(endLatRad);
    double x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    double bearingRad = math.atan2(y, x);
    double bearingDeg = bearingRad * (180 / math.pi);

    return (bearingDeg + 360) % 360;
  }

  double vincentyBearing(double lat1, double lon1, double lat2, double lon2) {
    const double a = 6378137, b = 6356752.314245, f = 1 / 298.257223563;
    double L = toRadians(lon2 - lon1);

    double U1 = math.atan((1 - f) * math.tan(toRadians(lat1)));
    double U2 = math.atan((1 - f) * math.tan(toRadians(lat2)));

    double sinU1 = math.sin(U1), cosU1 = math.cos(U1);
    double sinU2 = math.sin(U2), cosU2 = math.cos(U2);

    double cosSqAlpha, sinSigma, cos2SigmaM, cosSigma, sigma;

    double lambda = L, lambdaP, iterLimit = 100;
    do {
      double sinLambda = math.sin(lambda), cosLambda = math.cos(lambda);
      sinSigma = math.sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
              (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      if (sinSigma == 0) {
        return 0; // co-incident points
      }

      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);
      double sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;

      if (cos2SigmaM.isNaN) {
        cos2SigmaM = 0; // equatorial line: cosSqAlpha=0
      }

      double C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = L +
          (1 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SigmaM +
                          C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) {
      return double.nan; // formula failed to converge
    }

    double fwdAz = toDegrees(math.atan2(cosU2 * math.sin(lambda),
        cosU1 * sinU2 - sinU1 * cosU2 * math.cos(lambda)));
    return (fwdAz + 360) % 360;
  }

  double toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double toDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  Future<double> _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) async {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm;
  }

  @override
  void initState() {
    super.initState();
    _vibrationEnabled = Prefs.vibeOn;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _startCompass();
//    _getLocation();
    _ensureLocationPermissionAndStart();
  }

  @override
  void dispose() {
    Vibration.cancel();
    _pulseTimer?.cancel();
    _posSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startLocationStream() {
    _posSub?.cancel(); // cancel old if any
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // meters before update
      ),
    ).listen((pos) {
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _isLoadingLocation = false;
      });
    });
  }

  Widget _buildCompass() {
    return Stack(
      alignment: Alignment.center,
      children: [
        //  AnimatedSwitcher for a nice cross-fade when entering/leaving target
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: Transform.rotate(
            key: ValueKey<bool>(_isWithinLimits()),
            angle: -math.pi * _direction / 180,
            child: Image.asset(
              _isWithinLimits()
                  ? 'assets/images/compass_on_target.png'
                  : 'assets/images/compass_normal.png',
              width: 280,
              height: 280,
            ),
          ),
        ),

        // (Optional) keep/remove this label — not an arrow
        const Positioned(
          top: 0,
          child: Text(
            'I',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const CircularProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buddhist Compass App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (_isLoadingLocation || _isChangingLocation)
                    ? _buildLoadingIndicator()
                    : _buildCompass(),
                const SizedBox(height: 10),
                const Text(
                  'Current Direction:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_direction.toInt()}°',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Bearing to ${Prefs.targetName}:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_bearing.toInt()}°',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Distance to ${Prefs.targetName}:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_distance.toInt()} km',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                PlaceSelector(
                  onLocationChanged: () {
                    setState(() {
                      _isChangingLocation = true;
                    });
                    _getLocation().then((_) {
                      setState(() {
                        _isChangingLocation = false;
                      });
                    });
                  },
                ),
                const SizedBox(height: 15),
                const Text('Vibration'),
                Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _vibrationEnabled = value;
                      Prefs.vibeOn = value;
                    });
                    if (!value) {
                      _pulseTimer?.cancel();
                      _pulseTimer = null;
                      await Vibration.cancel();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
