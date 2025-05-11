import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';

class PatientTrackingZonePage extends StatefulWidget {
  final String patientUid;
  final String patientName;

  const PatientTrackingZonePage({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<PatientTrackingZonePage> createState() =>
      _PatientTrackingZonePageState();
}

class _PatientTrackingZonePageState extends State<PatientTrackingZonePage> {
  GoogleMapController? _mapController;
  LatLng? _patientLocation;
  LatLng? _safeZoneCenter;
  double _safeZoneRadius = 100;
  Circle? _safeZoneCircle;
  Marker? _patientMarker;
  StreamSubscription<DocumentSnapshot>? _locationSub;
  Timer? _locationTimer;
  String? _guardianUid;
  List<Map<String, dynamic>> _triggeredAlerts = [];
  bool _isZoneSaved = false;
  FlutterLocalNotificationsPlugin? _localNotifications;

  // Define colors from the provided palette
  final Color backgroundColorSolid = const Color(0xFFF9EFE5); // Brand Beige
  final Color buttonColor = const Color(0xFF000000); // Black for buttons
  final Color accentColor = const Color(0xFFFF6F61); // Coral for alerts
  final Color textColorPrimary = const Color(0xFF000000); // Brand Black
  final Color textColorSecondary = const Color(
    0xFF7F8790,
  ); // Base Muted Gray-Blue
  final Color cardBackgroundColor = const Color(0xFFF8F8F8); // Base Light Gray
  final Color glassyOverlayColor = const Color(
    0xFF000000,
  ); // Black for glassy effect

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadGuardianUid();
    _listenToPatientLocation();
    _loadSafeZone();
    _loadAlerts();
    _startTracking();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSub?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications?.initialize(settings);
  }

  Future<void> _sendLocalNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'danger_channel',
      'Danger Zone Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert_sound'),
      fullScreenIntent: true,
      enableVibration: true,
      ticker: 'ALERT',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications?.show(
      0,
      '🚨 Danger Zone Alert',
      '${widget.patientName} exited the safe zone!',
      notificationDetails,
    );

    _navigateToAlertScreen();
  }

  void _navigateToAlertScreen() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: glassyOverlayColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: const Text(
              '🚨 EMERGENCY ALERT 🚨',
              style: TextStyle(
                color: Color(0xFFFF6F61),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              '${widget.patientName} has exited the safe zone!',
              style: const TextStyle(color: Color(0xFF000000), fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: Color(0xFF7F8790), fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _loadGuardianUid() async {
    final patientDoc =
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientUid)
            .get();
    setState(() {
      _guardianUid = patientDoc.data()?['guardianUid'];
    });
  }

  void _startTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_patientLocation == null ||
          _safeZoneCenter == null ||
          _guardianUid == null)
        return;

      final lat = _patientLocation!.latitude;
      final lng = _patientLocation!.longitude;

      if (!_isInsideSafeZone(lat, lng)) {
        await _triggerAlert(
          widget.patientUid,
          widget.patientName,
          _guardianUid!,
          lat,
          lng,
        );
        await _sendLocalNotification();
      }
    });
  }

  bool _isInsideSafeZone(double lat, double lng) {
    if (_safeZoneCenter == null) return false;
    final distance = Geolocator.distanceBetween(
      _safeZoneCenter!.latitude,
      _safeZoneCenter!.longitude,
      lat,
      lng,
    );
    return distance <= _safeZoneRadius;
  }

  Future<void> _triggerAlert(
    String patientUid,
    String patientName,
    String guardianUid,
    double lat,
    double lng,
  ) async {
    final timestamp = Timestamp.now();
    final alertRef = await FirebaseFirestore.instance.collection('alerts').add({
      'patientUid': patientUid,
      'patientName': patientName,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp,
      'resolved': false,
    });

    final guardianDoc =
        await FirebaseFirestore.instance
            .collection('guardians')
            .doc(guardianUid)
            .get();
    final guardianToken = guardianDoc.data()?['fcmToken'];
    if (guardianToken == null) {
      print('⚠️ Guardian FCM token not found');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.9:5000/send_alert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': guardianToken,
          'title': '🚨 Danger Zone Alert',
          'body': '$patientName has exited the safe zone!',
          'alertId': alertRef.id,
          'lat': lat,
          'lng': lng,
          'timestamp': timestamp.toDate().toIso8601String(),
        }),
      );

      print(
        response.statusCode == 200
            ? '✅ FCM Alert sent'
            : '❌ FCM alert failed: ${response.body}',
      );
    } catch (e) {
      print('❌ Error sending FCM alert: $e');
    }
  }

  void _listenToPatientLocation() {
    _locationSub = FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientUid)
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.data();
          if (data == null || data['location'] == null) return;
          final loc = data['location'];
          final pos = LatLng(loc['lat'], loc['lng']);
          setState(() {
            _patientLocation = pos;
            _patientMarker = Marker(
              markerId: const MarkerId('patient'),
              position: pos,
              infoWindow: InfoWindow(title: widget.patientName),
            );
          });
          _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
        });
  }

  void _loadSafeZone() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientUid)
            .get();
    final data = doc.data();
    if (data != null && data['safeZone'] != null) {
      final zone = data['safeZone'];
      setState(() {
        _safeZoneCenter = LatLng(zone['lat'], zone['lng']);
        _safeZoneRadius = zone['radius']?.toDouble() ?? 100;
        _safeZoneCircle = Circle(
          circleId: const CircleId('safe_zone'),
          center: _safeZoneCenter!,
          radius: _safeZoneRadius,
          fillColor: Colors.green.withOpacity(0.3),
          strokeColor: Colors.green,
          strokeWidth: 2,
        );
        _isZoneSaved = true;
      });
    }
  }

  void _saveSafeZone() async {
    if (_safeZoneCenter == null) return;
    await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientUid)
        .set({
          'safeZone': {
            'lat': _safeZoneCenter!.latitude,
            'lng': _safeZoneCenter!.longitude,
            'radius': _safeZoneRadius,
          },
        }, SetOptions(merge: true));

    setState(() {
      _safeZoneCircle = Circle(
        circleId: const CircleId('safe_zone'),
        center: _safeZoneCenter!,
        radius: _safeZoneRadius,
        fillColor: Colors.green.withOpacity(0.3),
        strokeColor: Colors.green,
        strokeWidth: 2,
      );
      _isZoneSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Safe zone saved successfully'),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  void _loadAlerts() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('alerts')
            .where('patientUid', isEqualTo: widget.patientUid)
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      _triggeredAlerts = snap.docs.map((d) => d.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Track & Setup Safe Zone',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: glassyOverlayColor.withOpacity(0.1)),
          ),
        ),
      ),
      body: Container(
        color: backgroundColorSolid,
        child:
            _patientLocation == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interactive Google Maps box with black glassy effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            height: 350,
                            decoration: BoxDecoration(
                              color: cardBackgroundColor.withOpacity(0.9),
                              border: Border.all(
                                color: glassyOverlayColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _patientLocation!,
                                zoom: 17,
                              ),
                              markers:
                                  _patientMarker != null
                                      ? {_patientMarker!}
                                      : {},
                              circles:
                                  _safeZoneCircle != null
                                      ? {_safeZoneCircle!}
                                      : {},
                              onMapCreated:
                                  (controller) => _mapController = controller,
                              onTap: (LatLng tapped) {
                                setState(() {
                                  _safeZoneCenter = tapped;
                                  _safeZoneCircle = Circle(
                                    circleId: const CircleId('safe_zone'),
                                    center: tapped,
                                    radius: _safeZoneRadius,
                                    fillColor: Colors.green.withOpacity(0.3),
                                    strokeColor: Colors.green,
                                    strokeWidth: 2,
                                  );
                                  _isZoneSaved = false;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Safe zone controls with black glassy effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBackgroundColor.withOpacity(0.9),
                              border: Border.all(
                                color: glassyOverlayColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adjust Safe Zone',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000000),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.adjust,
                                      color: Color(0xFF7F8790),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Radius: ${_safeZoneRadius.round()} meters',
                                        style: const TextStyle(
                                          color: Color(0xFF000000),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Slider(
                                  value: _safeZoneRadius,
                                  min: 50,
                                  max: 1000,
                                  divisions: 19,
                                  label: _safeZoneRadius.round().toString(),
                                  activeColor: Colors.green,
                                  inactiveColor: Colors.green.withOpacity(0.3),
                                  onChanged: (value) {
                                    setState(() {
                                      _safeZoneRadius = value;
                                      if (_safeZoneCenter != null) {
                                        _safeZoneCircle = Circle(
                                          circleId: const CircleId('safe_zone'),
                                          center: _safeZoneCenter!,
                                          radius: _safeZoneRadius,
                                          fillColor: Colors.green.withOpacity(
                                            0.3,
                                          ),
                                          strokeColor: Colors.green,
                                          strokeWidth: 2,
                                        );
                                        _isZoneSaved = false;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 3,
                                      sigmaY: 3,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: glassyOverlayColor.withOpacity(
                                            0.3,
                                          ),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _saveSafeZone,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonColor,
                                          foregroundColor: backgroundColorSolid,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ).copyWith(
                                          overlayColor: WidgetStateProperty.all(
                                            glassyOverlayColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: const Text(
                                          'Save Safe Zone',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isZoneSaved)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF7F8790),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Safe zone saved',
                                          style: TextStyle(
                                            color: textColorSecondary,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Send Test Alert button with black glassy effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: glassyOverlayColor.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.warning),
                              label: const Text(
                                'Send Test Alert',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: backgroundColorSolid,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.all(
                                  glassyOverlayColor.withOpacity(0.2),
                                ),
                              ),
                              onPressed: () async {
                                if (_guardianUid != null &&
                                    _patientLocation != null) {
                                  await _triggerAlert(
                                    widget.patientUid,
                                    widget.patientName,
                                    _guardianUid!,
                                    _patientLocation!.latitude,
                                    _patientLocation!.longitude,
                                  );
                                  await _sendLocalNotification();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Missing guardian or patient location',
                                      ),
                                      backgroundColor: accentColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Triggered Alerts section with black glassy effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBackgroundColor.withOpacity(0.9),
                              border: Border.all(
                                color: glassyOverlayColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Triggered Alerts',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000000),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _triggeredAlerts.isEmpty
                                    ? const Text(
                                      'No alerts triggered yet.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF7F8790),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _triggeredAlerts.length,
                                      itemBuilder: (context, index) {
                                        final a = _triggeredAlerts[index];
                                        final ts =
                                            (a['timestamp'] as Timestamp?)
                                                ?.toDate();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 15,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 3,
                                                sigmaY: 3,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  15,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: backgroundColorSolid
                                                      .withOpacity(0.8),
                                                  border: Border.all(
                                                    color: glassyOverlayColor
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.warning,
                                                      color: Color(0xFFFF6F61),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 15),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Lat: ${a['lat']}, Lng: ${a['lng']}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Color(
                                                                    0xFF000000,
                                                                  ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            ts
                                                                    ?.toLocal()
                                                                    .toString() ??
                                                                '...',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF7F8790,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
