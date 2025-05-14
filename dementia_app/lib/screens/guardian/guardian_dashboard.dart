import 'package:flutter/material.dart';

class GuardianDashboard extends StatelessWidget {
  const GuardianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard'),
      ),
      body: const Center(
        child: Text('Guardian Dashboard'),
      ),
    );
  }
}
