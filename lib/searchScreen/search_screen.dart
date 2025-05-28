import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/NavigationBar/ReelsScreen/reels_screen.dart';
import 'package:shop/product_details/product_detail_screen.dart';
import 'package:shop/provider/wishlist_provider.dart';
import 'package:provider/provider.dart';
import 'package:shop/shimmer/product_Shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = '';
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Field
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5.5), // Reduced vertical padding
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            style: const TextStyle(
                                fontSize: 16), // Slightly smaller text
                            decoration: InputDecoration(
                              isDense: true, // Reduces height
                              hintText: 'Search...',
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search,
                                size: 22, // Smaller icon
                                color: _isSearchFocused
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.black,
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: 3.0),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.video_library)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontally Scrollable Category Buttons
                  SizedBox(
                    height: 48,
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final categories = snapshot.data!.docs
                            .map((doc) => doc['category']?.toString() ?? '')
                            .toSet()
                            .where((cat) => cat.isNotEmpty)
                            .toList();

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              _buildCategoryChip(
                                  context, 'All', _selectedCategory == ''),
                              const SizedBox(width: 8),
                              ...categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildCategoryChip(
                                    context,
                                    category,
                                    _selectedCategory == category,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Grid / Reels View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  GridTab(
                    isReel: false,
                    searchQuery: _searchQuery,
                    selectedCategory: _selectedCategory,
                  ),
                  GridTab(
                    isReel: true,
                    searchQuery: _searchQuery,
                    selectedCategory: _selectedCategory,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = (label == 'All') ? '' : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.black,
            width: 1.3,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class GridTab extends StatelessWidget {
  final bool isReel;
  final String searchQuery;
  final String selectedCategory;

  const GridTab({
    super.key,
    required this.isReel,
    required this.searchQuery,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (isReel) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reels').snapshots(),
        builder: (context, reelsSnapshot) {
          if (!reelsSnapshot.hasData) {
            return const Center(child: ShimmerGridLoader());
          }

          final reelsDocs = reelsSnapshot.data!.docs;

          // 1. Collect all unique product UIDs from reels
          final allProductUids = reelsDocs
              .expand(
                  (reelDoc) => List<String>.from(reelDoc['productUids'] ?? []))
              .toSet()
              .toList();
          if (allProductUids.isEmpty) {
            return const Center(child: Text("No reels found"));
          }
          // 2. Batch fetch products in a single query
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .where(FieldPath.documentId,
                    whereIn: allProductUids.take(10).toList())
                .get(),
            builder: (context, productSnapshot) {
              if (!productSnapshot.hasData) {
                return const Center(child: ShimmerGridLoader());
              }

              // 3. Map productId -> productData
              final productMap = {
                for (var doc in productSnapshot.data!.docs)
                  doc.id: doc.data() as Map<String, dynamic>
              };

              // 4. Filter reels based on matching products and query
              final filteredReels = reelsDocs.where((reelDoc) {
                final productUids =
                    List<String>.from(reelDoc['productUids'] ?? []);
                for (String uid in productUids) {
                  final product = productMap[uid];
                  if (product == null) continue;

                  final description =
                      (product['description'] ?? '').toString().toLowerCase();
                  final brand =
                      (product['brand'] ?? '').toString().toLowerCase();
                  final category =
                      (product['category'] ?? '').toString().toLowerCase();

                  final matchesSearch = searchQuery.isEmpty ||
                      description.contains(searchQuery.toLowerCase()) ||
                      brand.contains(searchQuery.toLowerCase());

                  final matchesCategory = selectedCategory.isEmpty ||
                      category == selectedCategory.toLowerCase();

                  if (matchesSearch && matchesCategory) return true;
                }
                return false;
              }).toList();

              if (filteredReels.isEmpty) {
                return const Center(child: Text("No reels found"));
              }

              // 5. Build grid
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.5,
                ),
                itemCount: filteredReels.length,
                itemBuilder: (context, index) {
                  final reelDoc = filteredReels[index];
                  final reelId = reelDoc.id;
                  final productUids =
                      List<String>.from(reelDoc['productUids'] ?? []);
                  final firstProductUid =
                      productUids.isNotEmpty ? productUids[0] : null;
                  final product = firstProductUid != null
                      ? productMap[firstProductUid]
                      : null;

                  if (product == null) {
                    return const Center(child: Text("Product not found"));
                  }

                  final Timestamp? productTimestamp = product['timestamp'];
                  final DateTime? productDate = productTimestamp?.toDate();
                  final bool isNew = productDate != null &&
                      DateTime.now().difference(productDate).inDays <= 5;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReelsScreen(initialReelId: reelId),
                        ),
                      );
                    },
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: constraints.maxHeight * 0.65,
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                                if (isNew)
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
                          const SizedBox(height: 6),
                          Text(
                            product['brand'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${product['price']?.toString() ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      );
                    }),
                  );
                },
              );
            },
          );
        },
      );
    } else {
      // Keep your existing products tab as-is
      return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: ShimmerGridLoader());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final hasImages = (data['imageUrls'] as List?)?.isNotEmpty ?? false;
            final brand = data['brand']?.toString().toLowerCase() ?? '';
            final description =
                data['description']?.toString().toLowerCase() ?? '';
            final category = data['category']?.toString().toLowerCase() ?? '';

            final matchesSearch = brand.contains(searchQuery) ||
                description.contains(searchQuery);
            final matchesCategory = selectedCategory.isEmpty ||
                category == selectedCategory.toLowerCase();

            return hasImages && matchesSearch && matchesCategory;
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3,
              mainAxisSpacing: 2,
              childAspectRatio: 0.5,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index].data();
              final imageUrl = (product['imageUrls'] as List).isNotEmpty
                  ? product['imageUrls'][0]
                  : 'https://via.placeholder.com/150';
              final description = product['description'] ?? '';
              final productId = product['id'];
              final Timestamp productTimestamp = product['timestamp'];
              final DateTime productDate = productTimestamp.toDate();
              final bool isNew =
                  DateTime.now().difference(productDate).inDays <= 5;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        brand: product['brand'],
                        name: product['description'],
                        price: product['price'].toString(),
                        imageUrls: List<String>.from(product['imageUrls']),
                        id: productId,
                        category: product['category'],
                        gender: product['gender'],
                        videoUrl: null,
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
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (isNew)
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
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Consumer<WishlistProvider>(
                                  builder: (context, wishlistProvider, _) {
                                    final isInWishlist = wishlistProvider
                                        .isInWishlist(product['id']);
                                    return GestureDetector(
                                      onTap: () {
                                        final productToAdd = {
                                          'id': product['id'],
                                          'name': product['brand'],
                                          'description': product['description'],
                                          'price': product['price'],
                                          'imageUrl':
                                              (product['imageUrls'] as List)
                                                      .isNotEmpty
                                                  ? product['imageUrls'][0]
                                                  : null,
                                        };
                                        if (isInWishlist) {
                                          wishlistProvider.removeFromWishlist(
                                              product['id']);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Removed from Wishlist")),
                                          );
                                        } else {
                                          wishlistProvider
                                              .addToWishlist(productToAdd);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text("Added to Wishlist")),
                                          );
                                        }
                                      },
                                      child: Icon(
                                        isInWishlist
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isInWishlist
                                            ? Colors.black
                                            : Colors.white,
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
                          description,
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
      );
    }
  }
}
