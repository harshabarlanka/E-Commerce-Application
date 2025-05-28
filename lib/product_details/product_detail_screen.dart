// ignore_for_file: equal_keys_in_map

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/provider/bag_provider.dart';
import 'package:shop/product_details/reviewScreen/reviewList.dart';
import 'package:shop/shimmer/custom_snackbar.dart';
import 'dart:async';
import 'package:shop/shimmer/shimmer_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String brand;
  final String name;
  final String price;
  final List<String> imageUrls;
  final String id;
  final String? videoUrl; // Add this field (nullable)

  final String category;
  final String gender;

  const ProductDetailScreen({
    super.key,
    required this.brand,
    required this.name,
    required this.price,
    required this.imageUrls,
    required this.id,
    this.videoUrl,
    required this.category, // add this
    required this.gender, // add this
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  String? _selectedSize;
  // List<String> _availableSizes = [];
  bool _isLoadingSizes = true;
  List<Map<String, dynamic>> _similarProducts = [];
  bool _isLoadingSimilar = true;
  List<Map<String, dynamic>> _availableSizes = [];

  final Map<String, List<String>> pairingMap = {
    'shirts': ['shirts', 'trousers', 'jeans'],
    'trousers': ['trousers', 'shirts', 'tshirt'],
    'tshirt': ['tshirt', 'shorts', 'joggers'],
    'kurtis': ['kurta', 'pants', 'pyjamas'],
    'tops': ['tops', 'bottom wear', 'skirts', 'jeans'],
    'sweater': ['sweater', 'trousers', 'jeans'],
    'hoodie': ['hoodie', 'joggers', 'jeans'],
    'jeans': ['jeans', 'shirts', 'tshirt', 'tops'],
    'joggers': ['joggers', 'tshirt', 'hoodie'],
    'shorts': ['shorts', 'tshirt', 'vest'],
    'skirts': ['skirts', 'tops', 'blouse'],
    'blouse': ['blouse', 'skirts', 'jeans'],
    'pants': ['pants', 'shirts', 'kurta'],
    'pyjamas': ['pyjamas', 'kurta', 'nightwear'],
    'nightwear': ['nightwear', 'pyjamas', 'tshirt'],
    'ethnic': ['ethnic', 'kurta', 'dupatta'],
    'formal': ['formal', 'shirts', 'trousers'],
    'jacket': ['jacket', 'jeans', 'tshirt'],
    'tracks': ['tracks', 'tshirt', 'hoodie'],
    'co-ord': ['co-ord', 'tops', 'skirts'],
    'dresses': ['dresses', 'heels', 'accessories'],
    'accessories': ['accessories', 'dresses', 'tops'],
    'heels': ['heels', 'dresses', 'skirts'],
    'sandals': ['sandals', 'kurta', 'tops'],
    'winter jackets': ['winter jackets', 'trousers', 'hoodie', 'jeans'],
  };

  Future<void> fetchSimilarProducts() async {
    try {
      final List<String> pairedCategories =
          pairingMap[widget.category] ?? [widget.category];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', whereIn: pairedCategories)
          .where('gender', isEqualTo: widget.gender)
          // .orderBy('purchaseCount', descending: true)
          .limit(10)
          .get();

      final allProducts = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Remove the currently opened product itself
      _similarProducts =
          allProducts.where((product) => product['id'] != widget.id).toList();
    } catch (e) {
      print("Error fetching similar products: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSimilar = false;
        });
      }
    }
  }

  int _purchaseCount = 0;

  Future<void> fetchProductSizes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.id) // ID from previous screen
          .get();

      print("📦 Fetching document for ID: ${widget.id}");

      if (doc.exists) {
        final data = doc.data()!;
        print("✅ Document data: $data");

        if (data.containsKey('sizes')) {
          final List<dynamic> sizesData = data['sizes'];
          print("🧵 Raw sizes data: $sizesData");

          // ✅ Proper cast to avoid null or runtime issues
          _availableSizes = sizesData
              .cast<Map<String, dynamic>>() // Cast needed
              .map((item) => {
                    'size': item['size'].toString(),
                    'stock': item['stock'] ?? 0,
                  })
              .toList();

          print("✅ Parsed sizes: $_availableSizes");
        } else {
          print("❌ 'sizes' key not found");
          _availableSizes = [];
        }

        // Optional: parse purchase count safely
        final rawCount = data['purchaseCount'];
        if (rawCount is int) {
          _purchaseCount = rawCount;
        } else if (rawCount is String) {
          _purchaseCount = int.tryParse(rawCount) ?? 0;
        } else {
          _purchaseCount = 0;
        }
      } else {
        print("❌ Document not found for ID: ${widget.id}");
      }
    } catch (e) {
      print("🚨 Error fetching sizes or purchase count: $e");
      _availableSizes = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSizes = false; // ✅ Triggers rebuild to show sizes
        });
      }
    }
  }

  String getPurchaseMessage(int count) {
    if (count == 0) return 'No purchases yet';
    if (count < 10) return '$count+ people bought this recently';
    return '$count+ people\nbought this product last month';
  }

  @override
  void initState() {
    super.initState();

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && widget.imageUrls.isNotEmpty) {
        int nextPage = (_currentIndex + 1) % widget.imageUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentIndex = nextPage;
        });
      }
    });

    fetchSimilarProducts(); // Fetch similar products
    // fetchPairedProducts();
    fetchProductSizes();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "SnenH",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Swiper
            SizedBox(
              height: 500,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.imageUrls[index],
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const ShimmerPlaceholder(
                              width: double.infinity, height: 500);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, size: 50),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 12 : 8,
                          height: _currentIndex == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Product Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.brand.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.name,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.price}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "MRP incl. of all taxes",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Size Picker
                  const Text("Select Size", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),

                  _isLoadingSizes
                      ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(5, (index) {
                            return const ShimmerPlaceholder(
                              width: 50,
                              height: 36,
                            );
                          }),
                        )
                      : _availableSizes.isEmpty
                          ? const Text("No sizes available")
                          : Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _availableSizes.map((sizeData) {
                                final String size = sizeData['size'];
                                final int stock = sizeData['stock'];
                                final bool isSelected = _selectedSize == size;
                                final bool isOutOfStock = stock <= 0;

                                return GestureDetector(
                                  onTap: isOutOfStock
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedSize = size;
                                          });
                                        },
                                  child: Opacity(
                                    opacity: isOutOfStock ? 0.4 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected && !isOutOfStock
                                            ? Colors.black
                                            : Colors.transparent,
                                        border:
                                            Border.all(color: Colors.black54),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected && !isOutOfStock
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                  const SizedBox(height: 22),

                  // Add to Bag
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedSize == null) {
                          showCustomSnackBar(
                            context,
                            icon: Icons.warning,
                            title: "Size Missing",
                            description:
                                "Please select a size before adding to bag",
                            backgroundColor: Colors.black,
                          );

                          return;
                        }

                        // final imageUrl = widget.imageUrls[_currentIndex];
                        final uniqueProductId =
                            "${widget.id}_${_selectedSize}"; // removed _currentIndex

                        final product = {
                          'id': uniqueProductId,
                          'originalId': widget.id,
                          'name': widget.brand,
                          'description': widget.name,
                          'price': double.parse(widget.price),
                          'size': _selectedSize,
                          'imageUrl': widget.imageUrls[_currentIndex],
                          'quantity': 1,
                          'timestamp': DateTime.now().toIso8601String(),
                        };

                        await Provider.of<BagProvider>(context, listen: false)
                            .addToBag(product);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Added ${widget.name} (Size: $_selectedSize) to bag"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 16),
                      ),
                      child: const Text(
                        'ADD TO BAG',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        getPurchaseMessage(_purchaseCount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoadingSimilar)
                    const Center(child: CircularProgressIndicator())
                  else if (_similarProducts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "You May Also Like",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarProducts.length,
                        itemBuilder: (context, index) {
                          final product = _similarProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    brand: product['brand'],
                                    name: product['description'],
                                    price: product['price'].toString(),
                                    imageUrls:
                                        List<String>.from(product['imageUrls']),
                                    id: product['id'],
                                    category: product['category'],
                                    gender: product['gender'],
                                    videoUrl: product['videoUrl'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      child: Image.network(
                                        product['imageUrls'][0],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product['brand'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    product['description'] ?? '',
                                    // maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '₹${product['price'].toString()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15), // <<---- 40px space at bottom
                    // Reviews Section
                  ],
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    "Customer Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ReviewList(productId: widget.id),
                  const SizedBox(
                    height: 50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
