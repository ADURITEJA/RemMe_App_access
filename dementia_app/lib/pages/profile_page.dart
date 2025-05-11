import 'dart:io';
import 'dart:ui';
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
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  // Define colors from the provided palette
  final Color backgroundColorSolid = const Color(0xFFF9EFE5); // Brand Beige
  final Color buttonColor = const Color(0xFF000000); // Black for buttons
  final Color accentColor = const Color(0xFFFF6F61); // Coral for alerts
  final Color textColorPrimary = const Color(0xFF000000); // Brand Black
  final Color textColorSecondary = const Color(
    0xFF7F8790,
  ); // Base Muted Gray-Blue
  final Color cardBackgroundColor = const Color(0xFFF8F8F8); // Base Light Gray
  final Color glassyOverlayColor = const Color(
    0xFF000000,
  ); // Black for glassy effect

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    String? newPhotoUrl = photoUrl;
    if (_newImage != null) {
      final uploadedUrl = await _uploadPhoto(_newImage!);
      if (uploadedUrl != null) {
        newPhotoUrl = uploadedUrl;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('guardians').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': gender,
        'photoUrl': newPhotoUrl,
      });

      setState(() {
        photoUrl = newPhotoUrl!;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: glassyOverlayColor.withOpacity(0.1)),
          ),
        ),
      ),
      body: Container(
        color: backgroundColorSolid,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
          child: Column(
            children: [
              // Profile photo with black glassy effect
              ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glassyOverlayColor.withOpacity(0.2),
                      border: Border.all(
                        color: textColorSecondary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: displayedImage as ImageProvider?,
                        child:
                            displayedImage == null
                                ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: textColorPrimary,
                                )
                                : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap to change photo',
                style: TextStyle(color: textColorSecondary, fontSize: 16),
              ),
              const SizedBox(height: 30),
              // Profile details (read-only) with black glassy effect
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor.withOpacity(0.9),
                      border: Border.all(
                        color: glassyOverlayColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildReadOnlyField(
                          'Email',
                          widget.profileData['email'] ?? 'N/A',
                          Icons.email,
                        ),
                        const SizedBox(height: 10),
                        _buildReadOnlyField(
                          'Role',
                          widget.profileData['role'] ?? 'N/A',
                          Icons.person_pin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Editable fields with black glassy effect
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor.withOpacity(0.9),
                      border: Border.all(
                        color: glassyOverlayColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Name', Icons.person),
                        const SizedBox(height: 20),
                        _buildTextField(
                          _phoneController,
                          'Phone',
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          _ageController,
                          'Age',
                          Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value:
                              _genderOptions.contains(gender) ? gender : null,
                          items:
                              _genderOptions
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                        g,
                                        style: const TextStyle(
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: const TextStyle(
                              color: Color(0xFF7F8790),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.transgender,
                              color: Color(0xFF7F8790),
                            ),
                            filled: true,
                            fillColor: textColorSecondary.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: glassyOverlayColor.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: glassyOverlayColor.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: textColorSecondary),
                            ),
                          ),
                          dropdownColor: cardBackgroundColor,
                          style: const TextStyle(color: Color(0xFF000000)),
                          onChanged: (val) {
                            if (val != null) setState(() => gender = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Save Changes button with black glassy effect
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: glassyOverlayColor.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: backgroundColorSolid,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          glassyOverlayColor.withOpacity(0.2),
                        ),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF9EFE5),
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Logout button with black glassy effect
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: glassyOverlayColor.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: backgroundColorSolid,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          glassyOverlayColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF7F8790),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Color(0xFF7F8790)),
        filled: true,
        fillColor: Color(0xFF7F8790).withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: glassyOverlayColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: glassyOverlayColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7F8790)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: textColorSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7F8790),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(color: Color(0xFF000000), fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
