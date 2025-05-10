// File: lib/services/danger_zone_alert_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class DangerZoneAlertService {
  static final DangerZoneAlertService _instance =
      DangerZoneAlertService._internal();
  factory DangerZoneAlertService() => _instance;

  DangerZoneAlertService._internal();

  Timer? _locationTimer;
  LatLng? _zoneCenter;
  double _zoneRadius = 200; // meters
  bool _isMonitoring = false;

  // Initialize notification service (local alerts)
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _sendLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'danger_zone_channel',
          'Danger Zone Alerts',
          channelDescription: 'Alerts when patient exits safety zone',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  void startMonitoring(LatLng center, double radius) {
    _zoneCenter = center;
    _zoneRadius = radius;
    _isMonitoring = true;

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      await _checkPatientLocation();
    });
    print('✅ Danger Zone Monitoring Started');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _locationTimer?.cancel();
    print('🛑 Danger Zone Monitoring Stopped');
  }

  Future<void> _checkPatientLocation() async {
    if (!_isMonitoring || _zoneCenter == null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('⚠️ Location permission not granted.');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double distance = Geolocator.distanceBetween(
      _zoneCenter!.latitude,
      _zoneCenter!.longitude,
      position.latitude,
      position.longitude,
    );

    print(
      '📍 Current Distance to Center: ${distance.toStringAsFixed(2)} meters',
    );

    if (distance > _zoneRadius) {
      print('🚨 Patient has left the Safety Zone!');

      // Send local notification
      await _sendLocalNotification(
        '🚨 Danger Zone Alert',
        'Patient left safety zone at ${DateTime.now().hour}:${DateTime.now().minute}.',
      );

      // TODO: Send remote Push Notification to caregiver (Firebase)
    }
  }
}

// Helper Class to represent a location point
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
