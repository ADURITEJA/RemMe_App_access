// File: lib/pages/danger_zone_setup_page.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DangerZoneSetupPage extends StatefulWidget {
  final String patientUid;

  const DangerZoneSetupPage({super.key, required this.patientUid});

  @override
  State<DangerZoneSetupPage> createState() => _DangerZoneSetupPageState();
}

class _DangerZoneSetupPageState extends State<DangerZoneSetupPage> {
  GoogleMapController? _mapController;
  LatLng? _zoneCenter;
  double _zoneRadius = 200; // Default radius in meters
  Set<Circle> _circles = {};
  bool _saving = false;

  void _onMapTap(LatLng position) {
    setState(() {
      _zoneCenter = position;
      _updateCircle();
    });
  }

  void _updateCircle() {
    if (_zoneCenter == null) return;
    _circles = {
      Circle(
        circleId: const CircleId('safety_zone'),
        center: _zoneCenter!,
        radius: _zoneRadius,
        strokeWidth: 3,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.2),
      ),
    };
  }

  Future<void> _saveZone() async {
    if (_zoneCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap on the map to set a zone.')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('zones')
          .add({
            'center': {
              'lat': _zoneCenter!.latitude,
              'lng': _zoneCenter!.longitude,
            },
            'radius': _zoneRadius,
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Safety Zone Saved!')));

      Navigator.pop(context); // ✅ Go back after saving
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving zone: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Safety Zone')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // Default India center
              zoom: 5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            circles: _circles,
          ),
          if (_saving)
            const Center(
              child: CircularProgressIndicator(),
            ), // Show loading if saving
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Zone Radius: ${_zoneRadius.toStringAsFixed(0)} meters',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      min: 100,
                      max: 1000,
                      divisions: 18,
                      value: _zoneRadius,
                      label: '${_zoneRadius.toStringAsFixed(0)} m',
                      onChanged: (value) {
                        setState(() {
                          _zoneRadius = value;
                          _updateCircle();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _saveZone,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Safety Zone'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
