import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ProfileQuestionPhoto extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProfileQuestionPhoto({super.key, required this.profileData});

  @override
  State<ProfileQuestionPhoto> createState() => _ProfileQuestionPhotoState();
}

class _ProfileQuestionPhotoState extends State<ProfileQuestionPhoto> {
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _uploadImageAndContinue() async {
    setState(() => _isUploading = true);

    try {
      if (_imageFile != null) {
        final fileName = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref().child(
          'profile_photos/$fileName.jpg',
        );
        await ref.putFile(_imageFile!);
        final downloadUrl = await ref.getDownloadURL();
        widget.profileData['photoUrl'] = downloadUrl;
      } else {
        widget.profileData['photoUrl'] =
            ''; // Optional: Leave blank or placeholder
      }

      Navigator.pushNamed(
        context,
        '/profile/summary',
        arguments: widget.profileData,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Your Photo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _imageFile != null
                ? CircleAvatar(
                  radius: 70,
                  backgroundImage: FileImage(_imageFile!),
                )
                : const CircleAvatar(
                  radius: 70,
                  child: Icon(Icons.person, size: 50),
                ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text("Choose Photo"),
            ),
            const SizedBox(height: 30),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _uploadImageAndContinue,
                  child: const Text("Continue"),
                ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                widget.profileData['photoUrl'] = '';
                Navigator.pushNamed(
                  context,
                  '/profile/summary',
                  arguments: widget.profileData,
                );
              },
              child: const Text("Skip this step"),
            ),
          ],
        ),
      ),
    );
  }
}
