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

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isGuardianPressed = false;
  bool _isPatientPressed = false;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose whether you are a Guardian or a Patient',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Guardian Button
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          _isGuardianPressed = true;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isGuardianPressed = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GuardianLoginPage(),
                          ),
                        );
                      },
                      onTapCancel: () {
                        setState(() {
                          _isGuardianPressed = false;
                        });
                      },
                      child: _buildRoleButton(
                        label: 'Guardian',
                        isPressed: _isGuardianPressed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Patient Button
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          _isPatientPressed = true;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isPatientPressed = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientLoginPage(),
                          ),
                        );
                      },
                      onTapCancel: () {
                        setState(() {
                          _isPatientPressed = false;
                        });
                      },
                      child: _buildRoleButton(
                        label: 'Patient',
                        isPressed: _isPatientPressed,
                      ),
                    ),
                  ],
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

  Widget _buildRoleButton({required String label, required bool isPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 60,
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF6B5B95),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
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

class _GuardianLoginPageState extends State<GuardianLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginGuardian() async {
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

        final guardianUid = userCredential.user!.uid;

        // Get FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();

        // Save FCM token to Firestore
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('guardians')
              .doc(guardianUid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian logged in successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GuardianDashboardPage(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      setState(() {
        _isLoginPressed = false;
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
                          'Guardian Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter your email'
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
                                      ? 'Please enter your password'
                                      : null,
                        ),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const GuardianRegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Create Account',
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

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoginPressed ? null : _loginGuardian,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B5B95),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Login',
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

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

        // Get FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();

        // Save FCM token to Firestore
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientUid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient logged in successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      setState(() {
        _isLoginPressed = false;
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
                          'Patient Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          obscureText: false,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter your email'
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
                                      ? 'Please enter your password'
                                      : null,
                        ),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const PatientRegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Sign up',
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
    required bool obscureText,
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

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoginPressed ? null : _loginPatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B5B95),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Login',
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E6), // Pale pink background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUidCard(uid),
                    const SizedBox(height: 20),
                    _buildMemoryStats(),
                    const SizedBox(height: 20),
                    _buildRoutineSummaryBanner(),
                    const SizedBox(height: 10),
                    _buildRoutineCards(),
                    const SizedBox(height: 20),
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureButtons(context),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildUidCard(String uid) => Container(
    padding: const EdgeInsets.all(12),
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
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Your UID: $uid',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.black),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: uid));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('UID copied to clipboard!')),
            );
          },
        ),
      ],
    ),
  );

  Widget _buildMemoryStats() => Container(
    padding: const EdgeInsets.all(16),
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
        const Text(
          '🧠 Memory Recall Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: _selectedWindow,
          items:
              _timeWindows.map((w) {
                return DropdownMenuItem(value: w, child: Text(w));
              }).toList(),
          onChanged: (w) {
            if (w != null) {
              setState(() => _selectedWindow = w);
              _analyzeQuizResults();
            }
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Remembered: $remembered (${rememberedPercent.toStringAsFixed(1)}%)',
          style: const TextStyle(color: Colors.black87),
        ),
        Text(
          'Forgotten: $forgotten (${forgottenPercent.toStringAsFixed(1)}%)',
          style: const TextStyle(color: Colors.black87),
        ),
        Text(
          'Total Attempts: $totalAttempts',
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    ),
  );

  Widget _buildRoutineSummaryBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
    child: Text(
      '📅 ${_todayRoutines.length} routine(s) scheduled for today!',
      style: const TextStyle(fontSize: 16, color: Colors.black),
    ),
  );

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

  Widget _buildFeatureButtons(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 1.2,
    children: [
      DashboardFeatureCard(
        icon: Icons.photo_album,
        label: 'Memories',
        onTap: () => Navigator.pushNamed(context, '/patient/memories'),
      ),
      DashboardFeatureCard(
        icon: Icons.quiz,
        label: 'Memory Quiz',
        onTap: () => Navigator.pushNamed(context, '/patient/quiz'),
      ),
      DashboardFeatureCard(
        icon: Icons.schedule,
        label: 'My Routines',
        onTap: () => Navigator.pushNamed(context, '/patient/routines'),
      ),
      DashboardFeatureCard(
        icon: Icons.chat_bubble_outline,
        label: 'Medical Chatbot',
        onTap: () => Navigator.pushNamed(context, '/patient/chatbot'),
      ),
    ],
  );
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
      appBar: AppBar(title: const Text('Patient Features')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Colors.pink[100],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Press Microphone to Start',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            _image == null
                                ? const Icon(Icons.image, size: 60)
                                : Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _recordedText.isEmpty
                            ? 'Your recorded text will appear here...'
                            : _recordedText,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera),
                            onPressed: () => _pickImage(ImageSource.camera),
                            iconSize: 32,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                            ),
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                            iconSize: 32,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.photo_library),
                            onPressed: () => _pickImage(ImageSource.gallery),
                            iconSize: 32,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: _saveMemory,
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const Text(
                  'Memories',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemoryQuizGamePage(),
                        ),
                      ),
                  child: const Text('Play Memory Quiz Game'),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                if (!_isLoading)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: _memories.length,
                    itemBuilder: (context, index) {
                      final memory = _memories[index];
                      return GestureDetector(
                        onLongPress: () => _showMemoryDetails(memory, index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  memory['imageUrl'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  memory['text'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
}

class MemoryQuizGamePage extends StatefulWidget {
  const MemoryQuizGamePage({super.key});

  @override
  State<MemoryQuizGamePage> createState() => _MemoryQuizGamePageState();
}

class _MemoryQuizGamePageState extends State<MemoryQuizGamePage>
    with SingleTickerProviderStateMixin {
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
    if (correct) {
      _score += 10;
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .set({'cutePoints': _score}, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .collection('scores')
          .add({'score': 10, 'timestamp': DateTime.now()});
    }
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
      scale: Tween<double>(begin: 0.7, end: 1.2).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
      ),
      child:
          _isCorrect
              ? Column(
                children: [
                  Icon(Icons.emoji_emotions, color: Colors.pink, size: 80),
                  const Text(
                    'Yay! Cute points +10',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    color: Colors.blueGrey,
                    size: 80,
                  ),
                  const Text(
                    'Oops! Try again!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Quiz Game'),
        backgroundColor: Colors.pink[300],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[100]!, Colors.blue[100]!],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                )
                : _memories.isEmpty
                ? const Center(
                  child: Text(
                    'No memories to quiz yet!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cute Points: $_score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _memories[_currentIndex]['imageUrl'],
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 100,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'What memory is this?',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (!_showResult)
                                        ..._options.map(
                                          (opt) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: ElevatedButton(
                                              onPressed:
                                                  () => _checkAnswer(opt),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.pink[200],
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                minimumSize: const Size(
                                                  double.infinity,
                                                  50,
                                                ),
                                              ),
                                              child: Text(
                                                opt,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_showResult) _buildCuteAnimation(),
                                      if (_errorMessage != null)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Score History',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 200,
                                child:
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _loadScoreHistory(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData)
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.pink,
                                            ),
                                          );
                                        final scores = snapshot.data!;
                                        if (scores.isEmpty)
                                          return const Center(
                                            child: Text(
                                              'No quiz history yet.',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          );
                                        return ListView.builder(
                                          itemCount: scores.length,
                                          itemBuilder: (context, i) {
                                            final s = scores[i];
                                            return ListTile(
                                              leading: const Icon(
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
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
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

  final String _flaskApiUrl =
      'http://192.168.1.6:5001/chat'; // Adjust for your environment
  late AnimationController _animationController;
  late Animation<double> _jumpAnimation1;
  late Animation<double> _jumpAnimation2;
  late Animation<double> _jumpAnimation3;
  late Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1750,
      ), // Matches --uib-speed: 1.75s
    )..repeat();

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
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': input});
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Medical AI Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            Container(
              height: 45, // Matches --uib-size: 45px
              width: 45, // Matches --uib-size: 45px
              padding: const EdgeInsets.only(
                bottom: 20,
              ), // Matches padding-bottom: 20%
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCube(_jumpAnimation1, _morphAnimation),
                  _buildCube(_jumpAnimation2, _morphAnimation),
                  _buildCube(_jumpAnimation3, _morphAnimation),
                ],
              ),
            ),
          if (_isLoading)
            const LinearProgressIndicator(), // Keep existing indicator as fallback
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a medical question...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
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
          jumpOffset = -200 * (jumpValue - 0.3) / 0.2;
        } else if (jumpValue <= 0.75) {
          jumpOffset = -200 + 200 * (jumpValue - 0.5) / 0.25;
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
          width: 9, // calc(45px * 0.2)
          height: 9, // calc(45px * 0.2)
          margin: const EdgeInsets.only(bottom: 5), // Align to bottom
          child: Transform(
            transform:
                Matrix4.identity()
                  ..translate(0.0, jumpOffset)
                  ..scale(scaleX, scaleY),
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        );
      },
    );
  }
}
