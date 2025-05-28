import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
class ShimmerGridLoader extends StatelessWidget {
  final int itemCount;
  const ShimmerGridLoader({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3,
        mainAxisSpacing: 2,
        childAspectRatio: 0.5,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 230,
                width: double.infinity,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 4),
              Container(
                height: 16,
                width: double.infinity,
                color: Colors.grey,
              ),
              const SizedBox(height: 4),
              Container(
                height: 16,
                width: 60,
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }
}
