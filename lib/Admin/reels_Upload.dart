// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ReelUploadScreen extends StatefulWidget {
  const ReelUploadScreen({super.key});

  @override
  State<ReelUploadScreen> createState() => _ReelUploadScreenState();
}

class _ReelUploadScreenState extends State<ReelUploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  bool _loading = false;

  Future<void> _uploadReel() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reel title")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      String id = const Uuid().v4();

      await FirebaseFirestore.instance.collection('reels').doc(id).set({
        'id': id,
        'title': _titleController.text.trim(),
        'videoUrl': _videoUrlController.text.trim(),
        'productUIds': [],
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Reel uploaded successfully")),
      );

      _titleController.clear();
      _videoUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Reel"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_titleController, "Reel Title"),
              _buildTextField(_videoUrlController, "Video URL (optional)"),
              const SizedBox(height: 30),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadReel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 40),
                      ),
                      child: const Text("Upload Reel"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
