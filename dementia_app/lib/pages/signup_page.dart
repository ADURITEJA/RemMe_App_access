import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isEmailSignup = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isOtpSent = false;
  String _status = '';

  void _toggleSignupMode() {
    setState(() {
      isEmailSignup = !isEmailSignup;
      _status = '';
    });
  }

  Future<void> _signupWithEmail() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _status = '✅ Signed up with email!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _status = '⏳ Sending OTP...';
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in for some phones
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          _status = '✅ Phone verified automatically!';
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _status = '❌ Verification failed: ${e.message}';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isOtpSent = true;
          _verificationId = verificationId;
          _status = '📩 OTP sent. Enter it below.';
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        _status = '✅ Phone number verified!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Invalid OTP: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isEmailSignup, !isEmailSignup],
              onPressed: (index) => _toggleSignupMode(),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Email Signup"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Phone Signup"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email Signup Form
            if (isEmailSignup) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              ElevatedButton(
                onPressed: _signupWithEmail,
                child: const Text('Signup with Email'),
              ),
            ],

            // Phone Signup Form
            if (!isEmailSignup) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              if (!_isOtpSent)
                ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text('Send OTP'),
                ),
              if (_isOtpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text('Verify & Signup'),
                ),
              ],
            ],

            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
