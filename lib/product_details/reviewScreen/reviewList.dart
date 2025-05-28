import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class ReviewList extends StatefulWidget {
  final String productId;
  const ReviewList({super.key, required this.productId});

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  late final Stream<QuerySnapshot> _reviewStream;
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _reviewStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: widget.productId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) _userCache[userId] = data;
      return data;
    }
    return null;
  }

  Widget shimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 14, color: Colors.white),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Container(height: 10, width: 150, color: Colors.white),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                Icon(Icons.star, color: Colors.white, size: 20),
                Icon(Icons.star, color: Colors.white, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reviewStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(2, (_) => shimmerTile()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No reviews yet. Be the first to review!',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
          );
        }

        final reviews = snapshot.data!.docs;
        double avgRating = 0.0;

        for (var doc in reviews) {
          final data = doc.data() as Map<String, dynamic>;
          avgRating += (data['rating']?.toDouble() ?? 0.0);
        }
        avgRating /= reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  //   'Rating',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  // ),
                  // const SizedBox(
                  //   height: 5,
                  // ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.black54,
                      );
                    }),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.3),
                    child: Text('${avgRating.toStringAsFixed(1)} / 5.0'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final data = reviews[index].data() as Map<String, dynamic>;
                final comment = data['comment'] ?? '';
                final rating = data['rating']?.toDouble() ?? 0.0;
                final userId = data['userId'] ?? '';

                return FutureBuilder<Map<String, dynamic>?>(
                  future: getUser(userId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return shimmerTile();
                    }

                    final user = userSnapshot.data!;
                    final name =
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';

                    return ListTile(
                      leading:  CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade400,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 16, color: Colors.blue),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(comment),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (star) {
                              return Icon(
                                star < rating ? Icons.star : Icons.star_border,
                                color: Colors.black54,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
