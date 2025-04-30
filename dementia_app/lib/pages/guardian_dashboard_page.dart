// File: lib/pages/guardian_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_app/pages/danger_zone_setup_page.dart';
import 'package:dementia_app/pages/live_patient_tracking_page.dart';
import 'package:dementia_app/pages/add_patient_page.dart';
import 'package:dementia_app/pages/guardian_alerts_list_page.dart';
import 'package:dementia_app/main.dart'; // For MedicalAIChatBotPage

class GuardianDashboardPage extends StatefulWidget {
  const GuardianDashboardPage({super.key});

  @override
  State<GuardianDashboardPage> createState() => _GuardianDashboardPageState();
}

class _GuardianDashboardPageState extends State<GuardianDashboardPage> {
  String? _selectedPatientUid;
  List<Map<String, dynamic>> _linkedPatients = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLinkedPatients();
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

    bool selectedPatientChanged = false;

    if (newLinkedPatients.any((p) => p['uid'] == cachedUid)) {
      _selectedPatientUid = cachedUid;
    } else if (newLinkedPatients.isNotEmpty) {
      _selectedPatientUid = newLinkedPatients.last['uid'];
      await _saveLastSelectedPatient(_selectedPatientUid!);
      selectedPatientChanged = true;
    }

    setState(() {
      _linkedPatients = newLinkedPatients;
      _isLoading = false;
    });

    if (selectedPatientChanged) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ New patient selected successfully!')),
        );
      }
    }
  }

  Future<void> _saveLastSelectedPatient(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedPatientUid', uid);
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
      appBar: AppBar(title: const Text('Guardian Dashboard')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome to Guardian Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_linkedPatients.isNotEmpty)
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search patients by name...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) => setState(() => _searchQuery = value),
                        ),

                      const SizedBox(height: 16),

                      if (filteredPatients.isNotEmpty)
                        DropdownButton<String>(
                          value: _selectedPatientUid,
                          isExpanded: true,
                          hint: const Text('Select Patient'),
                          items:
                              filteredPatients.map((patient) {
                                return DropdownMenuItem<String>(
                                  value: patient['uid'],
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage:
                                            patient['photoUrl'].isNotEmpty
                                                ? NetworkImage(
                                                  patient['photoUrl'],
                                                )
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
                          onChanged: (value) {
                            setState(() => _selectedPatientUid = value);
                            if (value != null) _saveLastSelectedPatient(value);
                          },
                        )
                      else if (_linkedPatients.isNotEmpty)
                        const Text('No matching patients.')
                      else
                        const Text('No patients linked yet. Add one first.'),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPatientPage(),
                            ),
                          ).then((_) => _loadLinkedPatients());
                        },
                        child: const Text('Add Patient'),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed:
                            _selectedPatientUid == null
                                ? () => _showNoPatientError(context)
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DangerZoneSetupPage(
                                            patientUid: _selectedPatientUid!,
                                          ),
                                    ),
                                  );
                                },
                        child: const Text('Setup Safety Zone'),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed:
                            _selectedPatientUid == null
                                ? () => _showNoPatientError(context)
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => GuardianAlertsListPage(
                                            patientUid: _selectedPatientUid!,
                                            patientName:
                                                _getSelectedPatientName(),
                                          ),
                                    ),
                                  );
                                },
                        child: const Text('View Danger Zone Alerts'),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed:
                            _selectedPatientUid == null
                                ? () => _showNoPatientError(context)
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LivePatientTrackingPage(
                                            patientUid: _selectedPatientUid!,
                                          ),
                                    ),
                                  );
                                },
                        child: const Text('Live Patient Tracking'),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const MedicalAIChatBotPage(),
                            ),
                          );
                        },
                        child: const Text('Medical AI Chatbot'),
                      ),
                    ],
                  ),
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
