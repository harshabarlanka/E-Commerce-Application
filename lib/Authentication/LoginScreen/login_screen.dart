// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/Authentication/LoginScreen/google_authentication.dart';
import 'package:shop/Authentication/LoginScreen/phone_authentication.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';
import '../../Details/create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String verificationId = '';
  bool otpSent = false;
  bool isLoading = false;
  bool isResendAvailable = false;
  int resendSeconds = 30;
  Timer? resendTimer;

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }

  void startResendTimer() {
    isResendAvailable = false;
    resendSeconds = 30;
    resendTimer?.cancel();
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds == 0) {
        timer.cancel();
        setState(() => isResendAvailable = true);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  Future<void> checkUserAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists &&
          doc['firstName'] != null &&
          doc['lastName'] != null &&
          doc['phone'] != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateAccountScreen(
              email: user.email ?? '',
              phone: user.phoneNumber ?? '',
            ),
          ),
        );
      }
    }
  }

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) {
      showSnackBar("Enter a valid 10-digit phone number");
      return;
    }

    setState(() => isLoading = true);

    await PhoneAuthentication.sendOtp(
      context: context,
      phone: phone,
      onCodeSent: (verId) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          isLoading = false;
        });
        startResendTimer();
      },
      onCompleted: () => setState(() => isLoading = false),
      onError: (msg) {
        setState(() => isLoading = false);
        showSnackBar("Verification failed: $msg");
      },
    );
  }

  Future<void> verifyOtp() async {
    setState(() => isLoading = true);
    await PhoneAuthentication.verifyOtp(
      context: context,
      verificationId: verificationId,
      smsCode: otpController.text.trim(),
      onCompleted: () => setState(() => isLoading = false),
      onError: (msg) {
        setState(() => isLoading = false);
        showSnackBar(msg);
      },
    );
  }

  Future<void> signInWithGoogle() async {
    await GoogleAuthentication.signInWithGoogle(context);
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          const Spacer(),
          const Text("NYKAA MAN",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          const Text("ULTIMATE\nLIFESTYLE DESTINATION\nFOR MEN",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(5)),
            child: const Text("FLAT ₹400 OFF\nON YOUR FIRST ORDER*",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 10),
          const Text("APP EXCLUSIVE OFFER",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text("NYKAA MAN",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Login or Signup",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Get started & grab best offers on top brands!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Text("+91"),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Mobile Number"),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              foregroundColor: Colors.black),
                          onPressed: isLoading
                              ? null
                              : () => otpSent ? verifyOtp() : sendOtp(),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : Text(otpSent ? "Verify" : "Get OTP"),
                        ),
                      ),
                    ),
                  ],
                ),
                if (otpSent) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: "Enter OTP"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 5),
                  isResendAvailable
                      ? TextButton(
                          onPressed: sendOtp, child: const Text("Resend OTP"))
                      : Text("Resend in $resendSeconds sec",
                          style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onPressed: signInWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Continue with Google",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                        Image.asset('assets/google.png', height: 25),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
