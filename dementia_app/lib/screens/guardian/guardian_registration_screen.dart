import 'package:flutter/material.dart';

class GuardianRegistrationScreen extends StatelessWidget {
  const GuardianRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Registration'),
      ),
      body: const Center(
        child: Text('Guardian Registration Form'),
      ),
    );
  }
}
