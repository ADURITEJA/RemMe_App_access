import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _patientCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Define colors from the provided palette
  final Color backgroundColorSolid = const Color(0xFFF9EFE5); // Brand Beige
  final Color buttonColor = const Color(0xFF000000); // Black for buttons
  final Color accentColor = const Color(0xFFFF6F61); // Coral for alerts
  final Color textColorPrimary = const Color(0xFF000000); // Brand Black
  final Color textColorSecondary = const Color(
    0xFF7F8790,
  ); // Base Muted Gray-Blue
  final Color cardBackgroundColor = const Color(0xFFF8F8F8); // Base Light Gray
  final Color glassyOverlayColor = const Color(
    0xFF000000,
  ); // Black for glassy effect

  @override
  void dispose() {
    _patientCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkPatientToGuardian(String patientUid) async {
    final guardianUid = FirebaseAuth.instance.currentUser!.uid;

    // Step 1: Validate that patient exists
    final patientDoc =
        await FirebaseFirestore.instance
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
    await FirebaseFirestore.instance
        .collection('guardians')
        .doc(guardianUid)
        .collection('linkedPatients')
        .doc(patientUid)
        .set({'name': patientName, 'photoUrl': patientPhotoUrl});
  }

  Future<void> _savePatientCode() async {
    final patientCode = _patientCodeController.text.trim();
    if (patientCode.isEmpty) {
      setState(() => _errorMessage = "Please enter the patient's code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("No logged-in user.");

      await _linkPatientToGuardian(patientCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Patient linked successfully!'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      Navigator.pop(context); // Return to dashboard
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Patient',
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
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: glassyOverlayColor.withOpacity(0.1)),
          ),
        ),
      ),
      body: Container(
        color: backgroundColorSolid,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Input field with black glassy effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor.withOpacity(0.9),
                        border: Border.all(
                          color: glassyOverlayColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Link Patient by UID',
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
                            controller: _patientCodeController,
                            style: const TextStyle(
                              color: Color(0xFF000000),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Enter Patient UID',
                              labelStyle: const TextStyle(
                                color: Color(0xFF7F8790),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Color(0xFF7F8790),
                              ),
                              filled: true,
                              fillColor: Color(0xFF7F8790).withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: glassyOverlayColor.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: glassyOverlayColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF7F8790),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: glassyOverlayColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _savePatientCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: backgroundColorSolid,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      glassyOverlayColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFF9EFE5),
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Link Patient',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
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
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: accentColor, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
