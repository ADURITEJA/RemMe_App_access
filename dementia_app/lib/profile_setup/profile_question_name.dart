import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ProfileQuestionName extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProfileQuestionName({super.key, required this.profileData});

  @override
  State<ProfileQuestionName> createState() => _ProfileQuestionNameState();
}

class _ProfileQuestionNameState extends State<ProfileQuestionName> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing name if present
    _nameController = TextEditingController(
      text: widget.profileData['name'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      return;
    }

    // Update profile data
    widget.profileData['name'] = name;

    Navigator.pushNamed(
      context,
      '/profile/phone',
      arguments: widget.profileData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.blue.shade50, // Light background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F7FA), // Light cyan
              Color(0xFFF0F4C3), // Light yellow
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              // Animated Text
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Let us know how to address you!',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600, // Semi-bold
                      color: Color(0xFF4A148C), // Deep purple
                    ),
                    speed: const Duration(milliseconds: 50), // Increased speed
                  ),
                ],
                isRepeatingAnimation: false,
                displayFullTextOnTap: true,
              ),
              const SizedBox(height: 40),
              // Styled TextField
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF212121), // Very dark gray
                ),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(
                    color: Color(0xFF7E57C2), // Light purple
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF9C27B0), // Purple
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFE91E63), // Pink
                      width: 2.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFD1C4E9), // Light purple 200
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Enter your full name',
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD), // Gray 400
                  ),
                ),
                cursorColor: const Color(0xFFE91E63), // Pink
              ),
              const SizedBox(height: 50),
              // Gradient Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF48FB1), // Pink 200
                      Color(0xFFE91E63), // Pink
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade200.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _goToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700, // Bold
                      color: Colors.white,
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
}
