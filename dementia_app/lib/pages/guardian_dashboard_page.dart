import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alerts_log_page.dart';
import 'profile_page.dart';
import 'guardian_patient_progress_page.dart';
import 'live_patient_tracking_page.dart';
import 'routine/routine_list_page.dart';
import 'add_patient_page.dart';

// Color Palette
const Color royalBlue = Color(0xFF1A237E);
const Color quicksand = Color(0xFFF4A460);
const Color swanWing = Color(0xFFF5F5F5);

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

  // Uber-inspired color scheme
  final Color backgroundColor = swanWing;
  final Color primaryColor = royalBlue;
  final Color accentColor = quicksand;
  final Color textColor = Colors.black87;
  final Color secondaryTextColor = Colors.grey[800]!;
  final Color cardColor = Colors.white;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadLinkedPatients();
    _watchUnresolvedAlerts();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _watchUnresolvedAlerts() {
    final guardianUid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Guardian Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                if (_hasUnresolvedAlerts)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
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
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () async {
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final doc =
                    await FirebaseFirestore.instance
                        .collection('guardians')
                        .doc(uid)
                        .get();
                final profileData = doc.data() ?? {};
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(profileData: profileData),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading profile: $e',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: royalBlue))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Hello Guardian!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your patients and their care',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildSearchAndDropdown(filteredPatients),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureButtons(),
                  ],
                ),
              ),
    );
  }

  Future<void> _showAddPatientDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPatientPage(),
      ),
    );

    if (result == true && mounted) {
      // Refresh the patient list if a patient was successfully added
      await _loadLinkedPatients();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient linked successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }
  }

  Widget _buildSearchAndDropdown(List<Map<String, dynamic>> filteredPatients) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (filteredPatients.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _selectedPatientUid,
                decoration: InputDecoration(
                  labelText: 'Choose a patient',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items:
                    _linkedPatients.map<DropdownMenuItem<String>>((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['uid'] as String,
                        child: Text(
                          patient['name'] as String,
                          style: const TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedPatientUid = value;
                  });
                  if (value != null) {
                    await _saveLastSelectedPatient(value);
                  }
                },
                selectedItemBuilder: (BuildContext context) {
                  return _linkedPatients.map<Widget>((patient) {
                    return PopupMenuItem<String>(
                      value: patient['uid'],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient['name'],
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.link_off,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close the dropdown
                              _unlinkPatient(
                                patientUid: patient['uid'],
                                patientName: patient['name'] ?? 'Patient',
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Unlink patient',
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No patients found',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _showAddPatientDialog,
              style: TextButton.styleFrom(
                foregroundColor: royalBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 20),
                  SizedBox(width: 8),
                  Text('Add Patient by UID'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _unlinkPatient({
    required String patientUid,
    required String patientName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unlink Patient'),
            content: Text(
              'Are you sure you want to unlink $patientName? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('UNLINK'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final guardianUid = FirebaseAuth.instance.currentUser!.uid;

      // Remove from guardian's linked patients
      await FirebaseFirestore.instance
          .collection('guardians')
          .doc(guardianUid)
          .collection('linkedPatients')
          .doc(patientUid)
          .delete();

      // Remove guardian from patient's guardians list
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientUid)
          .collection('guardians')
          .doc(guardianUid)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully unlinked $patientName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await _loadLinkedPatients(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to unlink patient: ${e.toString().split(']').last.trim()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildFeatureButtons() {
    final selectedPatient = _linkedPatients.firstWhere(
      (p) => p['uid'] == _selectedPatientUid,
      orElse: () => <String, dynamic>{},
    );
    final uid = selectedPatient['uid'] as String?;
    final name = selectedPatient['name'] as String?;

    final features = [
      {
        'label': 'Patient Routines',
        'icon': Icons.schedule_rounded,
        'color': Colors.blue[700],
        'onTap': () {
          if (uid == null) {
            _showNoPatientError(context);
            return;
          }
          final patient = _linkedPatients.firstWhere(
            (p) => p['uid'] == uid,
            orElse: () => {'name': 'Patient'},
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => RoutineListPage(
                    patientUid: uid,
                    patientName: patient['name'] ?? 'Patient',
                  ),
            ),
          );
        },
      },
      {
        'label': 'Patient Progress',
        'icon': Icons.trending_up_rounded,
        'color': Colors.green[700],
        'onTap': () {
          if (uid == null) {
            _showNoPatientError(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => GuardianPatientProgressPage(
                    patientUid: uid,
                    patientName: name ?? 'Patient',
                  ),
            ),
          );
        },
      },
      {
        'label': 'Live Tracking & Safety Zone Setup',
        'icon': Icons.location_on_rounded,
        'color': Colors.red[700],
        'onTap': () {
          if (uid == null) {
            _showNoPatientError(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LivePatientTrackingPage(patientUid: uid),
            ),
          );
        },
      },
      {
        'label': 'Medication',
        'icon': Icons.medication_rounded,
        'color': Colors.orange[700],
        'onTap': () {
          _showNoPatientError(context);
        },
      },
      {
        'label': 'Appointments',
        'icon': Icons.calendar_today_rounded,
        'color': Colors.purple[700],
        'onTap': () {
          _showNoPatientError(context);
        },
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.only(bottom: 16),
      children:
          features.map((feature) {
            return _buildButton(
              label: feature['label'] as String,
              icon: feature['icon'] as IconData,
              color: feature['color'] as Color?,
              onTap: feature['onTap'] as VoidCallback,
            );
          }).toList(),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? primaryColor;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: buttonColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 24, color: buttonColor),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNoPatientError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Please select a patient first',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
