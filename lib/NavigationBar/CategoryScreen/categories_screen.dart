import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop/searchScreen/search_screen.dart';
import 'package:shop/NavigationBar/CategoryScreen/category_detail_screen.dart';

class CategoryScrollPage extends StatefulWidget {
  const CategoryScrollPage({super.key});

  @override
  State<CategoryScrollPage> createState() => _CategoryScrollPageState();
}

class _CategoryScrollPageState extends State<CategoryScrollPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _circleScrollController = ScrollController();
  final GlobalKey _circleRowKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _selectedGender;

  bool _isLoading = true;
  Map<String, Map<String, Map<String, dynamic>>> _groupedData = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final products =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    final Map<String, Map<String, Map<String, dynamic>>> grouped = {};
    for (var product in products) {
      final gender = product['gender'] ?? 'Other';
      final category = product['category'] ?? 'Unknown';

      grouped.putIfAbsent(gender, () => {});
      grouped[gender]![category] ??= product;
    }

    setState(() {
      _groupedData = grouped;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _circleScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String gender) {
    final sectionContext = _sectionKeys[gender]?.currentContext;
    final circleContext = _circleRowKey.currentContext;

    if (sectionContext != null && circleContext != null) {
      final sectionBox = sectionContext.findRenderObject() as RenderBox;
      final circleBox = circleContext.findRenderObject() as RenderBox;
      final sectionOffset = sectionBox.localToGlobal(Offset.zero);
      final circleHeight = circleBox.size.height;
      final appBarHeight = kToolbarHeight;
      final statusBarHeight = MediaQuery.of(context).padding.top;
      final totalTopOffset = appBarHeight + statusBarHeight + circleHeight;
      final scrollOffset =
          sectionOffset.dy + _scrollController.offset - totalTopOffset;
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }
  }

  void _scrollCircleToCenter(int index, double itemWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = itemWidth * index - (screenWidth / 2 - itemWidth / 2);

    _circleScrollController.animateTo(
      offset.clamp(
        _circleScrollController.position.minScrollExtent,
        _circleScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _capitalize(String str) =>
      str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SnenH',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildCircleList(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: _buildSections(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCircleList() {
    final genders = _groupedData.keys.toList();
    _sectionKeys.clear();
    for (var gender in genders) {
      _sectionKeys[gender] = GlobalKey();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth * 0.22;

    return Container(
      key: _circleRowKey,
      height: screenWidth * 0.35,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ListView.separated(
        controller: _circleScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: genders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (_, index) {
          final gender = genders[index];
          final product = _groupedData[gender]!.values.first;
          final List<dynamic>? urls = product['imageUrls'];
          final String? imageUrl =
              (urls != null && urls.isNotEmpty) ? urls[0] : null;
          final bool isSelected = gender == _selectedGender;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = gender;
              });
              _scrollToSection(gender);
              _scrollCircleToCenter(index, itemWidth);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: isSelected ? itemWidth + 12 : itemWidth,
                  height: isSelected ? itemWidth + 12 : itemWidth,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey.shade300,
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: imageUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _capitalize(gender),
                  style: TextStyle(
                    fontSize: isSelected ? 14 : 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSections() {
    final genders = _groupedData.keys.toList();
    return [
      ...genders.map((gender) {
        return Column(
          key: _sectionKeys[gender],
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "${_capitalize(gender)}'s Wear",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            _buildCategoryGrid(_groupedData[gender]!),
            const SizedBox(height: 20),
          ],
        );
      }),
      const SizedBox(height: 400),
    ];
  }

  Widget _buildCategoryGrid(Map<String, Map<String, dynamic>> categories) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 130).floor().clamp(2, 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          // mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final categoryName = categories.keys.elementAt(index);
          final product = categories[categoryName]!;
          final List<dynamic>? urls = product['imageUrls'];
          final String? imageUrl =
              (urls != null && urls.isNotEmpty) ? urls[0] : null;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CategoryDetailScreen(categoryTitle: categoryName),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    // borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Category image
                        imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 40),
                                ),
                              ),

                        // Bottom Centered White Bold Text
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              categoryName.toUpperCase(), // Ensures ALL CAPS
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),

                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Text(
                //   _capitalize(categoryName),
                //   style: const TextStyle(
                //       fontWeight: FontWeight.bold, fontSize: 14),
                //   textAlign: TextAlign.center,
                // ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          2,
          (section) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 20,
                width: 120,
                color: Colors.grey.shade300,
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 5,
                  childAspectRatio: 0.62,
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    // borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
