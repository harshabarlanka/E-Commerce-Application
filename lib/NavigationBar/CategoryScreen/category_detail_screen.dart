import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/provider/wishlist_provider.dart';
import 'package:shop/shimmer/product_Shimmer.dart';
import '../../product_details/product_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryTitle;

  const CategoryDetailScreen({
    super.key,
    required this.categoryTitle,
  });
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
          _capitalizeWords(categoryTitle),
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: categoryTitle)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ShimmerGridLoader();
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<String> imageUrls =
                (data['imageUrls'] as List<dynamic>? ?? [])
                    .map((item) => item.toString())
                    .toList();

            return {
              'id': doc.id,
              'brand': data['brand'] ?? '',
              'name': data['description'] ?? '',
              'price': data['price'] ?? '',
              'imageUrls': imageUrls,
              'image': imageUrls.isNotEmpty ? imageUrls[0] : null,
              'category': data['category'] ?? '',
              'gender': data['gender'] ?? 'Unisex',
            };
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          return GridView.builder(padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3,
              mainAxisSpacing: 2,
              childAspectRatio: 0.5,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                productCard(context, products[index]),
          );
        },
      ),
    );
  }


  Widget productCard(BuildContext context, Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              brand: product['brand'],
              name: product['name'],
              price: product['price'].toString(),
              imageUrls: List<String>.from(product['imageUrls']),
              id: product['id'].toString(),
              category: product['category'],
              gender: product['gender'],
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
                  color: product['color'],
                  // borderRadius: BorderRadius.circular(16),
                  image: product['image'] != null
                      ? DecorationImage(
                          image: NetworkImage(product['image']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "New",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, _) {
                          final isInWishlist =
                              wishlistProvider.isInWishlist(product['id']);

                          return GestureDetector(
                            onTap: () {
                              final productToAdd = {
                                'id': product['id'],
                                'name': product['brand'],
                                'description': product['name'],
                                'price': product['price'],
                                'imageUrl': product['image'],
                              };

                              if (isInWishlist) {
                                wishlistProvider
                                    .removeFromWishlist(product['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Removed from Wishlist")),
                                );
                              } else {
                                wishlistProvider.addToWishlist(productToAdd);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Added to Wishlist")),
                                );
                              }
                            },
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist ? Colors.black : Colors.white,
                            ),
                          );
                        },
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
                product['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${product['price'].toString()}', // Add the rupee symbol before the price
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
  }
}
