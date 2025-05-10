import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ProfileQuestionGender extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProfileQuestionGender({super.key, required this.profileData});

  @override
  State<ProfileQuestionGender> createState() => _ProfileQuestionGenderState();
}

class _ProfileQuestionGenderState extends State<ProfileQuestionGender> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.profileData['gender']; // pre-fill if available
  }

  void _goToNextScreen() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
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

    widget.profileData['gender'] = _selectedGender;

    Navigator.pushNamed(context, '/profile/age', arguments: widget.profileData);
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color:
            isSelected ? const Color(0xFFE0F7FA) : Colors.white, // Light cyan
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color:
                isSelected
                    ? const Color(0xFF00B0FF) // Blue
                    : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color:
                    isSelected ? const Color(0xFF0091EA) : Colors.grey, // Blue
              ),
              const SizedBox(height: 10),
              Text(
                gender,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected
                          ? const Color(0xFF0077B6)
                          : Colors.black87, // Darker blue
                ),
              ),
            ],
          ),
        ),
      ),
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
                    'Please choose your gender',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGenderCard('Male', Icons.male),
                  _buildGenderCard('Female', Icons.female),
                  _buildGenderCard('Other', Icons.transgender),
                ],
              ),
              const SizedBox(height: 50),
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
            ],
          ),
        ),
      ),
    );
  }
}
