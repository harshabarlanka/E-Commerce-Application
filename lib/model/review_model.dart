import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String username;
  final String avatarUrl;
  final double rating;
  final String comment;
  final Timestamp timestamp;

  Review({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });
}
