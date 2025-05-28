import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shop/product_details/product_detail_screen.dart';
import 'package:shop/shimmer/product_Shimmer.dart';
class TrendingProductsScreen extends StatefulWidget {
  final String category;

  const TrendingProductsScreen({super.key, required this.category});

  @override
  State<TrendingProductsScreen> createState() => _TrendingProductsScreenState();
}

class _TrendingProductsScreenState extends State<TrendingProductsScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchTrendingProducts(widget.category);
  }

  Future<List<Map<String, dynamic>>> fetchTrendingProducts(
      String category) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: category)
        .get();

    List<Map<String, dynamic>> products =
        querySnapshot.docs.map((doc) => doc.data()).toList();

    products.sort((a, b) {
      final countA = a['purchaseCount'] ?? 0;
      final countB = b['purchaseCount'] ?? 0;
      return countB.compareTo(countA); // Descending
    });

    return products;
  }

  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _capitalizeWords(' Trending ${widget.category}'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ShimmerGridLoader());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.5,
              crossAxisSpacing: 3,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              final product = products[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        brand: product['brand'] ?? '',
                        name: product['description'] ?? '',
                        price: product['price']?.toString() ?? '0.0',
                        imageUrls: List<String>.from(product['imageUrls']),
                        id: product['id'],
                        category: product['category'] ?? '',
                        gender: product['gender'] ?? '',
                      ),
                    ),
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: constraints.maxHeight * 0.65,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // borderRadius: BorderRadius.circular(16),
                            image: product['imageUrls'] != null &&
                                    (product['imageUrls'] as List).isNotEmpty
                                ? DecorationImage(
                                    image:
                                        NetworkImage(product['imageUrls'][0]),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "New",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['brand'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${product['price'].toString()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
