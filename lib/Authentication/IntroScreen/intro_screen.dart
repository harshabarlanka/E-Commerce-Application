import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    _fadeIn();
  }

  Future<void> _fadeIn() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/appicon.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
