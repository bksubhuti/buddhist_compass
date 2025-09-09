import 'package:buddhist_compass/l10n/app_localizations.dart';
import 'package:buddhist_compass/place_selector.dart';
import 'package:buddhist_compass/prefs.dart';
import 'package:buddhist_compass/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show SystemNavigator;

//import 'package:vector_math/vector_math.dart' as vm;
import 'dart:async';

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

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
  bool _askedThisSession = false; // prevents repeat prompts
  bool _showingDialog = false; // avoids stacking dialogs

  String _targetDisplayName(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (Prefs.targetName) {
      // Prefs.targetName should store the ID
      case 'bodhGaya':
        return t.place_bodhGaya;
      case 'shwedagonPagoda':
        return t.place_shwedagonPagoda;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      default:
        return t.place_bodhGaya; // fallback
    }
  }

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

  Future<void> _getLocation(BuildContext context) async {
    final ok = await _ensureLocationPermissionWithPrompt(context);
    if (!ok) return;

    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      _promptOpenLocationServices(context);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 0),
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
      _showSnack(context, AppLocalizations.of(context)!.locationError);
    }
  }

  void _promptOpenLocationServices(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.locationServicesTitle),
        content: Text(
          AppLocalizations.of(context)!.locationServicesContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings(); // user-initiated only
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _ensureLocationPermissionWithPrompt(BuildContext context) async {
    // Avoid loops: only ask once per visible session (you can reset as needed)
    if (_askedThisSession) return await _hasLocationPermission();
    _askedThisSession = true;

    // Already granted?
    if (await _hasLocationPermission()) return true;

    // Rationale dialog (user-friendly explanation before the system sheet)
    final proceed = await _showRationaleDialog(context);
    if (proceed != true) return false;

    // Request permission
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    if (permission == LocationPermission.denied) {
      // User denied at system sheet — offer Settings or Exit
      await _showSettingsOrExitDialog(context,
          message: AppLocalizations.of(context)!.locationRequiredMessage1);
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      // Permanently denied — Settings or Exit
      await _showSettingsOrExitDialog(context,
          message: AppLocalizations.of(context)!.locationRequiredMessage2);
      return false;
    }

    return false;
  }

  Future<bool> _hasLocationPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<bool?> _showRationaleDialog(BuildContext context) async {
    if (_showingDialog) return false;
    _showingDialog = true;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Allow Location?'),
        content: Text(
          AppLocalizations.of(context)!.locationPermissionRationaleMessage,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text((AppLocalizations.of(context)!
                  .locationPermissionRationaleNotNow))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!
                  .locationPermissionRationaleContinue)),
        ],
      ),
    );
    _showingDialog = false;
    return res;
  }

  Future<void> _showSettingsOrExitDialog(BuildContext context,
      {required String message}) async {
    if (_showingDialog) return;
    _showingDialog = true;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.locationRequiredTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // stay in app
            child: Text(AppLocalizations.of(context)!.locationRequiredCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings(); // user-initiated only
            },
            child: Text(
                AppLocalizations.of(context)!.locationRequiredOpenSettings),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Exit: works on Android; iOS discourages programmatic exit.
              SystemNavigator.pop();
            },
            child: Text(AppLocalizations.of(context)!.locationRequiredExit),
          ),
        ],
      ),
    );
    _showingDialog = false;
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
    if (!(await Vibration.hasVibrator())) return false;
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
//    const double a = 6378137;
    //  const double b = 6356752.314245;
    const double f = 1 / 298.257223563;
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
        vsync: this, duration: const Duration(milliseconds: 200));
    _startCompass();

    // Ask once on load; don’t loop
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _ensureLocationPermissionWithPrompt(context);
      if (ok) {
        final servicesOn = await Geolocator.isLocationServiceEnabled();
        if (servicesOn) {
          _startLocationStream();
        }
      }
      setState(() => _isLoadingLocation = false);
    });
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(AppLocalizations.of(context)!.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/compass_on_target.png',
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.drawerHeaderTitle,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(AppLocalizations.of(context)!.settings),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: Text(AppLocalizations.of(context)!.help,
                    style: TextStyle()),
                onTap: () {
                  showHelpDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(AppLocalizations.of(context)!.about,
                    style: TextStyle()),
                onTap: () {
                  showAboutBuddhistCompassDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip), // Added Icon
                title: Text(AppLocalizations.of(context)!.privacyPolicy),
                onTap: () async {
                  const url =
                      'https://americanmonk.org/privacy-policy-for-buddhist-compass-app/';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    // Optional: show an error if the URL cannot be opened
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .privacyPolicyError)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.star), // Added Icon
                title: Text(AppLocalizations.of(context)!.rateThisApp,
                    style: TextStyle()),
                focusColor: Theme.of(context).focusColor,
                hoverColor: Theme.of(context).hoverColor,
                onTap: () async {
                  await InAppReview.instance.openStoreListing(
                    appStoreId: '6751797857', // use after iOS is live
                    //                  https://apps.apple.com/us/app/buddhist-compass/id6751797857
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(AppLocalizations.of(context)!.shareApp),
                onTap: () {
                  Navigator.pop(context); // close the drawer
                  shareApp(context);
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: SafeArea(
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
                    Text(
                      AppLocalizations.of(context)!.currentDirection,
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
                      AppLocalizations.of(context)!
                          .bearingTo(_targetDisplayName(context)),
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
                      AppLocalizations.of(context)!
                          .distanceTo(_targetDisplayName(context)),
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
                        _getLocation(context).then((_) {
                          setState(() {
                            _isChangingLocation = false;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Text(AppLocalizations.of(context)!.vibration),
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
        ),
      ),
    );
  }

  showHelpDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child:
          Text(AppLocalizations.of(context)!.helpDialogOk, style: TextStyle()),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog help = AlertDialog(
      title: Text("Help"),
      content: SingleChildScrollView(
        child: Text(
          AppLocalizations.of(context)!.helpDialogContent,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }

  showAboutBuddhistCompassDialog(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    showAboutDialog(
      context: context,
      applicationIcon: Image.asset(
        'assets/images/compass_on_target.png',
        width: 50,
        height: 50,
      ),
      applicationName: "Buddhist Compass",
      applicationVersion: 'Version ${info.version}+${info.buildNumber}',
      children: [
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.aboutDialogParagraph1,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.aboutDialogParagraph2,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.locationPermissionRationaleTitle,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.aboutDialogParagraph4,
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    const landingUrl =
        'https://americanmonk.org/buddhist-compass/?utm_source=app&utm_medium=share';

    await SharePlus.instance.share(
      ShareParams(
        text: AppLocalizations.of(context)!.shareAppText,
        subject: 'Buddhist Compass',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & (box.size),
        title: AppLocalizations.of(context)!.shareAppTitle,
      ),
    );
  }
}
