// File: lib/pages/live_patient_tracking_page.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _startListeningToPatientLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);
        setState(() {
          _currentLocation = newLocation;
          _patientMarker = Marker(
            markerId: const MarkerId('patient_marker'),
            position: newLocation,
            infoWindow: const InfoWindow(title: 'Patient Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Patient Tracking')),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 17,
                ),
                markers: _patientMarker != null ? {_patientMarker!} : {},
                onMapCreated: (controller) => _mapController = controller,
              ),
    );
  }
}
