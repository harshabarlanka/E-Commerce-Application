// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Details/create_account_screen.dart';
import '../../NavigationBar/HomePage/mainScreen.dart';

class GoogleAuthentication {
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _checkUserAndNavigate(context);
    } catch (e) {
      _showSnackBar(context, "Google Sign-In failed");
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

  static void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }
}
