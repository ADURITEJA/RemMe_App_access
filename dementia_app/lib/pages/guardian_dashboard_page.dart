import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../test/danger_zone_test_page.dart';
import 'guardian_routine_list_page.dart';

// Pages
import 'alerts_log_page.dart';
import 'profile_page.dart';
import 'danger_zone_alerts_page.dart';
import 'danger_zone_setup_page.dart';
import 'live_patient_tracking_page.dart';

class GuardianDashboardPage extends StatefulWidget {
  const GuardianDashboardPage({super.key});

  @override
  State<GuardianDashboardPage> createState() => _GuardianDashboardPageState();
}

class _GuardianDashboardPageState extends State<GuardianDashboardPage>
    with TickerProviderStateMixin {
  // State variables
  String? _selectedPatientUid;
  List<Map<String, dynamic>> _linkedPatients = [];
  bool _isLoading = false;
  bool _hasUnresolvedAlerts = false;
  final TextEditingController _searchController = TextEditingController();

  // Animation and audio
  late final AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _unresolvedAlertSub;

  // Modern Color Scheme
  static const Color primaryColor = Color(0xFF00B4AB);  // Teal
  static const Color primaryDark = Color(0xFF00897B);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFE53935);
  
  // Modern Text Styles
  final TextStyle headingStyle = const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    fontFamily: 'Roboto',
  );
  
  final TextStyle subheadingStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
    fontFamily: 'Roboto',
  );
  
  final TextStyle labelStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Roboto',
    letterSpacing: 0.1,
  );
  
  final TextStyle buttonTextStyle = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );
  
  // Card Decoration
  BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Input Decoration
  InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintStyle: subheadingStyle.copyWith(color: textSecondary.withOpacity(0.6)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadLinkedPatients();
    _setupFirebaseMessaging();
    _loadLastSelectedPatient();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _unresolvedAlertSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedPatients() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('guardians')
              .doc(user.uid)
              .collection('linkedPatients')
              .get();

      setState(() {
        _linkedPatients =
            querySnapshot.docs
                .map(
                  (doc) => {
                    'uid': doc.id,
                    'name': doc.data()['name'] ?? 'Unknown',
                    'photoUrl': doc.data()['photoUrl'] ?? '',
                  },
                )
                .toList();

        if (_linkedPatients.isNotEmpty && _selectedPatientUid == null) {
          _selectedPatientUid = _linkedPatients.first['uid'];
        }
      });
    } catch (e) {
      debugPrint('Error loading linked patients: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLastSelectedPatient() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedUid = prefs.getString('lastSelectedPatientUid');
    if (lastSelectedUid != null && mounted) {
      setState(() => _selectedPatientUid = lastSelectedUid);
    }
  }

  Future<void> _saveLastSelectedPatient(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedPatientUid', uid);
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle notification messages
      if (message.notification != null) {
        _showNotification(message.notification!);
      }

      // Handle data messages
      if (message.data.isNotEmpty) {
        if (message.data['type'] == 'danger_zone') {
          _handleDangerZoneAlert(message);
        }
      }
    });

    _watchUnresolvedAlerts();
  }

  void _watchUnresolvedAlerts() {
    _unresolvedAlertSub = FirebaseFirestore.instance
        .collection('alerts')
        .where('resolved', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() => _hasUnresolvedAlerts = snapshot.docs.isNotEmpty);
          }
        });
  }

  void _showNotification(RemoteNotification notification) {
    if (!mounted) return;

    // Show regular notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification.body ?? 'New notification'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _handleDangerZoneAlert(RemoteMessage message) async {
    try {
      final data = message.data;
      final patientId = data['patientId'];

      // Get patient details
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .get();

      if (!patientDoc.exists) return;

      // Play alert sound
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/alert_sound.wav'));

      // Show full-screen alert
      if (!mounted) return;

      final locationData = data['location']!.split(',');
      final location = LatLng(
        double.parse(locationData[0]),
        double.parse(locationData[1]),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => DangerZoneAlertsPage(
              alertId: data['alertId']!,
              patientName: patientDoc['name'] ?? 'Patient',
              alertLocation: location,
              alertTime: DateTime.parse(data['timestamp']!),
            ),
      );
    } catch (e) {
      debugPrint('Error handling danger zone alert: $e');
    }
  }

  void _showNoPatientError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select a patient first'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Build the notification button in app bar
  Widget _buildNotificationButton() {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: textPrimary,
            size: 24,
          ),
          if (_hasUnresolvedAlerts)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertsLogPage()),
        );
      },
    );
  }

  // Build the profile button in app bar
  Widget _buildProfileButton() {
    return IconButton(
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          color: primaryColor,
          size: 20,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(profileData: {}),
          ),
        );
      },
    );
  }

  // Build welcome section with greeting and date
  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMMM d');
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: headingStyle.copyWith(
              color: primaryDark,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(now),
            style: subheadingStyle.copyWith(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Build search and patient dropdown
  Widget _buildSearchAndDropdown(List<Map<String, dynamic>> filteredPatients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Patient',
            style: labelStyle.copyWith(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPatientUid,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textSecondary),
                hint: Text('Select a patient', style: subheadingStyle.copyWith(color: textSecondary.withOpacity(0.7))),
                items: filteredPatients.map((patient) {
                  return DropdownMenuItem<String>(
                    value: patient['uid'],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        patient['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPatientUid = newValue;
                      _saveLastSelectedPatient(newValue);
                    });
                  }
                },
                dropdownColor: surfaceColor,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                menuMaxHeight: 300,
                style: subheadingStyle.copyWith(color: textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feature items list with modern colors
  final List<Map<String, dynamic>> _featureItems = [
    {
      'icon': Icons.calendar_today_rounded,
      'label': 'Routines',
      'color': const Color(0xFF4CAF50),
    },
    {
      'icon': Icons.analytics_rounded,
      'label': 'Progress',
      'color': const Color(0xFF2196F3),
    },
    {
      'icon': Icons.location_on_rounded,
      'label': 'Live Tracking',
      'color': const Color(0xFF9C27B0),
    },
    {
      'icon': Icons.dangerous_rounded,
      'label': 'Danger Zones',
      'color': const Color(0xFFF44336),
    },
    {
      'icon': Icons.settings_rounded,
      'label': 'Settings',
      'color': const Color(0xFF607D8B),
    },
  ];
  
  // Handle feature tap
  void _onFeatureTapped(int index) {
    if (_selectedPatientUid == null) {
      _showNoPatientError();
      return;
    }
    
    switch (index) {
      case 0: // Routines
        final selectedPatient = _linkedPatients.firstWhere(
          (p) => p['uid'] == _selectedPatientUid,
          orElse: () => {'name': 'Patient'},
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuardianRoutineListPage(
              patientUid: _selectedPatientUid!,
              patientName: selectedPatient['name'] ?? 'Patient',
            ),
          ),
        );
        break;
        
      case 1: // Progress
        // Navigate to progress page
        break;
        
      case 2: // Live Tracking
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LivePatientTrackingPage(
              patientUid: _selectedPatientUid!,
            ),
          ),
        );
        break;
        
      case 3: // Danger Zones
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DangerZoneSetupPage(
              patientUid: _selectedPatientUid!,
            ),
          ),
        );
        break;
        
      case 4: // Settings
        // Navigate to settings page
        break;
    }
  }

  // Build feature buttons grid with modern cards
  Widget _buildFeatureButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              'Features',
              style: labelStyle.copyWith(
                fontSize: 15,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _featureItems.length,
            itemBuilder: (context, index) {
              final item = _featureItems[index];
              return _buildFeatureCard(
                icon: item['icon'],
                label: item['label'],
                color: item['color'],
                onTap: () => _onFeatureTapped(index),
              );
            },
          ),
        ],
      ),
    );
  }

  // Build individual feature card with hover effect
  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients =
        _linkedPatients.where((patient) {
          return patient['name'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
        }).toList();

    final testButton =
        kDebugMode
            ? Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'test_button',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DangerZoneTestPage(),
                    ),
                  );
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.warning, color: Colors.white),
              ),
            )
            : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        centerTitle: false,
        title: Text(
          'Dashboard',
          style: headingStyle.copyWith(
            color: textPrimary,
            fontSize: 22,
          ),
        ),
        actions: [
          _buildNotificationButton(),
          _buildProfileButton(),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          else
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  _buildSearchAndDropdown(filteredPatients),
                  _buildFeatureButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          if (kDebugMode) testButton,
        ],
      ),
    );
  }
}
