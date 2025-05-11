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
import 'guardian_patient_progress_page.dart';

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

  // Define colors from the provided palette
  final Color backgroundColorSolid = const Color(
    0xFFF9EFE5,
  ); // Brand Beige for solid background
  final Color gridItemColor = const Color(0xFF000000); // Black for grid items
  final Color accentColor = const Color(0xFFFF6F61); // Derived Coral for alerts
  final Color textColorPrimary = const Color(0xFF000000); // Brand Black
  final Color textColorSecondary = const Color(
    0xFF7F8790,
  ); // Base Muted Gray-Blue
  final Color cardBackgroundColor = const Color(0xFFF8F8F8); // Base Light Gray

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
    try {
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
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading patients: $e',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _saveLastSelectedPatient(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedPatientUid', uid);
  }

  void _setupFirebaseMessaging() async {
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error setting up notifications: $e',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
        title: const Text(
          'Guardian Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(color: backgroundColorSolid),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, color: textColorPrimary, size: 28),
                if (_hasUnresolvedAlerts)
                  FadeTransition(
                    opacity: _animationController,
                    child: const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.brightness_1,
                        size: 12,
                        color: Color(0xFFFF6F61),
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
            icon: Icon(Icons.account_circle, color: textColorPrimary, size: 28),
            onPressed: () async {
              try {
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
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading profile: $e',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    backgroundColor: accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        color: backgroundColorSolid,
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: textColorPrimary),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
                  child: Column(
                    children: [
                      const Text(
                        '👩‍⚕️ Welcome, Guardian!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildSearchAndDropdown(filteredPatients),
                      const SizedBox(height: 40),
                      _buildFeatureButtons(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSearchAndDropdown(List<Map<String, dynamic>> filteredPatients) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cardBackgroundColor.withOpacity(0.9),
          border: Border.all(
            color: textColorSecondary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: textColorSecondary.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Patient',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF7F8790).withOpacity(0.1),
                hintText: 'Search patients...',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8790),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8790)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: textColorSecondary.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: textColorSecondary.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF7F8790),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),
            _linkedPatients.isEmpty
                ? const Text(
                  'No patients linked yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF000000),
                    fontStyle: FontStyle.italic,
                  ),
                )
                : DropdownButton<String>(
                  value: _selectedPatientUid,
                  isExpanded: true,
                  dropdownColor: cardBackgroundColor,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF000000),
                    size: 28,
                  ),
                  underline: const SizedBox(),
                  items:
                      filteredPatients.map((patient) {
                        return DropdownMenuItem<String>(
                          value: patient['uid'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    patient['photoUrl'].isNotEmpty
                                        ? NetworkImage(patient['photoUrl'])
                                        : null,
                                child:
                                    patient['photoUrl'].isEmpty
                                        ? Icon(
                                          Icons.person,
                                          color: textColorPrimary,
                                          size: 20,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                patient['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7F8790),
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildFeatureButtons() {
    final uid = _selectedPatientUid;
    final name = _getSelectedPatientName();

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildButton(
          label: 'Add Patient',
          icon: Icons.person_add_alt,
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
        _buildButton(
          label: 'Patient Progress',
          icon: Icons.trending_up,
          onTap:
              uid == null
                  ? () => _showNoPatientError(context)
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => GuardianPatientProgressPage(
                              patientUid: uid,
                              patientName: name,
                            ),
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
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: gridItemColor, // Use #000000 for border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: gridItemColor, // Use #000000 for background
            foregroundColor:
                backgroundColorSolid, // Use #F9EFE5 for text/icon contrast
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            elevation: 5,
            shadowColor: gridItemColor.withOpacity(
              0.2,
            ), // Use #000000 for shadow
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              gridItemColor.withOpacity(0.2),
            ), // Use #000000 for overlay
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoPatientError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '❗ Please select a patient first.',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
