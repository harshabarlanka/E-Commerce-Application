// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Details/create_account_screen.dart';
import '../../NavigationBar/HomePage/mainScreen.dart';

class PhoneAuthentication {
  static Future<void> sendOtp({
    required BuildContext context,
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function onCompleted,
    required Function(String errorMessage) onError,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _checkUserAndNavigate(context);
        onCompleted();
      },
      verificationFailed: (e) => onError(e.message ?? "Unknown error"),
      codeSent: (verId, _) => onCodeSent(verId),
      codeAutoRetrievalTimeout: (verId) {},
    );
  }

  static Future<void> verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String smsCode,
    required Function onCompleted,
    required Function(String errorMessage) onError,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _checkUserAndNavigate(context);
      onCompleted();
    } catch (e) {
      onError("Invalid OTP");
    }
  }

  static Future<void> _checkUserAndNavigate(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists &&
          doc['firstName'] != null &&
          doc['lastName'] != null &&
          doc['phone'] != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
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
}
