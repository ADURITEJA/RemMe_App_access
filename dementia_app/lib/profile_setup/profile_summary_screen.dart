import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const ProfileSummaryScreen({super.key, required this.profileData});

  Future<void> _submitProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': profileData['name'],
        'phone': profileData['phone'],
        'gender': profileData['gender'],
        'age': profileData['age'],
        'photoUrl': profileData['photoUrl'] ?? '',
        'role': profileData['role'],
        'email': user.email,
        'uid': user.uid,
        'createdAt': Timestamp.now(),
      });

      final role = profileData['role'];
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'guardian' ? '/guardian_dashboard' : '/patient_dashboard',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    }
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Submission"),
            content: const Text(
              "Are you sure you want to submit your profile?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes, Submit"),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _submitProfile(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = profileData['name'];
    final phone = profileData['phone'];
    final gender = profileData['gender'];
    final age = profileData['age'];
    final photoUrl = profileData['photoUrl'];

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              CircleAvatar(radius: 60, backgroundImage: NetworkImage(photoUrl))
            else
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 40),
              ),
            const SizedBox(height: 20),
            _summaryRow("Name", name),
            _summaryRow("Phone", phone),
            _summaryRow("Gender", gender),
            _summaryRow("Age", age.toString()),
            _summaryRow("Role", profileData['role']),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _showConfirmationDialog(context),
              icon: const Icon(Icons.check_circle),
              label: const Text("Submit & Continue"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
