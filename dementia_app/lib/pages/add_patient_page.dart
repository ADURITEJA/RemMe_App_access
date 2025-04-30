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
        const SnackBar(content: Text('✅ Patient linked successfully!')),
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
      appBar: AppBar(title: const Text('Add Patient')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _patientCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Patient UID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePatientCode,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Patient'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
