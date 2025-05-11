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

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

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

      Navigator.pop(context); // Close loading dialog

      final role = profileData['role'];
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'guardian' ? '/guardian_dashboard' : '/patient_dashboard',
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Confirm Submission",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            content: const Text(
              "Are you sure you want to submit your profile?",
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
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
      appBar: AppBar(
        title: const Text("Confirm Your Profile"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[900]!, Colors.deepPurple[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple[900]!, Colors.deepPurple[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles (similar to RoleSelectionPage)
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[700]!, Colors.deepPurple[300]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[700]!, Colors.deepPurple[300]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(photoUrl),
                      onBackgroundImageError:
                          (error, stackTrace) => const Icon(Icons.error),
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _summaryRow("Name", name),
                          _summaryRow("Phone", phone),
                          _summaryRow("Gender", gender),
                          _summaryRow("Age", age.toString()),
                          _summaryRow("Role", profileData['role']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => _showConfirmationDialog(context),
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Submit & Continue"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
