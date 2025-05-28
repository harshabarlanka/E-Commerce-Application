import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
  Color backgroundColor = Colors.black87,
}) {
  final mediaQuery = MediaQuery.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(
        top: mediaQuery.padding.top + kToolbarHeight + 8, // below the AppBar
        left: 12,
        right: 12,
      ),
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
