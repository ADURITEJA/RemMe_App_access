// File: lib/pages/patient_tracking_zone_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
            backgroundColor: Colors.red[50],
            title: const Text(
              '🚨 EMERGENCY ALERT 🚨',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text('${widget.patientName} has exited the safe zone!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
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
        Uri.parse('http://192.168.1.9:5000/send_alert'), // update if needed
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
              infoWindow: const InfoWindow(title: 'Patient'),
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
      const SnackBar(content: Text('Safe zone saved successfully')),
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
      appBar: AppBar(title: const Text('Track & Setup Safe Zone')),
      body:
          _patientLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  SizedBox(
                    height: 350,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _patientLocation!,
                        zoom: 17,
                      ),
                      markers: _patientMarker != null ? {_patientMarker!} : {},
                      circles:
                          _safeZoneCircle != null ? {_safeZoneCircle!} : {},
                      onMapCreated: (controller) => _mapController = controller,
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
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text("Adjust Safe Zone Radius (in meters)"),
                  ),
                  Slider(
                    value: _safeZoneRadius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: _safeZoneRadius.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _safeZoneRadius = value;
                        if (_safeZoneCenter != null) {
                          _safeZoneCircle = Circle(
                            circleId: const CircleId('safe_zone'),
                            center: _safeZoneCenter!,
                            radius: _safeZoneRadius,
                            fillColor: Colors.green.withOpacity(0.3),
                            strokeColor: Colors.green,
                            strokeWidth: 2,
                          );
                        }
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: _saveSafeZone,
                    child: const Text('Save Selected Location as Safe Zone'),
                  ),
                  if (_isZoneSaved)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('✅ Safe zone saved'),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.warning),
                      label: const Text('Send Test Alert (Manual)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (_guardianUid != null && _patientLocation != null) {
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
                            const SnackBar(
                              content: Text(
                                'Missing guardian or patient location',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  const Text(
                    'Triggered Alerts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _triggeredAlerts.length,
                      itemBuilder: (context, index) {
                        final a = _triggeredAlerts[index];
                        final ts = (a['timestamp'] as Timestamp?)?.toDate();
                        return ListTile(
                          title: Text('Lat: ${a['lat']}, Lng: ${a['lng']}'),
                          subtitle: Text(ts?.toLocal().toString() ?? '...'),
                          leading: const Icon(Icons.warning, color: Colors.red),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
