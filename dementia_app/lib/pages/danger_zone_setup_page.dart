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

  // Predefined radius options in meters
  final List<Map<String, dynamic>> _radiusOptions = [
    {'value': 100, 'label': '100m', 'icon': Icons.directions_walk},
    {'value': 200, 'label': '200m', 'icon': Icons.directions_run},
    {'value': 300, 'label': '300m', 'icon': Icons.directions_bike},
    {'value': 500, 'label': '500m', 'icon': Icons.directions_car},
    {'value': 750, 'label': '750m', 'icon': Icons.directions_bus},
    {'value': 1000, 'label': '1km', 'icon': Icons.place},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Safety Zone'),
        backgroundColor: const Color(0xFF1A237E), // Royal blue
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map Section (60% of screen)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.5937, 78.9629), // Default India center
                    zoom: 14, // Zoomed in more by default
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Center on current location if available
                    _getCurrentLocation();
                  },
                  onTap: _onMapTap,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                if (_saving)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (_zoneCenter != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_zoneRadius.toInt()}m radius',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Controls Section (40% of screen)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Zone Radius',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Grid of radius options
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _radiusOptions.length,
                  itemBuilder: (context, index) {
                    final option = _radiusOptions[index];
                    final isSelected = _zoneRadius == option['value'];
                    return _buildRadiusOption(
                      icon: option['icon'],
                      label: option['label'],
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _zoneRadius = option['value'].toDouble();
                          _updateCircle();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Manual slider for fine adjustment
                Row(
                  children: [
                    const Text('100m'),
                    Expanded(
                      child: Slider(
                        min: 100,
                        max: 1000,
                        divisions: 18,
                        value: _zoneRadius,
                        label: '${_zoneRadius.toInt()}m',
                        onChanged: (value) {
                          setState(() {
                            _zoneRadius = value;
                            _updateCircle();
                          });
                        },
                      ),
                    ),
                    const Text('1km'),
                  ],
                ),
                const SizedBox(height: 16),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _zoneCenter == null ? null : _saveZone,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Safety Zone'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF1A237E),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get current location
  Future<void> _getCurrentLocation() async {
    // In a real app, you would get the actual current location here
    // For now, we'll just use the default location
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(20.5937, 78.9629), // Default India center
          14,
        ),
      );
    }
  }
}
