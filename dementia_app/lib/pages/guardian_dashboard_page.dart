import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'add_patient_page.dart';
import 'patient_tracking_zone_page.dart';
import 'danger_zone_alerts_page.dart';
import 'alerts_log_page.dart';
import 'profile_page.dart';
import 'guardian_routine_list_page.dart';

class GuardianDashboardPage extends StatefulWidget {
  const GuardianDashboardPage({super.key});

  @override
  State<GuardianDashboardPage> createState() => _GuardianDashboardPageState();
}

class _GuardianDashboardPageState extends State<GuardianDashboardPage>
    with TickerProviderStateMixin {
  String? _selectedPatientUid;
  List<Map<String, dynamic>> _linkedPatients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _hasUnresolvedAlerts = false;

  late final AnimationController _animationController;
  late final AudioPlayer _audioPlayer;
  StreamSubscription<QuerySnapshot>? _unresolvedAlertSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadLinkedPatients();
    _setupFirebaseMessaging();
    _watchUnresolvedAlerts();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    _unresolvedAlertSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLinkedPatients() async {
    final guardianUid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _isLoading = true);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('guardians')
            .doc(guardianUid)
            .collection('linkedPatients')
            .get();

    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString('lastSelectedPatientUid');

    final newLinkedPatients =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'name': data['name'] ?? 'Unnamed',
            'photoUrl': data['photoUrl'] ?? '',
          };
        }).toList();

    if (newLinkedPatients.any((p) => p['uid'] == cachedUid)) {
      _selectedPatientUid = cachedUid;
    } else if (newLinkedPatients.isNotEmpty) {
      _selectedPatientUid = newLinkedPatients.last['uid'];
      await _saveLastSelectedPatient(_selectedPatientUid!);
    }

    setState(() {
      _linkedPatients = newLinkedPatients;
      _isLoading = false;
    });
  }

  Future<void> _saveLastSelectedPatient(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedPatientUid', uid);
  }

  void _setupFirebaseMessaging() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('guardians')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      await _audioPlayer.play(AssetSource('sounds/alert_sound.wav'));

      if (data.containsKey('alertId')) {
        final alertId = data['alertId'];
        final patientName = data['patientName'] ?? 'Unknown';
        final lat = double.tryParse(data['lat'] ?? '');
        final lng = double.tryParse(data['lng'] ?? '');
        final timestamp = DateTime.tryParse(data['timestamp'] ?? '');

        if (lat != null && lng != null && timestamp != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DangerZoneAlertsPage(
                    alertId: alertId,
                    patientName: patientName,
                    alertLocation: LatLng(lat, lng),
                    alertTime: timestamp,
                  ),
            ),
          );
        }
      }
    });
  }

  void _watchUnresolvedAlerts() {
    final guardianUid = FirebaseAuth.instance.currentUser!.uid;
    _unresolvedAlertSub = FirebaseFirestore.instance
        .collection('alerts')
        .where('resolved', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _hasUnresolvedAlerts = snapshot.docs.isNotEmpty;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients =
        _linkedPatients
            .where(
              (p) =>
                  p['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Guardian Dashboard'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_hasUnresolvedAlerts)
                  FadeTransition(
                    opacity: _animationController,
                    child: const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.brightness_1,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsLogPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final doc =
                  await FirebaseFirestore.instance
                      .collection('guardians')
                      .doc(uid)
                      .get();
              final profileData = doc.data() ?? {};
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(profileData: profileData),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB5F2EA),
              Color(0xFFB8D9F8),
              Color(0xFFE4B5F2),
              Color(0xFFFAD6D6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
                  child: Column(
                    children: [
                      const Text(
                        '👩‍⚕️ Welcome, Guardian!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSearchAndDropdown(filteredPatients),
                      const SizedBox(height: 30),
                      _buildFeatureButtons(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSearchAndDropdown(List<Map<String, dynamic>> filteredPatients) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.purple[50],
            hintText: 'Search patients...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 16),
        _linkedPatients.isEmpty
            ? const Text(
              'No patients linked yet.',
              style: TextStyle(color: Colors.white),
            )
            : DropdownButton<String>(
              value: _selectedPatientUid,
              isExpanded: true,
              dropdownColor: Colors.pink[50],
              items:
                  filteredPatients.map((patient) {
                    return DropdownMenuItem<String>(
                      value: patient['uid'],
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                patient['photoUrl'].isNotEmpty
                                    ? NetworkImage(patient['photoUrl'])
                                    : null,
                            child:
                                patient['photoUrl'].isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                          ),
                          const SizedBox(width: 10),
                          Text(patient['name']),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (val) {
                setState(() => _selectedPatientUid = val);
                if (val != null) _saveLastSelectedPatient(val);
              },
            ),
      ],
    );
  }

  Widget _buildFeatureButtons() {
    final uid = _selectedPatientUid;
    final name = _getSelectedPatientName();

    return Column(
      children: [
        _buildButton(
          label: 'Add Patient',
          icon: Icons.person_add_alt,
          color: Colors.pinkAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPatientPage()),
            ).then((_) => _loadLinkedPatients());
          },
        ),
        _buildButton(
          label: 'Safety Zone',
          icon: Icons.map,
          color: Colors.teal,
          onTap:
              uid == null
                  ? () => _showNoPatientError(context)
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PatientTrackingZonePage(
                              patientUid: uid,
                              patientName: name,
                            ),
                      ),
                    );
                  },
        ),
        _buildButton(
          label: 'View Routines',
          icon: Icons.list_alt,
          color: Colors.orangeAccent,
          onTap:
              uid == null
                  ? () => _showNoPatientError(context)
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => GuardianRoutineListPage(patientUid: uid),
                      ),
                    );
                  },
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        ),
      ),
    );
  }

  void _showNoPatientError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❗ Please select a patient first.')),
    );
  }

  String _getSelectedPatientName() {
    final match = _linkedPatients.firstWhere(
      (p) => p['uid'] == _selectedPatientUid,
      orElse: () => {'name': 'Unknown'},
    );
    return match['name'];
  }
}
