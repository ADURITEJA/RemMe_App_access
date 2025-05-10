import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ProfileQuestionAge extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProfileQuestionAge({super.key, required this.profileData});

  @override
  State<ProfileQuestionAge> createState() => _ProfileQuestionAgeState();
}

class _ProfileQuestionAgeState extends State<ProfileQuestionAge> {
  int _selectedAge = 25; // Default

  @override
  void initState() {
    super.initState();
    // Load age if returning to this screen
    if (widget.profileData['age'] != null) {
      final age = int.tryParse(widget.profileData['age'].toString());
      if (age != null) {
        _selectedAge = age;
      }
    }
  }

  void _goToNextScreen() {
    widget.profileData['age'] = _selectedAge.toString(); // Store as String

    Navigator.pushNamed(
      context,
      '/profile/photo',
      arguments: widget.profileData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.lightBlue.shade50,
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
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Select your age',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00838F), // Dark cyan
                    ),
                    speed: const Duration(milliseconds: 50),
                  ),
                ],
                isRepeatingAnimation: false,
                displayFullTextOnTap: true,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _selectedAge - 1,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedAge = index + 1;
                    });
                  },
                  children: List<Widget>.generate(
                    100,
                    (int index) => Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80DEEA), Color(0xFF00B0FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.5),
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
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
