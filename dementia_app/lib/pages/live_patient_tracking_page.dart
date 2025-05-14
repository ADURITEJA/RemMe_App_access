// File: lib/pages/live_patient_tracking_page.dart

import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'danger_zone_setup_page.dart';
import 'danger_zone_alerts_page.dart';
import 'alerts_log_page.dart';

// Color Palette
const Color royalBlue = Color(0xFF1A237E);
const Color quicksand = Color(0xFFF4A460);
const Color alertRed = Color(0xFFD32F2F);

class LivePatientTrackingPage extends StatefulWidget {
  final String patientUid; // UID to fetch location from Firestore

  const LivePatientTrackingPage({super.key, required this.patientUid});

  @override
  State<LivePatientTrackingPage> createState() =>
      _LivePatientTrackingPageState();
}

class _LivePatientTrackingPageState extends State<LivePatientTrackingPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Marker? _patientMarker;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _locationStream;
  Stream<QuerySnapshot>? _alertsStream;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlertActive = false;
  Set<Circle> _safetyZones = {};
  double? _safetyZoneRadius;

  @override
  void initState() {
    super.initState();
    _startListeningToPatientLocation();
    _startListeningToAlerts();
    _loadSafetyZones();
  }

  // Helper method to calculate distance between two points in meters
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - 
        cos((lat2 - lat1) * p) / 2 + 
        cos(lat1 * p) * cos(lat2 * p) * 
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000; R = 6371 km
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSafetyZones() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('zones')
          .get();

      setState(() {
        _safetyZones = snapshot.docs.map((doc) {
          final data = doc.data();
          final center = data['center'] as Map<String, dynamic>;
          final radius = (data['radius'] ?? 200).toDouble();
          _safetyZoneRadius = radius;
          
          return Circle(
            circleId: CircleId('safety_zone_${doc.id}'),
            center: LatLng(center['lat'], center['lng']),
            radius: radius,
            strokeWidth: 2,
            strokeColor: Colors.blue,
            fillColor: Colors.blue.withOpacity(0.1),
          );
        }).toSet();
      });
    } catch (e) {
      print('Error loading safety zones: $e');
    }
  }

  void _startListeningToPatientLocation() {
    _locationStream =
        FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientUid)
            .snapshots();

    _locationStream!.listen((snapshot) {
      final data = snapshot.data();
      if (data == null || data['location'] == null) return;

      final lat = data['location']['lat'];
      final lng = data['location']['lng'];
      final inDangerZone = data['inDangerZone'] ?? false;

      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);
        setState(() {
          _currentLocation = newLocation;
          _patientMarker = Marker(
            markerId: const MarkerId('patient_marker'),
            position: newLocation,
            infoWindow: InfoWindow(
              title: 'Patient Location',
              snippet: inDangerZone ? 'Outside Safety Zone' : 'Within Safety Zone',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              inDangerZone 
                  ? BitmapDescriptor.hueRed 
                  : BitmapDescriptor.hueAzure,
            ),
          );
        });

        // Smooth animate the camera to new location
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
        }
      }
    });
  }

  void _startListeningToAlerts() {
    _alertsStream = FirebaseFirestore.instance
        .collection('alerts')
        .where('patientUid', isEqualTo: widget.patientUid)
        .where('resolved', isEqualTo: false)
        .snapshots();

    _alertsStream!.listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_isAlertActive) {
          _isAlertActive = true;
          await _showAlertDialog(
            context,
            alertId: doc.id,
            patientName: data['patientName'] ?? 'Patient',
            alertLocation: LatLng(
              data['location']['lat'],
              data['location']['lng'],
            ),
            alertTime: (data['timestamp'] as Timestamp).toDate(),
          );
          _isAlertActive = false;
        }
      }
    });
  }

  Future<void> _showAlertDialog(
    BuildContext context, {
    required String alertId,
    required String patientName,
    required LatLng alertLocation,
    required DateTime alertTime,
  }) async {
    // Play alert sound
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/alert_sound.wav'));

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: alertRed,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Danger Zone Alert!', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$patientName has entered a danger zone!', 
              style: const TextStyle(color: Colors.white, fontSize: 16)
            ),
            const SizedBox(height: 12),
            Text('Location: ${alertLocation.latitude.toStringAsFixed(5)}, ${alertLocation.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)
            ),
            Text('Time: ${alertTime.hour}:${alertTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _audioPlayer.stop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DangerZoneAlertsPage(
                    alertId: alertId,
                    patientName: patientName,
                    alertLocation: alertLocation,
                    alertTime: alertTime,
                  ),
                ),
              );
            },
            child: const Text('VIEW DETAILS', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _audioPlayer.stop();
              FirebaseFirestore.instance.collection('alerts').doc(alertId).update({'resolved': true});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: alertRed,
            ),
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: royalBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _patientMarker?.icon == BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) 
                        ? Colors.red 
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  _patientMarker?.icon == BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                      ? 'In Danger Zone'
                      : 'Safe',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }



  // Build safety zone options grid
  Widget _buildSafetyZoneGrid() {
    final List<Map<String, dynamic>> zoneOptions = [
      {
        'icon': Icons.add_location_alt,
        'label': 'New Zone',
        'onTap': () => _navigateToZoneSetup(),
      },
      {
        'icon': Icons.edit_location_alt,
        'label': 'Edit Zones',
        'onTap': () => _navigateToZoneSetup(editMode: true),
      },
      {
        'icon': Icons.delete_forever,
        'label': 'Clear All',
        'onTap': _confirmClearAllZones,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: zoneOptions.length,
      itemBuilder: (context, index) {
        final option = zoneOptions[index];
        return _buildZoneOption(
          icon: option['icon'],
          label: option['label'],
          onTap: option['onTap'],
        );
      },
    );
  }

  Widget _buildZoneOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: royalBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToZoneSetup({bool editMode = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DangerZoneSetupPage(patientUid: widget.patientUid),
      ),
    );
  }

  Future<void> _confirmClearAllZones() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Safety Zones?'),
        content: const Text(
            'This will remove all safety zones for this patient. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllZones();
    }
  }

  Future<void> _clearAllZones() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clearing all safety zones...')),
      );

      // Get all zones for this patient
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('zones')
          .get();

      // Delete each zone
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update UI
      setState(() {
        _safetyZones.clear();
        _safetyZoneRadius = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All safety zones have been removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing zones: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking & Safety Zone Setup'),
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertsLogPage(),
                ),
              );
            },
            tooltip: 'View Alert History',
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 17,
                        ),
                        markers: _patientMarker != null ? {_patientMarker!} : {},
                        circles: _safetyZones,
                        onMapCreated: (controller) => _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        onTap: (latLng) {
                          // Show safety zone info if tapped near a zone
                          for (final zone in _safetyZones) {
                            final distance = _calculateDistance(
                              zone.center.latitude,
                              zone.center.longitude,
                              latLng.latitude,
                              latLng.longitude,
                            );
                            if (distance <= zone.radius * 1.5) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Safety Zone'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Radius: ${zone.radius.toStringAsFixed(0)} meters'),
                                      const SizedBox(height: 8),
                                      Text('Tap and hold to edit', 
                                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('CLOSE'),
                                    ),
                                  ],
                                ),
                              );
                              break;
                            }
                          }
                        },
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (_currentLocation != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(_currentLocation!),
                              );
                            }
                          },
                          child: const Icon(Icons.my_location, color: royalBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                // Patient Info Card
                _buildPatientInfoCard(),
                
                // Safety Zone Info & Controls
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safety Zone Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: royalBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Zone status
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _safetyZones.isNotEmpty ? Colors.blue : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _safetyZones.isNotEmpty
                                  ? '${_safetyZones.length} safety zone${_safetyZones.length > 1 ? 's' : ''} active'
                                  : 'No safety zones',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (_safetyZoneRadius != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Current radius: ${_safetyZoneRadius!.toStringAsFixed(0)} meters',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Zone actions grid
                        _buildSafetyZoneGrid(),
                      ],
                    ),
                  ),
                ),

              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DangerZoneSetupPage(patientUid: widget.patientUid),
            ),
          );
        },
        backgroundColor: quicksand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.dangerous_rounded),
        label: const Text('Setup Safety Zone'),
      ),
    );
  }
}
