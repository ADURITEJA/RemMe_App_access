import 'package:flutter/material.dart';

class GuardianPatientProgressPage extends StatelessWidget {
  final String patientUid;
  final String patientName;

  const GuardianPatientProgressPage({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$patientName's Progress"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Progress for $patientName (UID: $patientUid)",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Patient quiz progress and cute point data will be shown here.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}