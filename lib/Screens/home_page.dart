import 'package:blorbmart2/Screens/Categories.dart';
import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:blorbmart2/Screens/product_details.dart';
import 'package:blorbmart2/Screens/product_feed.dart';
import 'package:blorbmart2/Screens/profile.dart';
import 'package:blorbmart2/saved_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const SavedPage(),
    const ProductFeed(categoryId: null, categoryName: null),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _carouselController = PageController();
  final Location _location = Location();
  final ScrollController _scrollController = ScrollController();

  List<String> _carouselImages = [];
  bool _isLoadingCarousel = true;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _sponsoredProducts = [];
  int _currentCarouselIndex = 0;
  int _cartCount = 0;
  LocationData? _currentLocation;
  final DateTime _flashSaleEnd = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _setupScrollListener();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchCartCount(),
      _getCurrentLocation(),
      _fetchCarouselImages(),
      _fetchCategories(),
      _fetchRandomProducts(),
    ]);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchMoreProducts();
      }
    });
  }

  Future<void> _fetchRandomProducts() async {
    try {
      final snapshot =
          await _firestore
              .collection('products')
              .where('approved', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      final products =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'No Name',
              'price': data['price']?.toDouble() ?? 0.0,
              'image':
                  data['imageUrls'] is List && data['imageUrls'].isNotEmpty
                      ? data['imageUrls'][0]
                      : '',
              'stock': data['stock'] ?? 0,
              'sponsored': data['sponsored'] ?? false,
              'description': data['description'] ?? '',
              'category': data['category'] ?? '',
              'sellerId': data['sellerId'] ?? '',
              'timestamp': data['timestamp'] ?? Timestamp.now(),
            };
          }).toList();

      if (mounted) {
        setState(() {
          _products = products.where((p) => !p['sponsored']).toList();
          _sponsoredProducts = products.where((p) => p['sponsored']).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
      _showErrorToast('Failed to load products');
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingProducts || _products.isEmpty) return;

    try {
      final lastProduct = _products.last;
      final lastTimestamp = lastProduct['timestamp'] as Timestamp;

      final snapshot =
          await _firestore
              .collection('products')
              .where('approved', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .startAfter([lastTimestamp])
              .limit(10)
              .get();

      final newProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'No Name',
              'price': data['price']?.toDouble() ?? 0.0,
              'image':
                  data['imageUrls'] is List && data['imageUrls'].isNotEmpty
                      ? data['imageUrls'][0]
                      : '',
              'stock': data['stock'] ?? 0,
              'sponsored': data['sponsored'] ?? false,
              'description': data['description'] ?? '',
              'category': data['category'] ?? '',
              'sellerId': data['sellerId'] ?? '',
              'timestamp': data['timestamp'] ?? Timestamp.now(),
            };
          }).toList();

      if (mounted && newProducts.isNotEmpty) {
        setState(() {
          _products.addAll(newProducts.where((p) => !p['sponsored']));
          _sponsoredProducts.addAll(newProducts.where((p) => p['sponsored']));
        });
      }
    } catch (e) {
      _showErrorToast('Failed to load more products');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').limit(6).get();
      final categories =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'No Name',
              'description': data['description'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
            };
          }).toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
      _showErrorToast('Failed to load categories');
    }
  }

  Future<void> _fetchCarouselImages() async {
    try {
      final snapshot = await _firestore.collection('carouselImages').get();
      final images =
          snapshot.docs
              .map((doc) => doc.data()['imageurl'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

      if (mounted) {
        setState(() {
          _carouselImages = images;
          _isLoadingCarousel = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCarousel = false;
        });
      }
      _showErrorToast('Failed to load carousel images');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = locationData;
        });
      }
    } catch (e) {
      _showErrorToast('Failed to get location');
    }
  }

  Future<void> _fetchCartCount() async {
    if (_auth.currentUser == null) return;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('cart')
              .get();
      if (mounted) {
        setState(() {
          _cartCount = doc.size;
        });
      }
    } catch (e) {
      if (mounted) _showErrorToast('Failed to load cart count');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to add items to cart');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(product['id'])
          .set({
            'productId': product['id'],
            'name': product['name'],
            'price': product['price'],
            'image': product['image'],
            'quantity': 1,
            'addedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() => _cartCount++);
      }
      _showSuccessToast('${product['name']} added to cart');
    } catch (e) {
      _showErrorToast('Failed to add to cart');
    }
  }

  Future<void> _toggleSavedProduct(Map<String, dynamic> product) async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to save products');
      return;
    }

    try {
      final savedRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('saved')
          .doc(product['id']);

      final doc = await savedRef.get();
      if (doc.exists) {
        await savedRef.delete();
        _showSuccessToast('${product['name']} removed from saved');
      } else {
        await savedRef.set({
          'productId': product['id'],
          'name': product['name'],
          'price': product['price'],
          'image': product['image'],
          'savedAt': FieldValue.serverTimestamp(),
        });
        _showSuccessToast('${product['name']} saved for later');
      }
    } catch (e) {
      _showErrorToast('Failed to update saved status');
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  String _formatCountdown() {
    Duration remaining = _flashSaleEnd.difference(DateTime.now());
    return '${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3D),
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
          ),
          child: TextField(
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search on Blorbmart',
              hintStyle: GoogleFonts.poppins(color: Colors.white70),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchInitialData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nearby feeds section
                  _buildSectionHeader(
                    icon: Icons.location_on,
                    title: 'Nearby Products & Stores',
                    subtitle:
                        _currentLocation != null
                            ? 'Lat: ${_currentLocation!.latitude!.toStringAsFixed(4)}, Long: ${_currentLocation!.longitude!.toStringAsFixed(4)}'
                            : null,
                    onSeeAll: () {},
                  ),

                  // Carousel slider
                  _buildImageCarousel(),

                  // Categories section
                  _buildSectionHeader(
                    title: 'Categories',
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                  ),
                  _buildCategories(),

                  // Flash sale banner
                  _buildFlashSaleBanner(),

                  // Products section
                  _buildSectionHeader(
                    title: 'Trending Products',
                    onSeeAll: () {},
                  ),
                ],
              ),
            ),

            // Trending products grid
            _isLoadingProducts
                ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 160,
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Card(
                                color: const Color(0xFF1A3A6A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                : SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
                  ),
                ),

            // Sponsored products section
            SliverToBoxAdapter(
              child: _buildSectionHeader(title: 'Sponsored', onSeeAll: () {}),
            ),
            _isLoadingProducts
                ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 160,
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Card(
                                color: const Color(0xFF1A3A6A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                : SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _sponsoredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_sponsoredProducts[index]);
                      },
                    ),
                  ),
                ),

            // Top sellers section
            SliverToBoxAdapter(
              child: _buildSectionHeader(title: 'Top Sellers', onSeeAll: () {}),
            ),
            SliverToBoxAdapter(child: _buildTopSellers()),

            // Official stores section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'Official Stores',
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(child: _buildOfficialStores()),

            // Loading indicator for more products
            SliverToBoxAdapter(
              child:
                  _isLoadingProducts && _products.isNotEmpty
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        ),
                      )
                      : const SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showBecomeSellerDialog(context),
        child: const Icon(Icons.store, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader({
    IconData? icon,
    required String title,
    String? subtitle,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.orange),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_isLoadingCarousel) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 180,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (_carouselImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.white),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 180,
              autoPlay: true,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              onPageChanged: (index, _) {
                setState(() => _currentCarouselIndex = index);
              },
            ),
            items:
                _carouselImages.map((imageUrl) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) =>
                                Container(color: Colors.white.withOpacity(0.1)),
                        errorWidget:
                            (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.1),
                              child: const Icon(
                                Icons.error,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                _carouselImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentCarouselIndex == entry.key
                              ? Colors.orange
                              : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    if (_isLoadingCategories) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[800]!,
                highlightColor: Colors.grey[700]!,
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 10, color: Colors.white),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductFeed(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image:
                          category['imageUrl'] != null &&
                                  category['imageUrl'].isNotEmpty
                              ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  category['imageUrl'],
                                ),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        category['imageUrl'] == null ||
                                category['imageUrl'].isEmpty
                            ? Center(
                              child: Icon(
                                Icons.category,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: Text(
                    category['name'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashSaleBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FLASH SALE',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Up to 50% off',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ends in ${_formatCountdown()}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Shop Now',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFB8C00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 160,
        child: Card(
          color: const Color(0xFF1A3A6A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: product['image'],
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => Container(
                                color: Colors.white.withOpacity(0.1),
                              ),
                          errorWidget:
                              (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.1),
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${product['price'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(
                                'Add to Cart',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleSavedProduct(product),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            _auth.currentUser != null
                                ? _firestore
                                    .collection('users')
                                    .doc(_auth.currentUser!.uid)
                                    .collection('saved')
                                    .doc(product['id'])
                                    .snapshots()
                                : null,
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data?.exists ?? false;
                          return Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : Colors.white,
                            size: 20,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (product['sponsored'])
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Sponsored',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSellers() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 3, // Placeholder - replace with actual data
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seller ${index + 1}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(
                      '4.${index + 5}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfficialStores() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 3, // Placeholder - replace with actual data
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 200,
              child: Card(
                color: const Color(0xFF1A3A6A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Official Store ${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBecomeSellerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A1E3D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Become a Seller on Blorbmart',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join our community of student sellers and start making money from your unused items!',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBenefitItem('No listing fees'),
                    _buildBenefitItem('Campus-wide reach'),
                    _buildBenefitItem('Secure transactions'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        const url = 'https://market-monitor-five.vercel.app';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Seller Portal',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.currentIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1E3D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isSelected: _currentIndex == 0,
                onTap: () => widget.onTabChange(0),
              ),
              _buildNavItem(
                icon: Icons.bookmark_rounded,
                label: 'Saved',
                index: 1,
                isSelected: _currentIndex == 1,
                onTap: () => widget.onTabChange(1),
              ),
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                index: 2,
                isSelected: _currentIndex == 2,
                onTap: () => widget.onTabChange(2),
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                isSelected: _currentIndex == 3,
                onTap: () => widget.onTabChange(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? Colors.orange : Colors.white.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
