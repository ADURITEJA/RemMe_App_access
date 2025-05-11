import 'package:flutter/material.dart';

class GuardianRoutineListPage extends StatelessWidget {
  final String patientUid;

  const GuardianRoutineListPage({super.key, required this.patientUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Routines'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Text('Routines for Patient UID: $patientUid'),
        // Add routine list UI here
      ),
    );
  }
}
