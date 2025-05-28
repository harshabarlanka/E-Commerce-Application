import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ManageNotificationsScreen> createState() =>
      _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState
    extends State<ManageNotificationsScreen> {
  bool isEmailEnabled = false;
  bool isSmsEnabled = false;
  bool isWhatsAppEnabled = false;

  String email = '';
  String phone = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        setState(() {
          email = userDoc.data()?['email'] ?? '';
          phone = userDoc.data()?['phone'] ?? '';
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Manage Notifications',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _buildNotificationOption(
                    title: 'Email',
                    subtitle: 'Sent To $email',
                    iconUrl:
                        'https://upload.wikimedia.org/wikipedia/commons/4/4e/Gmail_Icon.png',
                    isEnabled: () => isEmailEnabled,
                    onChanged: (val) => setState(() => isEmailEnabled = val),
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationOption(
                    title: 'SMS',
                    subtitle: 'Sent To $phone',
                    iconUrl:
                        'https://upload.wikimedia.org/wikipedia/commons/5/51/Google_Messages_icon_%282022%29.svg'
,
                    isEnabled: () => isSmsEnabled,
                    onChanged: (val) => setState(() => isSmsEnabled = val),
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationOption(
                    title: 'WhatsApp',
                    subtitle: 'Sent To $phone',
                    iconUrl:
                        'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                    isEnabled: () => isWhatsAppEnabled,
                    onChanged: (val) =>
                        setState(() => isWhatsAppEnabled = val),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required String iconUrl,
    required bool Function() isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = isEnabled() ? Colors.black : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.network(
            iconUrl,
            width: 30,
            height: 30,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled(),
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
