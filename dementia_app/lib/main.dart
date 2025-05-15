import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dementia_app/pages/add_patient_page.dart';
import 'package:dementia_app/pages/danger_zone_alerts_page.dart';
import 'package:dementia_app/pages/guardian_dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:convert';
import 'package:dementia_app/pages/patient_tracking_zone_page.dart';
import 'package:dementia_app/pages/alerts_log_page.dart';
import 'package:dementia_app/profile_setup/profile_question_phone.dart';
import 'package:dementia_app/profile_setup/profile_question_gender.dart';
import 'package:dementia_app/profile_setup/profile_question_age.dart';
import 'package:dementia_app/profile_setup/profile_question_name.dart';
import 'package:dementia_app/profile_setup/profile_question_photo.dart';
import 'package:dementia_app/profile_setup/profile_summary_screen.dart';
import 'package:dementia_app/pages/profile_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Handling background message: ${message.messageId}");

  // Show local notification for background messages
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }
}

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ Provisional permission granted');
  } else {
    print('❌ User declined or has not accepted permission');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Before Firebase');
  try {
    await Firebase.initializeApp();
    print('Before AlarmManager');
    await AndroidAlarmManager.initialize();
    print('Before Firebase Messaging');

    // Initialize FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    await _requestNotificationPermission();

    // Get and print FCM token
    final token = await FirebaseMessaging.instance.getToken();
    print("🔔 FCM Token: $token");

    // Subscribe to alerts topic
    await FirebaseMessaging.instance.subscribeToTopic("alerts");
    print("🔔 Subscribed to 'alerts' topic");

    print('Before runApp');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Initialization failed: $e');
    print('Stack trace: $stackTrace');
    // Optionally, you can show an error screen or exit the app
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization failed: $e'))),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupForegroundMessageHandling();
  }

  void _setupForegroundMessageHandling() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Foreground message received: ${message.notification?.title}");

      // Show local notification for foreground messages
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Notification tapped: ${message.notification?.title}");
      // You can add navigation logic here based on the notification
    });
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RoleSelectionPage(),

      routes: {
        '/patient/memories': (context) => const PatientFeaturesPage(),
        '/patient/quiz': (context) => const MemoryQuizGamePage(),
        '/patient/routines': (context) => const PatientRoutinePage(),
        '/patient/chatbot': (context) => const MedicalAIChatBotPage(),

        '/guardian/patient_tracking':
            (context) =>
                const PatientTrackingZonePage(patientUid: '', patientName: ''),

        '/alerts': (context) => const AlertsLogPage(),

        '/profile_question_name': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileQuestionName(profileData: args);
        },
        '/profile/phone': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileQuestionPhone(profileData: args);
        },
        '/profile/gender': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileQuestionGender(profileData: args);
        },
        '/profile/age': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileQuestionAge(profileData: args);
        },
        '/profile/photo': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileQuestionPhoto(profileData: args);
        },
        '/profile/summary': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfileSummaryScreen(profileData: args);
        },

        '/guardian_dashboard': (context) => const GuardianDashboardPage(),
        '/patient_dashboard': (context) => const PatientDashboardPage(),
        '/profile_page': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProfilePage(profileData: args);
        },
      },
    );
  }
}


class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> with SingleTickerProviderStateMixin {
  bool _isHoveringGuardian = false;
  bool _isHoveringPatient = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: swanWing,
      body: Stack(
        children: [
          // Background with gradient overlay
          Container(
            width: double.infinity,
            height: size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [royalBlue, royalBlue.withOpacity(0.9)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Welcome to',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'RemMe Care',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Select your role to continue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Role selection cards
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Guardian Card
                        MouseRegion(
                          onEnter: (_) => setState(() => _isHoveringGuardian = true),
                          onExit: (_) => setState(() => _isHoveringGuardian = false),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GuardianLoginPage(),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_isHoveringGuardian ? 0.15 : 0.1),
                                    blurRadius: _isHoveringGuardian ? 20 : 10,
                                    offset: Offset(0, _isHoveringGuardian ? 8 : 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: _isHoveringGuardian ? quicksand : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: royalBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.people_alt_rounded,
                                      size: 32,
                                      color: royalBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Guardian',
                                          style: TextStyle(
                                            color: royalBlue,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Manage and monitor your loved ones',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: _isHoveringGuardian ? quicksand : Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Patient Card
                        MouseRegion(
                          onEnter: (_) => setState(() => _isHoveringPatient = true),
                          onExit: (_) => setState(() => _isHoveringPatient = false),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PatientLoginPage(),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_isHoveringPatient ? 0.15 : 0.1),
                                    blurRadius: _isHoveringPatient ? 20 : 10,
                                    offset: Offset(0, _isHoveringPatient ? 8 : 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: _isHoveringPatient ? quicksand : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: quicksand.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      size: 32,
                                      color: quicksand,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient',
                                          style: TextStyle(
                                            color: quicksand,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Access your care plan and activities',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: _isHoveringPatient ? quicksand : Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom wave decoration
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.rotate(
                      angle: 3.14,
                      child: ClipPath(
                        clipper: WaveClipper(),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          color: royalBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    
    var firstStart = Offset(size.width / 5, size.height);
    var firstEnd = Offset(size.width / 2.5, size.height - 30.0);
    path.quadraticBezierTo(firstStart.dx, firstStart.dy, firstEnd.dx, firstEnd.dy);
    
    var secondStart = Offset(size.width - (size.width / 3.24), size.height - 65);
    var secondEnd = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondStart.dx, secondStart.dy, secondEnd.dx, secondEnd.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GuardianLoginPage extends StatefulWidget {
  const GuardianLoginPage({super.key});

  @override
  State<GuardianLoginPage> createState() => _GuardianLoginPageState();
}

class _GuardianLoginPageState extends State<GuardianLoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginPressed = false;
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Color scheme
  final Color royalBlue = const Color(0xFF1A237E);
  final Color quickSand = const Color(0xFFF4A460);
  final Color swanWing = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loginGuardian() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoginPressed = true);
      
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        final guardianUid = userCredential.user!.uid;
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('guardians')
              .doc(guardianUid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const GuardianDashboardPage(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoginPressed = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                // Header with gradient
                Container(
                  height: size.height * 0.35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [royalBlue, royalBlue.withOpacity(0.9)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Login Form
                Positioned(
                  top: size.height * 0.25,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildInputField(
                                label: 'Email',
                                controller: _emailController,
                                obscureText: false,
                                icon: Icons.email_outlined,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter your email'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                                icon: Icons.lock_outline,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter your password'
                                        : null,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: royalBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildLoginButton(),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  MouseRegion(
                                    onEnter: (_) => setState(() => _isHovering = true),
                                    onExit: (_) => setState(() => _isHovering = false),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const GuardianRegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: royalBlue,
                                          fontWeight: FontWeight.bold,
                                          decoration: _isHovering ? TextDecoration.underline : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required String? Function(String?) validator,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: royalBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: royalBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovering 
                ? [royalBlue.withOpacity(0.9), royalBlue.withOpacity(0.7)]
                : [royalBlue, royalBlue.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoginPressed ? null : _loginGuardian,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoginPressed
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'LOG IN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginPressed = false;
  bool _isHoveringSignUp = false;
  bool _isHoveringLogin = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loginPatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoginPressed = true;
      });
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        final patientUid = userCredential.user!.uid;
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientUid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        }

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = 'Invalid email or password';
        }
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoginPressed = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: swanWing,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            ),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  // Header with gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [royalBlue, royalBlue.withOpacity(0.9)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 20),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Login Form
                  Positioned.fill(
                    top: size.height * 0.25,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  _buildInputField(
                                    label: 'Email',
                                    controller: _emailController,
                                    obscureText: false,
                                    validator: (value) =>
                                        value == null || value.isEmpty || !value.contains('@')
                                            ? 'Please enter a valid email'
                                            : null,
                                    icon: Icons.email_outlined,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputField(
                                    label: 'Password',
                                    controller: _passwordController,
                                    obscureText: true,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter your password'
                                            : null,
                                    icon: Icons.lock_outline,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildLoginButton(),
                                  const SizedBox(height: 20),
                                  
                                  // Divider with "or" text
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Row(
                                      children: [
                                        const Expanded(child: Divider(thickness: 1)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(child: Divider(thickness: 1)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSocialButton(
                                    icon: 'assets/images/google_icon.png',
                                    label: 'Continue with Google',
                                    onPressed: () {
                                      // TODO: Implement Google Sign In
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Apple Sign In Button
                                  _buildSocialButton(
                                    icon: 'assets/images/apple_icon.png',
                                    label: 'Continue with Apple',
                                    onPressed: () {
                                      // TODO: Implement Apple Sign In
                                    },
                                    isLight: true,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Don\'t have an account? ',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      MouseRegion(
                                        onEnter: (_) => setState(() => _isHoveringSignUp = true),
                                        onExit: (_) => setState(() => _isHoveringSignUp = false),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const PatientRegisterPage(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              color: _isHoveringSignUp ? quicksand : royalBlue,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              decoration: _isHoveringSignUp ? TextDecoration.underline : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required String? Function(String?) validator,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: royalBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    bool isLight = false,
  }) {
    bool isHovering = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLight ? Colors.grey[300]! : Colors.grey[200]!,
                  width: 1.5,
                ),
                boxShadow: [
                  if (isHovering)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // For now using an icon, replace with actual image asset
                  Icon(
                    icon.contains('google') ? Icons.g_mobiledata : Icons.apple,
                    size: 24,
                    color: isLight ? Colors.black : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.grey[800],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringLogin = true),
      onExit: (_) => setState(() => _isHoveringLogin = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHoveringLogin
                ? [royalBlue.withOpacity(0.9), royalBlue]
                : [royalBlue, royalBlue],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: royalBlue.withOpacity(_isHoveringLogin ? 0.4 : 0.2),
              blurRadius: _isHoveringLogin ? 12 : 6,
              offset: Offset(0, _isHoveringLogin ? 6 : 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoginPressed ? null : _loginPatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoginPressed
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'SIGN IN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class GuardianRegisterPage extends StatefulWidget {
  const GuardianRegisterPage({super.key});

  @override
  State<GuardianRegisterPage> createState() => _GuardianRegisterPageState();
}

class _GuardianRegisterPageState extends State<GuardianRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegisterPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerGuardian() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegisterPressed = true;
      });
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        final uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('guardians').doc(uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'role': 'guardian',
        });

        final profileData = {
          'email': _emailController.text,
          'name': _nameController.text,
          'role': 'guardian',
          'uid': uid,
        };

        Navigator.pushReplacementNamed(
          context,
          '/profile_question_name',
          arguments: profileData,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      setState(() {
        _isRegisterPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B5B95), // Purple
              Color(0xFF88B7D5), // Light blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(top: -50, left: -50, child: _buildCircle(150, 0.3)),
            Positioned(top: 100, right: -70, child: _buildCircle(200, 0.2)),
            Positioned(bottom: -60, left: -30, child: _buildCircle(180, 0.3)),
            Positioned(bottom: 50, right: -40, child: _buildCircle(120, 0.2)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Guardian Registration',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          label: 'Name',
                          controller: _nameController,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter your name'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter your email'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter a password'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildSignUpButton(),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Navigate back to login
                          },
                          child: const Text(
                            'Have an account? Log in',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(double radius, double opacity) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isRegisterPressed ? null : _registerGuardian,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B5B95),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class PatientRegisterPage extends StatefulWidget {
  const PatientRegisterPage({super.key});

  @override
  State<PatientRegisterPage> createState() => _PatientRegisterPageState();
}

class _PatientRegisterPageState extends State<PatientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegisterPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerPatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegisterPressed = true;
      });
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        final uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'role': 'patient',
        });

        final profileData = {
          'email': _emailController.text,
          'name': _nameController.text,
          'role': 'patient',
          'uid': uid,
        };

        Navigator.pushReplacementNamed(
          context,
          '/profile_question_name', // Make sure this route is defined
          arguments: profileData,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      setState(() {
        _isRegisterPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B5B95), // Purple
              Color(0xFF88B7D5), // Light blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(top: -50, left: -50, child: _buildCircle(150, 0.3)),
            Positioned(top: 100, right: -70, child: _buildCircle(200, 0.2)),
            Positioned(bottom: -60, left: -30, child: _buildCircle(180, 0.3)),
            Positioned(bottom: 50, right: -40, child: _buildCircle(120, 0.2)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Patient Registration',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          label: 'Name',
                          controller: _nameController,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter your name'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter your email'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter a password'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildSignUpButton(),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Navigate back to login
                          },
                          child: const Text(
                            'Have an account? Log in',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(double radius, double opacity) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isRegisterPressed ? null : _registerPatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B5B95),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Inside main.dart — Just the PatientDashboardPage

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

// Color Palette
const Color royalBlue = Color(0xFF1A237E);
const Color quicksand = Color(0xFFF4A460);
const Color swanWing = Color(0xFFF5F5F5);
const Color darkGrey = Color(0xFF424242);
const Color lightGrey = Color(0xFFEEEEEE);

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final user = FirebaseAuth.instance.currentUser;
  Timer? _locationUpdateTimer;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _timeWindows = ['7 days', '30 days', 'All time'];
  String _selectedWindow = '7 days';
  int remembered = 0, forgotten = 0, totalAttempts = 0;
  double rememberedPercent = 0, forgottenPercent = 0;
  List<DocumentSnapshot> _todayRoutines = [];

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _analyzeQuizResults();
    _fetchTodayRoutines();
  }

  Future<void> _startLocationUpdates() async {
    if (user == null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user!.uid)
            .set({
              'location': {
                'lat': position.latitude,
                'lng': position.longitude,
                'timestamp': FieldValue.serverTimestamp(),
              },
            }, SetOptions(merge: true));
      } catch (e) {
        print('Failed to update location: $e');
      }
    });
  }

  Future<void> _analyzeQuizResults() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final scoresSnap =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .collection('scores')
              .orderBy('timestamp', descending: true)
              .get();

      final now = DateTime.now();
      remembered = forgotten = totalAttempts = 0;

      for (var doc in scoresSnap.docs) {
        final ts = doc['timestamp'].toDate();
        final inWindow =
            _selectedWindow == '7 days'
                ? now.difference(ts).inDays < 7
                : _selectedWindow == '30 days'
                ? now.difference(ts).inDays < 30
                : true;
        if (inWindow) {
          totalAttempts++;
          doc['score'] > 0 ? remembered++ : forgotten++;
        }
      }

      rememberedPercent =
          totalAttempts > 0 ? (remembered / totalAttempts) * 100 : 0;
      forgottenPercent =
          totalAttempts > 0 ? (forgotten / totalAttempts) * 100 : 0;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to analyze quiz results.';
      });
    }
  }

  Future<void> _fetchTodayRoutines() async {
    if (user == null) return;
    final routines =
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user!.uid)
            .collection('routines')
            .orderBy('createdAt', descending: true)
            .get();

    final today = DateFormat('EEE').format(DateTime.now());
    final filtered =
        routines.docs.where((doc) {
          final days = List.from(doc['days'] ?? []);
          return days.contains(today);
        }).toList();

    setState(() {
      _todayRoutines = filtered;
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid ?? 'Unknown';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        backgroundColor: royalBlue,
        elevation: 0,
        title: const Text(
          'RemMe Care',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(royalBlue),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with greeting and profile
                  _buildHeader(),
                  
                  // Stats Cards
                  _buildStatsSection(),
                  
                  // Today's Routines
                  _buildTodaysRoutines(),
                  
                  // Features Grid
                  _buildFeaturesGrid(context),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: royalBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: quicksand, width: 2),
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Patient ID: ${user?.uid ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.content_copy, color: Colors.white, size: 18),
                      onPressed: () {
                        if (user?.uid != null) {
                          Clipboard.setData(ClipboardData(text: user!.uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Patient ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy Patient ID',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Memory Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkGrey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Remembered',
                '$remembered',
                '${rememberedPercent.toStringAsFixed(0)}%',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Forgotten',
                '$forgotten',
                '${forgottenPercent.toStringAsFixed(0)}%',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Period',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkGrey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWindow,
                      icon: const Icon(Icons.arrow_drop_down, color: royalBlue),
                      elevation: 16,
                      style: const TextStyle(
                        color: royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (w) {
                        if (w != null) {
                          setState(() => _selectedWindow = w);
                          _analyzeQuizResults();
                        }
                      },
                      items: _timeWindows.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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

  Widget _buildStatCard(String title, String value, String percentage, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysRoutines() {
    if (_todayRoutines.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Routines",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: royalBlue,
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [royalBlue, royalBlue.withOpacity(0.8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_todayRoutines.length} Scheduled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._todayRoutines.take(2).map((routine) => _buildRoutineItem(routine)).toList(),
                if (_todayRoutines.length > 2) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '+${_todayRoutines.length - 2} more',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoutineItem(DocumentSnapshot routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: quicksand,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine['title'] ?? 'Untitled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (routine['time'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    routine['time'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCards() => Column(
    children:
        _todayRoutines.map((routine) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.9,
              ), // Slightly translucent for glassy effect
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (routine['time'] != null)
                  Text(
                    '🕒 Time: ${routine['time']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                if (routine['repeat'] != null)
                  Text(
                    '🔁 Repeat: ${routine['repeat']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                if (routine['notes'] != null)
                  Text(
                    '📝 Notes: ${routine['notes']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
              ],
            ),
          );
        }).toList(),
  );

  Widget _buildFeaturesGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildFeatureItem(
                context,
                Icons.photo_album,
                'Memories',
                royalBlue,
                '/patient/memories',
              ),
              _buildFeatureItem(
                context,
                Icons.quiz,
                'Memory Quiz',
                quicksand,
                '/patient/quiz',
              ),
              _buildFeatureItem(
                context,
                Icons.schedule,
                'My Routines',
                Colors.purple,
                '/patient/routines',
              ),
              _buildFeatureItem(
                context,
                Icons.chat_bubble_outline,
                'Chatbot',
                Colors.green,
                '/patient/chatbot',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    String routeName,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, routeName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, routeName),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: darkGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
  }
}

class DashboardFeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashboardFeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  State<DashboardFeatureCard> createState() => _DashboardFeatureCardState();
}

class _DashboardFeatureCardState extends State<DashboardFeatureCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Glassy effect
            borderRadius: BorderRadius.circular(12),
            border:
                _hovering
                    ? Border.all(color: Colors.black54, width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 40, color: Colors.black),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientAccessPage extends StatefulWidget {
  const PatientAccessPage({super.key});

  @override
  State<PatientAccessPage> createState() => _PatientAccessPageState();
}

class _PatientAccessPageState extends State<PatientAccessPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _accessPatientFeatures() async {
    final code = _codeController.text;
    final patientSnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where('code', isEqualTo: code)
            .get();

    if (patientSnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Access granted!')));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PatientFeaturesPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Patient Features')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Patient Code',
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter the patient code'
                          : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _accessPatientFeatures,
              child: const Text('Access'),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientFeaturesPage extends StatefulWidget {
  const PatientFeaturesPage({super.key});

  @override
  State<PatientFeaturesPage> createState() => _PatientFeaturesPageState();
}

class _PatientFeaturesPageState extends State<PatientFeaturesPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recordedText = '';
  List<Map<String, dynamic>> _memories = [];
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .collection('memories')
              .orderBy('dateTime', descending: true)
              .get();
      setState(() {
        _memories =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'imageUrl': data['imageUrl'],
                'text': data['text'],
                'dateTime': data['dateTime'].toDate(),
              };
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load memories. Please check your connection.';
      });
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('memories')
          .child(user!.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to upload image. Please try again.';
      });
      return null;
    }
  }

  Future<void> _saveMemory() async {
    if (_image != null && _recordedText.isNotEmpty && user != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final now = DateTime.now();
      final imageUrl = await _uploadImage(_image!);
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user!.uid)
            .collection('memories')
            .add({
              'imageUrl': imageUrl,
              'text': _recordedText,
              'dateTime': now,
            });
        setState(() {
          _image = null;
          _recordedText = '';
          _isLoading = false;
        });
        _loadMemories();
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save memory. Please try again.';
        });
      }
    }
  }

  Future<void> _deleteMemory(String id, String imageUrl) async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .collection('memories')
          .doc(id)
          .delete();
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
      setState(() {
        _isLoading = false;
      });
      _loadMemories();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete memory. Please try again.';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required!')),
      );
      return;
    }
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _recordedText = val.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _showMemoryDetails(Map<String, dynamic> memory, int index) {
    final formatted = DateFormat(
      'yyyy-MM-dd – kk:mm',
    ).format(memory['dateTime']);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Memory Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  memory['imageUrl'],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                Text(memory['text']),
                const SizedBox(height: 10),
                Text('Saved on: $formatted'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _deleteMemory(memory['id'], memory['imageUrl']);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        title: const Text(
          'Memory Keeper',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: royalBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Memory Capture Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Image Preview
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: swanWing,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: royalBlue.withOpacity(0.2)),
                          ),
                          child: _image == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 50, color: royalBlue.withOpacity(0.5)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add a photo to remember',
                                      style: TextStyle(
                                        color: royalBlue.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_image!.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        
                        // Recorded Text
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: royalBlue.withOpacity(0.1)),
                          ),
                          child: Text(
                            _recordedText.isEmpty
                                ? 'Tap the mic to record your memory...'
                                : _recordedText,
                            style: TextStyle(
                              color: _recordedText.isEmpty 
                                  ? Colors.grey[500] 
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                            _buildActionButton(
                              icon: _isListening ? Icons.mic_off : Icons.mic,
                              label: _isListening ? 'Stop' : 'Record',
                              onPressed: _isListening ? _stopListening : _startListening,
                              isActive: _isListening,
                            ),
                            _buildActionButton(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                            _buildActionButton(
                              icon: Icons.save,
                              label: 'Save',
                              onPressed: _saveMemory,
                              isDisabled: _image == null || _recordedText.isEmpty,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Memories Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Memories',
                        style: TextStyle(
                          color: royalBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MemoryQuizGamePage(),
                          ),
                        ),
                        icon: const Icon(Icons.games, size: 18),
                        label: const Text('Play Quiz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: quicksand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Memories Grid
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_memories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No memories yet\nStart by adding your first memory!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _memories.length,
                    itemBuilder: (context, index) {
                      final memory = _memories[index];
                      return _buildMemoryCard(memory, index);
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled 
                ? Colors.grey[200] 
                : (isActive ? quicksand : royalBlue.withOpacity(0.05)),
            border: Border.all(
              color: isActive ? quicksand : royalBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isDisabled 
                  ? Colors.grey[400] 
                  : (isActive ? Colors.white : royalBlue),
              size: 22,
            ),
            onPressed: isDisabled ? null : onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDisabled ? Colors.grey[400] : royalBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory, int index) {
    return GestureDetector(
      onLongPress: () => _showMemoryDetails(memory, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  memory['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: swanWing,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: royalBlue,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: swanWing,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Text and Date
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory['text'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(memory['dateTime']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryQuizGamePage extends StatefulWidget {
  const MemoryQuizGamePage({super.key});

  @override
  State<MemoryQuizGamePage> createState() => _MemoryQuizGamePageState();
}

class _MemoryQuizGamePageState extends State<MemoryQuizGamePage>
    with SingleTickerProviderStateMixin {
  // Color constants
  static const Color _primaryColor = Color(0xFF1A237E); // Royal Blue
  static const Color _accentColor = Color(0xFFF4A460);   // Quicksand
  static const Color _backgroundColor = Color(0xFFF5F5F5); // Swan Wing
  static const Color _textColor = Color(0xFF424242);      // Dark Grey
  static const Color _cardColor = Colors.white;
  static const Color _successColor = Color(0xFF4CAF50);   // Green for success
  static const Color _errorColor = Color(0xFFE53935);      // Red for errors
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _memories = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animController;
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadMemoriesAndScore();
  }

  @override
  void didUpdateWidget(covariant MemoryQuizGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generateOptions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoriesAndScore() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .collection('memories')
              .get();
      _memories =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'imageUrl': data['imageUrl'],
              'text': data['text'],
              'dateTime': data['dateTime'].toDate(),
            };
          }).toList();
      final scoreDoc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .get();
      _score = scoreDoc.data()?['cutePoints'] ?? 0;
      _memories.shuffle(Random());
      _generateOptions(); // Generate options for the first question
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load memories/game.';
      });
    }
  }

  void _generateOptions() {
    if (_memories.isEmpty) {
      _options = [];
      return;
    }
    final correct = _memories[_currentIndex]['text'] as String;
    final otherMemories =
        _memories
            .map((m) => m['text'] as String)
            .where((t) => t != correct)
            .toList();
    otherMemories.shuffle(Random());
    // Ensure at least the correct answer is included, up to 4 options
    _options = [correct, ...otherMemories.take(3)].toList();
    _options.shuffle(Random());
  }

  void _checkAnswer(String selected) async {
    final correct =
        selected.trim().toLowerCase() ==
        _memories[_currentIndex]['text'].trim().toLowerCase();
    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });
    _animController.forward(from: 0);
    
    // Update score and record attempt in Firestore
    final scoreUpdate = correct ? 10 : 0;
    if (correct) {
      _score += 10;
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .set({'cutePoints': _score}, SetOptions(merge: true));
    }
    
    // Record the attempt (both correct and incorrect)
    await FirebaseFirestore.instance
        .collection('patients')
        .doc(user!.uid)
        .collection('scores')
        .add({
          'score': scoreUpdate,
          'timestamp': DateTime.now(),
          'memoryId': _memories[_currentIndex]['id'],
          'correct': correct,
        });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showResult = false;
        if (_currentIndex < _memories.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
          _memories.shuffle(Random());
        }
        _generateOptions();
      });
    });
  }

  Widget _buildCuteAnimation() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.7, end: 1.1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _isCorrect ? _successColor.withOpacity(0.1) : _errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isCorrect ? _successColor.withOpacity(0.3) : _errorColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCorrect ? Icons.check_circle : Icons.error_outline,
              color: _isCorrect ? _successColor : _errorColor,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              _isCorrect ? 'Correct! +10 Points' : 'Incorrect! Try Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _isCorrect ? _successColor : _errorColor,
              ),
            ),
            if (_isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Keep up the good work!',
                style: TextStyle(
                  fontSize: 14,
                  color: _textColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadScoreHistory() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user!.uid)
            .collection('scores')
            .orderBy('timestamp', descending: true)
            .get();
    return snapshot.docs
        .map(
          (doc) => {
            'score': doc['score'],
            'timestamp': doc['timestamp'].toDate(),
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Memory Quiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : _memories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: _primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No memories to quiz yet!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some memories first to start the quiz',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Score Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Score',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_score',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: _accentColor,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Quiz Card
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              // Image Card
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: _cardColor,
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
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        _memories[_currentIndex]['imageUrl'],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 200,
                                          color: _backgroundColor,
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'What memory is this?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: _textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Options
                              if (!_showResult)
                                ..._options.map(
                                  (opt) => _buildOptionButton(opt),
                                ),
                              
                              // Result Animation
                              if (_showResult) _buildCuteAnimation(),
                              
                              // Error Message
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: _errorColor, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: _errorColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 20),
                              
                              // Score History
                              _buildScoreHistorySection(),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildOptionButton(String option) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _checkAnswer(option),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _backgroundColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildScoreHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadScoreHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                );
              }
              
              final scores = snapshot.data!;
              if (scores.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No quiz history yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: scores.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: _backgroundColor.withOpacity(0.8),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, i) {
                  final s = scores[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Earned ${s['score']} points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, y • hh:mm a').format(s['timestamp']),
                      style: TextStyle(
                        fontSize: 12,
                        color: _textColor.withOpacity(0.6),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class GuardianPatientProgressPage extends StatefulWidget {
  const GuardianPatientProgressPage({super.key});

  @override
  State<GuardianPatientProgressPage> createState() =>
      _GuardianPatientProgressPageState();
}

class _GuardianPatientProgressPageState
    extends State<GuardianPatientProgressPage> {
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _scoreHistory = [];
  int _cutePoints = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('patients').get();
      _patients =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'name': data['name'],
              'cutePoints': data['cutePoints'] ?? 0,
            };
          }).toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load patients.';
      });
    }
  }

  Future<void> _loadPatientProgress(Map<String, dynamic> patient) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedPatient = patient;
    });
    try {
      final scoresSnap =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patient['uid'])
              .collection('scores')
              .orderBy('timestamp', descending: true)
              .get();
      _scoreHistory =
          scoresSnap.docs
              .map(
                (doc) => {
                  'score': doc['score'],
                  'timestamp': doc['timestamp'].toDate(),
                },
              )
              .toList();
      final doc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patient['uid'])
              .get();
      _cutePoints = doc.data()?['cutePoints'] ?? 0;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load progress.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Progress')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    DropdownButton<Map<String, dynamic>>(
                      value: _selectedPatient,
                      hint: const Text('Select Patient'),
                      items:
                          _patients
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p['name'] ?? 'Unknown'),
                                ),
                              )
                              .toList(),
                      onChanged: (p) {
                        if (p != null) _loadPatientProgress(p);
                      },
                    ),
                    if (_selectedPatient != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Cute Points: $_cutePoints',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Quiz History:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child:
                            _scoreHistory.isEmpty
                                ? const Text('No quiz history yet.')
                                : ListView.builder(
                                  itemCount: _scoreHistory.length,
                                  itemBuilder: (context, i) {
                                    final s = _scoreHistory[i];
                                    return ListTile(
                                      leading: Icon(
                                        Icons.star,
                                        color: Colors.pink,
                                      ),
                                      title: Text(
                                        'Cute Points: +${s['score']}',
                                      ),
                                      subtitle: Text(
                                        DateFormat(
                                          'yyyy-MM-dd – kk:mm',
                                        ).format(s['timestamp']),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

class Routine {
  final String id;
  final String title;
  final DateTime dateTime;
  Routine({required this.id, required this.title, required this.dateTime});
}

Future<void> addRoutineForPatient(
  String patientUid,
  String title,
  DateTime dateTime,
) async {
  await FirebaseFirestore.instance
      .collection('patients')
      .doc(patientUid)
      .collection('routines')
      .add({'title': title, 'dateTime': dateTime});
}

Future<List<Routine>> getRoutinesForPatient(String patientUid) async {
  final snap =
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientUid)
          .collection('routines')
          .orderBy('dateTime')
          .get();
  return snap.docs
      .map(
        (doc) => Routine(
          id: doc.id,
          title: doc['title'],
          dateTime: doc['dateTime'].toDate(),
        ),
      )
      .toList();
}

class GuardianCreateRoutinePage extends StatefulWidget {
  final String patientUid;
  const GuardianCreateRoutinePage({super.key, required this.patientUid});

  @override
  State<GuardianCreateRoutinePage> createState() =>
      _GuardianCreateRoutinePageState();
}

class _GuardianCreateRoutinePageState extends State<GuardianCreateRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await addRoutineForPatient(
        widget.patientUid,
        _titleController.text,
        _selectedDateTime!,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add routine.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Routine')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Routine Title',
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            _selectedDateTime == null
                                ? 'No date/time chosen'
                                : _selectedDateTime.toString(),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _pickDateTime,
                            child: const Text('Pick Date & Time'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Create Routine'),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class PatientRoutinePage extends StatefulWidget {
  const PatientRoutinePage({super.key});

  @override
  State<PatientRoutinePage> createState() => _PatientRoutinePageState();
}

class _PatientRoutinePageState extends State<PatientRoutinePage> {
  final user = FirebaseAuth.instance.currentUser;
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _errorMessage;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadRoutines();
  }

  Future<void> _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notificationsPlugin!.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> _scheduleNotification(Routine routine) async {
    if (_notificationsPlugin == null) return;
    await _notificationsPlugin!.zonedSchedule(
      routine.id.hashCode,
      'Routine Reminder',
      routine.title,
      tz.TZDateTime.from(routine.dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('routine_channel', 'Routines'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> _cancelNotification(Routine routine) async {
    if (_notificationsPlugin == null) return;
    await _notificationsPlugin!.cancel(routine.id.hashCode);
  }

  Future<void> _loadRoutines() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _routines = await getRoutinesForPatient(user!.uid);
      for (final r in _routines) {
        await _cancelNotification(r);
        await _scheduleNotification(r);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load routines.';
      });
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .collection('routines')
          .doc(routine.id)
          .delete();
      await _cancelNotification(routine);
      setState(() {
        _isLoading = false;
      });
      _loadRoutines();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete routine.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Routines')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _routines.length,
                itemBuilder: (context, i) {
                  final r = _routines[i];
                  return ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd – kk:mm').format(r.dateTime),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRoutine(r),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class GuardianRoutineListPage extends StatefulWidget {
  final String patientUid;
  const GuardianRoutineListPage({super.key, required this.patientUid});

  @override
  State<GuardianRoutineListPage> createState() =>
      _GuardianRoutineListPageState();
}

class _GuardianRoutineListPageState extends State<GuardianRoutineListPage> {
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _routines = await getRoutinesForPatient(widget.patientUid);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load routines.';
      });
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('routines')
          .doc(routine.id)
          .delete();
      setState(() {
        _isLoading = false;
      });
      _loadRoutines();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete routine.';
      });
    }
  }

  void _editRoutine(Routine routine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => GuardianEditRoutinePage(
              patientUid: widget.patientUid,
              routine: routine,
            ),
      ),
    );
    if (result == true) _loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routines')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _routines.length,
                itemBuilder: (context, i) {
                  final r = _routines[i];
                  return ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd – kk:mm').format(r.dateTime),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRoutine(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRoutine(r),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class GuardianEditRoutinePage extends StatefulWidget {
  final String patientUid;
  final Routine routine;
  const GuardianEditRoutinePage({
    super.key,
    required this.patientUid,
    required this.routine,
  });

  @override
  State<GuardianEditRoutinePage> createState() =>
      _GuardianEditRoutinePageState();
}

class _GuardianEditRoutinePageState extends State<GuardianEditRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine.title);
    _selectedDateTime = widget.routine.dateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('routines')
          .doc(widget.routine.id)
          .update({
            'title': _titleController.text,
            'dateTime': _selectedDateTime,
          });
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update routine.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Routine')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Routine Title',
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            _selectedDateTime == null
                                ? 'No date/time chosen'
                                : _selectedDateTime.toString(),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _pickDateTime,
                            child: const Text('Pick Date & Time'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Update Routine'),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

final defaultGeminiApiKey = 'AIzaSyD2jKT9WzrhlJ6UsfuzByaQMbO2XKIPFys';
final defaultGeminiModel = 'gemini-2.5-pro-exp-03-25';
final groqApiKey = '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';
final groqModel = 'llama-3.3-70b-versatile';

class MedicalAIChatBotPage extends StatefulWidget {
  const MedicalAIChatBotPage({super.key});

  @override
  State<MedicalAIChatBotPage> createState() => _MedicalAIChatBotPageState();
}


class _MedicalAIChatBotPageState extends State<MedicalAIChatBotPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  final String _flaskApiUrl = 'http://192.168.1.6:5001/chat';
  late AnimationController _animationController;
  late Animation<double> _jumpAnimation1;
  late Animation<double> _jumpAnimation2;
  late Animation<double> _jumpAnimation3;
  late Animation<double> _morphAnimation;
  
  // For hover effect on send button
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..repeat();
    
    // Add a small delay to ensure the UI is built before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    _jumpAnimation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _jumpAnimation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.36, 1.0, curve: Curves.easeInOut),
      ),
    );

    _jumpAnimation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _morphAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _messages.add({'role': 'user', 'content': input});
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });
    
    // Scroll to bottom when new message is added
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    try {
      final response = await http
          .post(
            Uri.parse(_flaskApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': input}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final answer = jsonResponse['reply'] ?? 'No response.';
        setState(() {
          _messages.add({'role': 'ai', 'content': answer});
          _isLoading = false;
        });
      } else {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              jsonResponse['error'] ?? 'API Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get response: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: royalBlue,
        title: const Text(
          'Medical Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 60,
                            color: royalBlue.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ask me anything about\nyour health',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final isUser = m['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: royalBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? royalBlue
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                          isUser ? 16 : 4),
                                      bottomRight: Radius.circular(
                                          isUser ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    m['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isUser
                                          ? Colors.white
                                          : Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              if (isUser) const SizedBox(width: 8),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.red[50],
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isLoading)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCube(_jumpAnimation1, _morphAnimation),
                    const SizedBox(width: 8),
                    _buildCube(_jumpAnimation2, _morphAnimation),
                    const SizedBox(width: 8),
                    _buildCube(_jumpAnimation3, _morphAnimation),
                    const SizedBox(width: 12),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Type your question here...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? royalBlue.withOpacity(0.9)
                          : royalBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: royalBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
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

  Widget _buildCube(
    Animation<double> jumpAnimation,
    Animation<double> morphAnimation,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final jumpValue = jumpAnimation.value;
        final morphValue = morphAnimation.value;
        double jumpOffset = 0;
        double scaleY = 1.0;
        double scaleX = 1.0;

        // Jump animation logic
        if (jumpValue <= 0.3) {
          jumpOffset = 0;
        } else if (jumpValue <= 0.5) {
          jumpOffset = -8 * (jumpValue - 0.3) / 0.2;
        } else if (jumpValue <= 0.75) {
          jumpOffset = -8 + 8 * (jumpValue - 0.5) / 0.25;
        } else {
          jumpOffset = 0;
        }

        // Morph animation logic
        if (morphValue <= 0.1) {
          scaleY = 1;
        } else if (morphValue <= 0.25) {
          scaleY = 0.6 + (1 - 0.6) * (morphValue - 0.2) / 0.05;
          scaleX = 1.3 - (1.3 - 1) * (morphValue - 0.2) / 0.05;
        } else if (morphValue <= 0.3) {
          scaleY = 1.15 - (1.15 - 1) * (morphValue - 0.25) / 0.05;
          scaleX = 0.9 + (1 - 0.9) * (morphValue - 0.25) / 0.05;
        } else if (morphValue <= 0.4) {
          scaleY = 1;
        } else if (morphValue <= 0.75) {
          scaleY = 0.8 + (1 - 0.8) * (morphValue - 0.7) / 0.05;
          scaleX = 1.2 - (1.2 - 1) * (morphValue - 0.7) / 0.05;
        } else {
          scaleY = 1;
          scaleX = 1;
        }

        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(bottom: 2),
          child: Transform(
            transform: Matrix4.identity()
              ..translate(0.0, jumpOffset)
              ..scale(scaleX, scaleY),
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: royalBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
