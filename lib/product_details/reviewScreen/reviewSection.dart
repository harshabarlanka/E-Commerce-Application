import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ReviewSection extends StatefulWidget {
  final String productId;
  final String userId;

  const ReviewSection({super.key, required this.productId, required this.userId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  int _rating = 0;
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  bool _reviewSubmitted = false;

  Map<String, dynamic>? _submittedReview; // Store the review after submission

  Future<void> _submitReview() async {
    if (_rating == 0 || _controller.text.isEmpty) return;

    setState(() => _submitting = true);

    final reviewData = {
      'userId': widget.userId,
      'productId': widget.productId,
      'rating': _rating,
      'comment': _controller.text.trim(),
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('reviews').add(reviewData);

    setState(() {
      _submittedReview = reviewData;
      _reviewSubmitted = true;
      _submitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewSubmitted && _submittedReview != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < _submittedReview!['rating'] ? Colors.black : Colors.grey[400],
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _submittedReview!['comment'],
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    }

    // Show review input form if not submitted
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                color: _rating > index ? Colors.black : Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _rating = index + 1;
                });
              },
            );
          }),
        ),
        TextField(
          controller: _controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Write your review...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitReview,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Submit Review"),
          ),
        ),
      ],
    );
  }
}
