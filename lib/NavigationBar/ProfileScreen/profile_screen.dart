// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/Admin/admin_screen.dart';
import 'package:shop/Authentication/LoginScreen/login_screen.dart';
import 'package:shop/NavigationBar/ProfileScreen/communication%20screen.dart';
import 'package:shop/NavigationBar/ProfileScreen/myorders.dart';
import 'package:shop/NavigationBar/ProfileScreen/savedAddress.dart';
import 'package:shop/NavigationBar/ProfileScreen/profile_update.dart';
import 'package:shop/NavigationBar/ProfileScreen/shopping_discount.dart';
import 'package:shop/NavigationBar/ProfileScreen/wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          displayName = userDoc['firstName'] +
              " " +
              userDoc['lastName']; // Combine first and last name
        });
      }
    }
  }

  final bool isAdmin =
      FirebaseAuth.instance.currentUser?.email == "snenh2025@gmail.com";

  // Capitalize words function
  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SnenH',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: isAdmin
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserUploadPage(),
                                  ),
                                );
                              }
                            : null,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            if (isAdmin)
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _capitalizeWords(displayName), // Display fetched name
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Options Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        icon: Icons.shopping_bag_outlined,
                        text: "My Orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyOrderScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildProfileOption(
                        icon: Icons.favorite_border,
                        text: "My Wishlist",
                        onTap: () {
                          // Correct way to navigate to the WishlistScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const WishlistScreen()), // Wrap WishlistScreen with MaterialPageRoute
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildProfileOption(
                        icon: Icons.location_on_outlined,
                        text: "Saved Address",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SavedAddressScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildProfileOption(
                        icon: Icons.account_circle_outlined,
                        text: "Profile Details",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileUpdateScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildProfileOption(
                        icon: Icons.discount_outlined,
                        text: "Shopping Discounts",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CouponScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildProfileOption(
                        icon: Icons.handshake,
                        text: "Communication",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ManageNotificationsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Logout Button (full width)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("Logout"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: Colors.grey,
    );
  }
}
