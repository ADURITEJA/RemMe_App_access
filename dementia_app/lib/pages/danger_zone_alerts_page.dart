// File: lib/pages/danger_zone_alerts_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class DangerZoneAlertsPage extends StatefulWidget {
  final String alertId;
  final String patientName;
  final LatLng alertLocation;
  final DateTime alertTime;

  const DangerZoneAlertsPage({
    super.key,
    required this.alertId,
    required this.patientName,
    required this.alertLocation,
    required this.alertTime,
  });

  @override
  State<DangerZoneAlertsPage> createState() => _DangerZoneAlertsPageState();
}

class _DangerZoneAlertsPageState extends State<DangerZoneAlertsPage> {
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlertSound();
  }

  Future<void> _playAlertSound() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/alert_sound.wav'));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.alertLocation.latitude},${widget.alertLocation.longitude}';
    if (!await launchUrl(Uri.parse(url))) {
      print('❌ Could not launch Google Maps');
    }
  }

  void _markAsResolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .update({'resolved': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Alert marked as resolved.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('❌ Failed to mark as resolved: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update alert status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade800,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                '🚨 ${widget.patientName} left the safe zone!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Last seen at: ${widget.alertLocation.latitude.toStringAsFixed(5)}, ${widget.alertLocation.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.alertLocation,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('alert_location'),
                      position: widget.alertLocation,
                      infoWindow: const InfoWindow(title: 'Alert Location'),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  onMapCreated: (controller) {},
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Triggered at: ${widget.alertTime.hour}:${widget.alertTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _markAsResolved(context),
                child: const Text(
                  'Mark as Resolved',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
