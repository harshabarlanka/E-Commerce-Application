// ignore_for_file: library_private_types_in_public_api, file_names

import 'dart:async';
// import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/searchScreen/search_screen.dart';
// import 'package:shop/product_details/product_detail_screen.dart';
import 'package:shop/NavigationBar/HomePage/trending_Products.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _scrollTimer;

  List<Map<String, dynamic>> firebaseProducts = [];
  final List<String> fallbackSections = [
    "Women",
    "Men",
    "Accessories",
    "Shoes",
    "Beauty",
    "Home"
  ];

  @override
  void initState() {
    super.initState();
    fetchTrendingByCategory();
    _startAutoScroll();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        const totalSlides = 5; // Limit to 5 slides or less

        if (nextPage >= totalSlides) nextPage = 0;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchTrendingByCategory() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();
    final allProducts = snapshot.docs.map((doc) => doc.data()).toList();

    final categoryGroups = <String, List<Map<String, dynamic>>>{};

    for (var product in allProducts) {
      final category = product['category'] ?? 'Unknown';
      categoryGroups.putIfAbsent(category, () => []).add(product);
    }

    final List<Map<String, dynamic>> topByCategory = [];

    categoryGroups.forEach((category, products) {
      final withPurchase = products
          .where((p) => (p['purchaseCount'] ?? 0) > 0)
          .toList()
        ..sort((a, b) =>
            (b['purchaseCount'] ?? 0).compareTo(a['purchaseCount'] ?? 0));

      final topProduct = withPurchase.isNotEmpty
          ? withPurchase.first
          : (products..shuffle()).first;

      topByCategory.add(topProduct);
    });

    // 🔥 Sort by highest purchaseCount among selected top products
    topByCategory.sort(
        (a, b) => (b['purchaseCount'] ?? 0).compareTo(a['purchaseCount'] ?? 0));

    setState(() {
      firebaseProducts = topByCategory;
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring it accepts 5 slides or fewer, depending on available products
    final int slideCount = firebaseProducts.isNotEmpty
        ? (firebaseProducts.length <= 5 ? firebaseProducts.length : 5)
        : fallbackSections.length;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: slideCount,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final isFirebaseSlide = index < firebaseProducts.length;
                final String category = isFirebaseSlide
                    ? firebaseProducts[index]['category'] ?? 'Unknown'
                    : fallbackSections[index];

                final List<dynamic>? imageUrls = isFirebaseSlide
                    ? firebaseProducts[index]['imageUrls']
                    : null;
                final String? imageUrl =
                    (imageUrls != null && imageUrls.isNotEmpty)
                        ? imageUrls[0]
                        : null;

                return GestureDetector(
                  onTap: () {
                    if (isFirebaseSlide &&
                        firebaseProducts[index]['category'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrendingProductsScreen(
                            category: firebaseProducts[index]
                                ['category'], // changed
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 50,
                          left: 30,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trending',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "it's a feeling",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.yellow,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Replace the Text with your App Icon
                  Image.asset(
                    'assets/appicon.png', // Update this path to your actual icon path
                    height: 105, // adjust size as needed
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.search,
                          color: Colors.black, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SearchScreen()),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height / 3,
            child: Column(
              children: List.generate(
                slideCount,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 12 : 8,
                    height: _currentPage == index ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
