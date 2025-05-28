// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/Authentication/LoginScreen/login_screen.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';

class CreateAccountScreen extends StatefulWidget {
  final String email;
  final String phone;

  final void Function()? onBack;

  const CreateAccountScreen({
    super.key,
    required this.email,
    required this.phone,
    this.onBack,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
    _phone.text = widget.phone;
  }

  Future<void> saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated")),
        );
        return;
      }

      final userData = {
        "uid": user.uid,
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving user: $e")),
        );
      }
    }
  }

  Future<void> _handleBack() async {
    if (widget.onBack != null) {
      widget.onBack!(); // Call parent method to clear FCM + Sign out
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator ??
          (val) {
            if (val == null || val.trim().isEmpty) {
              return "$label is required";
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _handleBack,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Create an Account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                buildTextField("First Name", _firstName),
                const SizedBox(height: 20),
                buildTextField("Last Name", _lastName),
                const SizedBox(height: 20),
                buildTextField(
                  "Email",
                  _email,
                  enabled: widget.email.isEmpty,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                buildTextField(
                  "Phone Number",
                  _phone,
                  enabled: widget.phone.isEmpty,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Create User",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
