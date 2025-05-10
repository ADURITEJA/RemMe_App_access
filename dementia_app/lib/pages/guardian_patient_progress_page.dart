import 'package:flutter/material.dart';

class GuardianPatientProgressPage extends StatelessWidget {
  const GuardianPatientProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Progress")),
      body: const Center(
        child: Text(
          "Patient quiz progress and cute point data will be shown here.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
