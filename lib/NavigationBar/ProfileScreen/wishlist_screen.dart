import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/provider/bag_provider.dart';
import 'package:shop/provider/wishlist_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Map<String, String> _selectedSizes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).loadWishlist();
    });
  }

  Future<List<Map<String, dynamic>>> _getProductSizes(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      final data = doc.data();
      if (data == null || data['sizes'] == null) return [];

      return List<Map<String, dynamic>>.from(data['sizes']);
    } catch (e) {
      print("Error fetching sizes: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final bagProvider = Provider.of<BagProvider>(context);
    final wishlist = wishlistProvider.wishlist;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Wishlist",
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: wishlistProvider.isLoading // Check if data is loading
            ? ListView.builder(
                itemCount: 6, // Show 3 shimmer items as placeholders
                itemBuilder: (context, index) => shimmerItem(),
              )
            : wishlist.isEmpty
                ? const Center(child: Text("Your wishlist is empty"))
                : ListView.builder(
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final product = wishlist[index];
                      final productId = product['id'];
                      final selectedSize = _selectedSizes[productId] ?? '';
                      final uniqueProductId = "${productId}_${selectedSize}";
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              // borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                product['imageUrl'],
                                width: 100,
                                height: 139,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Name & Delete
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'No Name',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              product['description'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.black),
                                        onPressed: () {
                                          wishlistProvider
                                              .removeFromWishlist(productId);
                                        },
                                      ),
                                    ],
                                  ),
                                  // Price and Size
                                  Row(
                                    children: [
                                      Text(
                                        "₹${product['price']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _getProductSizes(productId),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox(
                                              height: 40,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2)),
                                            );
                                          }

                                          final sizes = snapshot.data!;
                                          if (sizes.isEmpty) {
                                            return const Text("Out of stock",
                                                style: TextStyle(
                                                    color: Colors.red));
                                          }

                                          final selected =
                                              _selectedSizes[productId];

                                          return DropdownButton<String>(
                                            value: selected,
                                            hint: const Text("Select Size"),
                                            isExpanded: false,
                                            items: sizes.map((sizeEntry) {
                                              final size = sizeEntry['size'];
                                              final inStock =
                                                  sizeEntry['stock'] > 0;

                                              return DropdownMenuItem<String>(
                                                value: size,
                                                enabled: inStock,
                                                child: Text(
                                                  inStock
                                                      ? size
                                                      : "$size (Out of Stock)",
                                                  style: TextStyle(
                                                    color: inStock
                                                        ? Colors.black
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedSizes[productId] =
                                                    value!;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: selectedSize.isEmpty
                                          ? null
                                          : () async {
                                              await bagProvider.addToBag({
                                                'id': uniqueProductId,
                                                'name': product['name'],
                                                'description':
                                                    product['description'] ??
                                                        '',
                                                'price': product['price'],
                                                'imageUrl': product['imageUrl'],
                                                'size': selectedSize,
                                                'quantity': 1,
                                              });

                                              await wishlistProvider
                                                  .removeFromWishlist(
                                                      productId);
                                              // ignore: use_build_context_synchronously
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Product moved to bag successfully!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      child: const Text(
                                        "Move to Bag",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // Function to create shimmer placeholder item
  Widget shimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer effect for product image
          ClipRRect(
            // borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 100,
              height: 138,
              color: Colors.grey[300], // Placeholder color
            ),
          ),
          const SizedBox(width: 12),
          // Shimmer effect for product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder color
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder color
                          ),
                        ],
                      ),
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete, color: Colors.red),
                    //   onPressed: () {},
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 60,
                      color: Colors.grey[300], // Placeholder color
                    ),
                    const Spacer(),
                    Container(
                      height: 16,
                      width: 60,
                      color: Colors.grey[300], // Placeholder color
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 40,
                    color: Colors.grey[300], // Placeholder color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
