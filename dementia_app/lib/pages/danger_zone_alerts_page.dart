// File: lib/pages/danger_zone_alerts_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DangerZoneAlertsPage extends StatelessWidget {
  final String patientName;
  final String alertLocation;
  final DateTime alertTime;

  DangerZoneAlertsPage({
    required this.patientName,
    required this.alertLocation,
    required this.alertTime,
  });

  void _callPatient() async {
    const phoneNumber = 'tel:+1234567890'; // Replace with patient's number
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      print('Could not launch phone dialer');
    }
  }

  void _openMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$alertLocation';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not launch Google Maps');
    }
  }

  void _resolveAlert(BuildContext context) {
    // You can implement backend logging here if needed
    Navigator.of(context).pop(); // Go back to Home or Tracking page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('Danger Zone Alert', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              '⚠️ $patientName left the safety zone!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text('Last seen near:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 5),
            Text(
              alertLocation,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Alert triggered at: ${alertTime.hour}:${alertTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _callPatient,
              icon: Icon(Icons.phone),
              label: Text('Call Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _openMaps,
              icon: Icon(Icons.map),
              label: Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 15),
            TextButton(
              onPressed: () => _resolveAlert(context),
              child: Text(
                'Mark as Resolved',
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
