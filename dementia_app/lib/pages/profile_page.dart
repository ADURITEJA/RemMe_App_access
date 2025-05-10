import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProfilePage({super.key, required this.profileData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  String gender = 'Not specified';
  String photoUrl = '';
  File? _newImage;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileData['name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profileData['phone'] ?? '',
    );
    _ageController = TextEditingController(
      text:
          widget.profileData['age'] != null
              ? widget.profileData['age'].toString()
              : '',
    );
    gender = widget.profileData['gender'] ?? 'Not specified';
    photoUrl = widget.profileData['photoUrl'] ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadPhoto(File imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/$uid.jpg',
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String? newPhotoUrl = photoUrl;
    if (_newImage != null) {
      final uploadedUrl = await _uploadPhoto(_newImage!);
      if (uploadedUrl != null) {
        newPhotoUrl = uploadedUrl;
      }
    }

    await FirebaseFirestore.instance.collection('guardians').doc(uid).update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': gender,
      'photoUrl': newPhotoUrl,
    });

    setState(() {
      photoUrl = newPhotoUrl!;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final displayedImage =
        _newImage != null
            ? FileImage(_newImage!)
            : (photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: displayedImage as ImageProvider?,
                child:
                    displayedImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Tap to change photo'),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _genderOptions.contains(gender) ? gender : null,
              items:
                  _genderOptions.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g));
                  }).toList(),
              decoration: const InputDecoration(labelText: 'Gender'),
              onChanged: (val) {
                if (val != null) setState(() => gender = val);
              },
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _logout,
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
