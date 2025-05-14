import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Color palette
const Color royalBlue = Color(0xFF1A237E);
const Color quicksand = Color(0xFFF4A460);
const Color swanWing = Color(0xFFF5F5F5);

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _patientCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // UI State
  bool _isHovered = false;

  @override
  void dispose() {
    _patientCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkPatientToGuardian(String patientUid) async {
    final guardianUid = FirebaseAuth.instance.currentUser!.uid;

    // Step 1: Validate that patient exists
    final patientDoc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientUid)
        .get();

    if (!patientDoc.exists) {
      throw Exception('Patient with this code does not exist.');
    }

    final patientData = patientDoc.data()!;
    final patientName = patientData['name'] ?? 'Unnamed';
    final patientPhotoUrl = patientData['photoUrl'] ?? '';

    // Step 2: Link patient under guardian/linkedPatients
    final batch = FirebaseFirestore.instance.batch();
    
    // Add to guardian's linked patients
    final guardianRef = FirebaseFirestore.instance
        .collection('guardians')
        .doc(guardianUid)
        .collection('linkedPatients')
        .doc(patientUid);
    
    batch.set(guardianRef, {
      'name': patientName,
      'photoUrl': patientPhotoUrl,
      'linkedAt': FieldValue.serverTimestamp(),
    });
    
    // Add guardian to patient's guardians list
    final patientRef = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientUid)
        .collection('guardians')
        .doc(guardianUid);
    
    final user = FirebaseAuth.instance.currentUser!;
    batch.set(patientRef, {
      'name': user.displayName ?? 'Guardian',
      'photoUrl': user.photoURL ?? '',
      'email': user.email ?? '',
      'linkedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Future<void> _savePatientCode() async {
    final patientCode = _patientCodeController.text.trim();
    if (patientCode.isEmpty) {
      setState(() => _errorMessage = "Please enter the patient's UID");
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Please sign in to continue");
      
      // Check if trying to link to self
      if (currentUser.uid == patientCode) {
        throw Exception("You cannot link to your own account");
      }

      await _linkPatientToGuardian(patientCode);

      // Return success to previous screen
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      
      // Log the error for debugging
      debugPrint('Error linking patient: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Patient',
          style: TextStyle(
            color: royalBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: royalBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Link Patient Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the patient\'s unique ID to connect with their account',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              
              // UID Input Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient UID',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _patientCodeController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter patient UID',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.person_search, color: royalBlue),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Link Button
              MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isHovered
                          ? [royalBlue.withOpacity(0.9), royalBlue.withOpacity(0.8)]
                          : [royalBlue, royalBlue.withOpacity(0.9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: royalBlue.withOpacity(0.3),
                        blurRadius: _isHovered ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePatientCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Link Patient Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'You can find the patient\'s UID in their profile settings or by asking them to share it with you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
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
