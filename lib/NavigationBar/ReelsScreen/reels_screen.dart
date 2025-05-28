import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/product_details/product_detail_screen.dart';
import 'package:shop/shimmer/shimmer_page.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ReelsScreen extends StatefulWidget {
  final String? initialReelId;

  const ReelsScreen({super.key, this.initialReelId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<DocumentSnapshot> _reels = [];
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadReels();
    _pageController.addListener(_pageScrollListener);
  }

  Future<void> _loadReels() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reels')
        .where('videoUrl', isNotEqualTo: "")
        .get();

    List<DocumentSnapshot> reels = snapshot.docs;

    // Shuffle the list
    reels.shuffle(Random());

    _reels = reels;

    int targetIndex = 0;
    if (widget.initialReelId != null) {
      final foundIndex =
          _reels.indexWhere((doc) => doc.id == widget.initialReelId);
      if (foundIndex != -1) {
        targetIndex = foundIndex;
        _currentPage = foundIndex;
      }
    }

    await Future.wait([
      _initializeControllerForPage(targetIndex, autoPlay: true),
      if (_reels.length > targetIndex + 1)
        _initializeControllerForPage(targetIndex + 1),
    ]);

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(targetIndex);
    });
  }

  Future<void> _initializeControllerForPage(int index,
      {bool autoPlay = false}) async {
    if (index < 0 ||
        index >= _reels.length ||
        _videoControllers.containsKey(index)) return;

    final reel = _reels[index];
    final videoController = VideoPlayerController.networkUrl(
      Uri.parse(reel['videoUrl']),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    await videoController.initialize();
    final chewieController = ChewieController(
      videoPlayerController: videoController,
      autoPlay: autoPlay,
      looping: false,
      showControls: false,
    );
    _videoControllers[index] = videoController;
    _chewieControllers[index] = chewieController;
  }

  void _disposeControllerForPage(int index) {
    _videoControllers[index]?.dispose();
    _chewieControllers[index]?.dispose();
    _videoControllers.remove(index);
    _chewieControllers.remove(index);
  }

  void _pageScrollListener() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      setState(() => _currentPage = newPage);

      _initializeControllerForPage(newPage, autoPlay: true);
      _initializeControllerForPage(newPage + 1); // preload next
      if (newPage - 1 >= 0) {
        _initializeControllerForPage(newPage - 1); // preload previous
      }

      // Pause non-visible videos
      _videoControllers.forEach((index, controller) {
        if (index != newPage && controller.value.isPlaying) {
          controller.pause();
        }
      });

      // Dispose far-off reels
      _videoControllers.keys.toList().forEach((index) {
        if (index < newPage - 1 || index > newPage + 1) {
          _disposeControllerForPage(index);
        }
      });

      // Play only current
      _chewieControllers[newPage]?.play();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    for (var chewieController in _chewieControllers.values) {
      chewieController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isLoading
              ? const ShimmerPlaceholder(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.zero,
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _reels.length,
                  itemBuilder: (context, index) {
                    final reel = _reels[index];
                    if (!_chewieControllers.containsKey(index)) {
                      return const ShimmerPlaceholder(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.zero,
                      );
                    }
                    return ReelPlayer(
                      chewieController: _chewieControllers[index]!,
                      videoController: _videoControllers[index]!,
                      productUids: List<String>.from(reel['productUids'] ?? []),
                    );
                  },
                ),
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/appicon.png', height: 105),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final ChewieController chewieController;
  final VideoPlayerController videoController;
  final List<String> productUids;

  const ReelPlayer({
    super.key,
    required this.chewieController,
    required this.videoController,
    required this.productUids,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  bool _showOverlay = false;
  List<DocumentSnapshot> _products = [];
  bool _justReplayed = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();

    widget.videoController.addListener(() {
      if (_justReplayed) return;

      final controller = widget.videoController;
      if (controller.value.position >= controller.value.duration &&
          !_showOverlay) {
        setState(() {
          _showOverlay = true;
        });
      }
    });
  }

  Future<void> _fetchProductDetails() async {
    if (widget.productUids.isEmpty) return;
    final productsRef = FirebaseFirestore.instance.collection('products');
    final snapshots = await Future.wait(
      widget.productUids.map((uid) => productsRef.doc(uid).get()),
    );
    setState(() {
      _products = snapshots.where((doc) => doc.exists).toList();
    });
  }

  void _replayVideo() async {
    setState(() {
      _showOverlay = false;
      _justReplayed = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    await widget.videoController.seekTo(Duration.zero);
    await widget.videoController.play();

    // Allow showing overlay again after a short delay
    await Future.delayed(const Duration(seconds: 1));
    _justReplayed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: widget.videoController.value.size.width,
              height: widget.videoController.value.size.height,
              child: Chewie(controller: widget.chewieController),
            ),
          ),
        ),

        // Animated Product Overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          bottom: _showOverlay ? MediaQuery.of(context).size.height * 0.25 : 15,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_products.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final cardWidth = screenWidth * 0.7; // 70% of screen width
                    final imageSize = screenWidth * 0.18; // 18% of screen width

                    return SizedBox(
                      height: 148,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final data = product.data() as Map<String, dynamic>;
                          final imageUrl =
                              (data['imageUrls'] as List).isNotEmpty
                                  ? data['imageUrls'][0]
                                  : '';

                          return Container(
                            width: cardWidth,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              // borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      // borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        height: imageSize,
                                        width: imageSize,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['brand'],
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['description'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      // shape: RoundedRectangleBorder(
                                      //   // borderRadius: BorderRadius.circular(10),
                                      // ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailScreen(
                                            id: data['id'],
                                            brand: data['brand'],
                                            name: data['description'],
                                            price: data['price'].toString(),
                                            imageUrls: List<String>.from(
                                                data['imageUrls']),
                                            category: data['category'],
                                            gender: data['gender'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Order Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

              // Replay button when overlay is shown
              if (_showOverlay)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      // shape: RoundedRectangleBorder(
                      //   // borderRadius: BorderRadius.circular(10),
                      // ),
                    ),
                    icon: const Icon(Icons.replay),
                    label: const Text('Replay'),
                    onPressed: _replayVideo,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
