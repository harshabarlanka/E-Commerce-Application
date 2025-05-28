import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false; // Track if we are editing or just viewing

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _firstNameController.text = userDoc['firstName'] ?? '';
          _lastNameController.text = userDoc['lastName'] ?? '';
          _phoneController.text = userDoc['phone'] ?? '';
          _emailController.text = userDoc['email'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
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
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
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
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // This will go back to the previous screen
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Update Profile",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                buildTextField("First Name", _firstNameController,
                    enabled: _isEditing),
                const SizedBox(height: 20),
                buildTextField("Last Name", _lastNameController,
                    enabled: _isEditing),
                const SizedBox(height: 20),
                buildTextField(
                  "Email",
                  _emailController,
                  enabled: false, // Email field is not editable
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                buildTextField(
                  "Phone Number",
                  _phoneController,
                  enabled:
                      _isEditing, // Phone number is editable only in edit mode
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isEditing
                        ? _updateUserProfile
                        : () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isEditing ? "Update Profile" : "Edit",
                      style: const TextStyle(fontSize: 18),
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
