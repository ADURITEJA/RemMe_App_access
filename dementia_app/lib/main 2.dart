import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dementia_app/pages/add_patient_page.dart';
import 'package:dementia_app/pages/danger_zone_alerts_page.dart';
import 'package:dementia_app/pages/danger_zone_setup_page.dart';
import 'package:dementia_app/pages/guardian_dashboard_page.dart';
import 'package:dementia_app/pages/live_patient_tracking_page.dart';
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
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart'; // Import from the first main.dart
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Before Firebase');
  await Firebase.initializeApp();
  print('Before AlarmManager');
  await AndroidAlarmManager.initialize();
  print('Before runApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4B5EAA), // Deep blue
              Color(0xFFD2B8E3), // Light purple
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title and subtitle
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
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(height: 40),
                // Guardian Button with Hover Effect
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
                  child: _buildGradientButton(
                    label: 'Guardian',
                    isPressed: _isGuardianPressed,
                  ),
                ),
                const SizedBox(height: 20),
                // Patient Button with Hover Effect
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
                  child: _buildGradientButton(
                    label: 'Patient',
                    isPressed: _isPatientPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required bool isPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), // Animation duration
      width: 250, // Fixed width for consistency
      height: 60, // Increased height for better touch area
      transform:
          Matrix4.identity()
            ..scale(isPressed ? 0.95 : 1.0), // Scale down when pressed
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4B5EAA), // Dark blue
            Color(0xFFE3B8D2), // Pinkish-purple
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPressed ? 0.3 : 0.2),
            offset: const Offset(0, 4),
            blurRadius: isPressed ? 12 : 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

Widget _buildGradientButton({
  required BuildContext context,
  required String label,
  required VoidCallback onPressed,
}) {
  return Container(
    width: 250, // Fixed width for consistency
    height: 60, // Increased height for better touch area
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF4B5EAA), // Dark blue
          Color(0xFFE3B8D2), // Pinkish-purple
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        shadowColor: Colors.transparent, // Disable default shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginGuardian() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Login')),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loginGuardian,
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GuardianRegisterPage(),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
            ],
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
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4B5EAA), // Deep blue
              Color(0xFFD2B8E3), // Light purple
            ],
          ),
        ),
        child: SafeArea(
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
                    const SizedBox(height: 20),
                    _buildInputContainer(
                      label: 'EMAIL',
                      controller: _emailController,
                      obscureText: false,
                      isFocused: _isEmailFocused,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isEmailFocused = hasFocus;
                        });
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your email'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputContainer(
                      label: 'PASSWORD',
                      controller: _passwordController,
                      obscureText: true,
                      isFocused: _isPasswordFocused,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isPasswordFocused = hasFocus;
                        });
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientRegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildInputContainer({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required bool isFocused,
    required ValueChanged<bool> onFocusChange,
    required String? Function(String?) validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      width: 350,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: const Offset(10, 10),
            blurRadius: 0,
          ),
          if (isFocused)
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.4),
              offset: const Offset(0, 0),
              blurRadius: 20,
              spreadRadius: -10,
            ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      transform:
          Matrix4.identity()
            ..rotateX(isFocused ? 5 * 3.14159 / 180 : 10 * 3.14159 / 180)
            ..rotateY(isFocused ? 1 * 3.14159 / 180 : -10 * 3.14159 / 180)
            ..scale(isFocused ? 1.05 : 1.0),
      transformAlignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFFE9B50B),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 15),
              hintText: 'Enter your details',
              hintStyle: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: const TextStyle(fontSize: 18, color: Colors.black),
            validator: validator,
            onTap: () => onFocusChange(true),
            onFieldSubmitted: (_) => onFocusChange(false),
            onChanged: (_) => onFocusChange(true),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 350,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9B50B), Color(0xFFFFD700)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: const Offset(5, 5),
            blurRadius: 0,
          ),
          if (_isLoginPressed)
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(5, 5),
              blurRadius: 5,
              spreadRadius: 2,
            ),
        ],
      ),
      transform:
          Matrix4.identity()
            ..scale(_isLoginPressed ? 0.95 : 1.0) // Scale down when pressed
            ..translate(
              _isLoginPressed ? -5.0 : 0.0,
              _isLoginPressed ? -5.0 : 0.0,
            ),
      transformAlignment: Alignment.center,
      child: ElevatedButton(
        onPressed: _loginPatient,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerGuardian() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
        await FirebaseFirestore.instance
            .collection('guardians')
            .doc(userCredential.user!.uid)
            .set({
              'name': _nameController.text,
              'email': _emailController.text,
              'role': 'guardian',
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian registered successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Registration')),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your name'
                            : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerGuardian,
                child: const Text('Submit'),
              ),
            ],
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
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(userCredential.user!.uid)
            .set({
              'name': _nameController.text,
              'email': _emailController.text,
              'role': 'patient',
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your name'
                            : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerPatient,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final user = FirebaseAuth.instance.currentUser;
  Timer? _locationUpdateTimer;
  int remembered = 0;
  int forgotten = 0;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _timeWindows = ['7 days', '30 days', 'All time'];
  String _selectedWindow = '7 days';
  int totalAttempts = 0;
  double rememberedPercent = 0;
  double forgottenPercent = 0;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _analyzeQuizResults();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
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
      remembered = 0;
      forgotten = 0;
      totalAttempts = 0;

      for (var doc in scoresSnap.docs) {
        final ts = doc['timestamp'].toDate();
        bool inWindow =
            _selectedWindow == '7 days'
                ? now.difference(ts).inDays < 7
                : _selectedWindow == '30 days'
                ? now.difference(ts).inDays < 30
                : true;

        if (inWindow) {
          totalAttempts++;
          if (doc['score'] > 0) {
            remembered++;
          } else {
            forgotten++;
          }
        }
      }

      rememberedPercent =
          totalAttempts > 0 ? (remembered / totalAttempts) * 100 : 0;
      forgottenPercent =
          totalAttempts > 0 ? (forgotten / totalAttempts) * 100 : 0;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to analyze quiz results.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String patientUid = user?.uid ?? 'Unavailable';

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Dashboard')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your UID: $patientUid',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: patientUid),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('UID copied to clipboard!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Memory Recall Analysis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _selectedWindow,
                              items:
                                  _timeWindows.map((w) {
                                    return DropdownMenuItem(
                                      value: w,
                                      child: Text(w),
                                    );
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
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Forgotten: $forgotten (${forgottenPercent.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                            Text(
                              'Total Attempts: $totalAttempts',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        DashboardFeatureCard(
                          icon: Icons.photo_album,
                          label: 'Memories',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/patient/memories',
                              ),
                        ),
                        DashboardFeatureCard(
                          icon: Icons.quiz,
                          label: 'Memory Quiz Game',
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/patient/quiz'),
                        ),
                        DashboardFeatureCard(
                          icon: Icons.schedule,
                          label: 'My Routines',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/patient/routines',
                              ),
                        ),
                        DashboardFeatureCard(
                          icon: Icons.chat_bubble_outline,
                          label: 'Medical AI Chatbot',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/patient/chatbot',
                              ),
                        ),
                      ],
                    ),
                  ],
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                _hovering
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
      appBar: AppBar(
        title: const Text('Patient Progress'),
        backgroundColor: Colors.pink[300],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _selectedPatient != null
                    ? () => _loadPatientProgress(_selectedPatient!)
                    : _loadPatients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[100]!, Colors.blue[100]!],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Patient',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedPatient,
                            hint: const Text('Select a Patient'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.pink[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items:
                                _patients.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p['name'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (p) {
                              if (p != null) _loadPatientProgress(p);
                            },
                          ),
                          if (_patients.isEmpty && !_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No patients found.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_selectedPatient != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Progress for ${_selectedPatient!['name']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.pink,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cute Points: $_cutePoints',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.pink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Quiz History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 300,
                              child:
                                  _scoreHistory.isEmpty
                                      ? const Center(
                                        child: Text(
                                          'No quiz history yet.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                      : ListView.builder(
                                        itemCount: _scoreHistory.length,
                                        itemBuilder: (context, i) {
                                          final s = _scoreHistory[i];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  i % 2 == 0
                                                      ? Colors.pink[50]
                                                      : Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.star,
                                                color: Colors.pink,
                                              ),
                                              title: Text(
                                                'Cute Points: +${s['score']}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              subtitle: Text(
                                                DateFormat(
                                                  'yyyy-MM-dd – kk:mm',
                                                ).format(s['timestamp']),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              ),
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
final grokApiKey = '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';
final grokModel = 'llama-3.3-70b-versatile';

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
      'http://192.168.214.28:5001/chat'; // Adjust for your environment
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
