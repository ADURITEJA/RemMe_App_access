import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../pages/danger_zone_alerts_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DangerZoneTestPage extends StatelessWidget {
  const DangerZoneTestPage({super.key});

  void _triggerTestAlert(BuildContext context) {
    // Simulate a danger zone alert
    final testMessage = RemoteMessage(
      data: {
        'type': 'danger_zone',
        'alertId': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
        'patientId': 'test_patient_456',
        'location': '37.7749,-122.4194', // San Francisco coordinates
        'timestamp': DateTime.now().toIso8601String(),
      },
      notification: const RemoteNotification(
        title: '🚨 Test Alert',
        body: 'This is a test danger zone alert',
      ),
    );

    // Show the danger zone alert dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DangerZoneAlertsPage(
        alertId: testMessage.data['alertId']!,
        patientName: 'Test Patient',
        alertLocation: const LatLng(37.7749, -122.4194),
        alertTime: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danger Zone Alert Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Danger Zone Alert Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _triggerTestAlert(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Trigger Test Alert'),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will show a test danger zone alert dialog',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
