import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shop/Authentication/LoginScreen/login_screen.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';
import 'package:shop/Details/create_account_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  Future<void> checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigateTo(const LoginScreen());
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists ||
        doc['firstName'] == null ||
        doc['lastName'] == null ||
        doc['phone'] == null) {
      navigateTo(CreateAccountScreen(
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
      ));
    } else {
      navigateTo(const MainScreen());
    }
  }

  void navigateTo(Widget screen) {
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/appicon.png',
          height: 200,
          width: 200,
        ),
      ),
    );
  }
}
