import 'dart:async';

import 'package:blorbmart2/Screens/Categories.dart';
import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:blorbmart2/Screens/product_details.dart';
import 'package:blorbmart2/Screens/product_feed.dart';
import 'package:blorbmart2/Screens/profile.dart';
import 'package:blorbmart2/saved_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final Location _location = Location();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 0;

  List<String> _carouselImages = [];
  bool _isLoadingCarousel = true;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _sponsoredProducts = [];
  int _currentCarouselIndex = 0;
  int _cartCount = 0;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isInitialLoadComplete = false;

  // Cache variables
  static List<String>? _cachedCarouselImages;
  static List<Map<String, dynamic>>? _cachedCategories;
  static List<Map<String, dynamic>>? _cachedProducts;
  static List<Map<String, dynamic>>? _cachedSponsoredProducts;

  final List<Widget> _screens = [
    const _HomeContent(),
    const SavedPage(),
    const ProductFeed(categoryId: null, categoryName: null),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAuthListener();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchCartCount();
      } else {
        setState(() => _cartCount = 0);
      }
    });
  }

  Future<void> _initializeData() async {
    if (!_isInitialLoadComplete) {
      await _fetchInitialDataFromCache();
    }
    await _fetchInitialDataFromServer();

    if (!_isInitialLoadComplete) {
      setState(() => _isInitialLoadComplete = true);
    }
  }

  Future<void> _fetchInitialDataFromCache() async {
    try {
      if (_cachedCarouselImages != null) {
        setState(() {
          _carouselImages = _cachedCarouselImages!;
          _isLoadingCarousel = false;
        });
      }

      if (_cachedCategories != null) {
        setState(() {
          _categories = _cachedCategories!;
          _isLoadingCategories = false;
        });
      }

      if (_cachedProducts != null && _cachedSponsoredProducts != null) {
        setState(() {
          _products = _cachedProducts!;
          _sponsoredProducts = _cachedSponsoredProducts!;
          _isLoadingProducts = false;
        });
      }

      if (_auth.currentUser != null) _fetchCartCount(Source.cache);
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _fetchInitialDataFromServer() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (!_isInitialLoadComplete) {
          _showErrorToast('No internet connection');
        }
        return;
      }

      await Future.wait([
        _fetchCarouselImages(),
        _fetchCategories(),
        _fetchInitialProducts(),
        if (_auth.currentUser != null) _fetchCartCount(),
      ]);
    } catch (e) {
      debugPrint('Error loading from server: $e');
      if (!_isInitialLoadComplete) {
        _showErrorToast('Failed to load data. Please try again.');
      }
    }
  }

  Future<void> _fetchCarouselImages() async {
    if (!mounted) return;

    setState(() => _isLoadingCarousel = true);

    try {
      final snapshot = await _firestore.collection('carouselImages').get();

      final images =
          snapshot.docs
              .where((doc) => doc.exists && doc.data().containsKey('imageurl'))
              .map((doc) => doc['imageurl'] as String)
              .toList();

      if (mounted) {
        setState(() {
          _carouselImages = images;
          _isLoadingCarousel = false;
          _cachedCarouselImages = images;
        });
      }
    } catch (e) {
      debugPrint('Error fetching carousel images: $e');
      if (mounted) {
        setState(() => _isLoadingCarousel = false);
        _showErrorToast('Failed to load carousel images');
      }
    }
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;

    setState(() => _isLoadingCategories = true);

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
          _cachedCategories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        _showErrorToast('Failed to load categories');
      }
    }
  }

  Future<void> _fetchInitialProducts() async {
    if (!mounted) return;

    setState(() => _isLoadingProducts = true);

    try {
      final snapshot =
          await _firestore
              .collection('products')
              .where('approved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

      final products = await _parseProductDocuments(snapshot.docs);

      if (mounted) {
        setState(() {
          _products = products.where((p) => !p['sponsored']).toList();
          _sponsoredProducts = products.where((p) => p['sponsored']).toList();
          _isLoadingProducts = false;
          _cachedProducts = _products;
          _cachedSponsoredProducts = _sponsoredProducts;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching products: $e\n$stackTrace');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        _showErrorToast('Failed to load products');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _parseProductDocuments(
    List<DocumentSnapshot> docs,
  ) async {
    return Future.value(
      docs
              .map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  return {
                    'id': doc.id,
                    'name': data['name'] ?? 'No Name',
                    'price': (data['price'] as num?)?.toDouble() ?? 0.0,
                    'image':
                        (data['images'] is List && data['images'].isNotEmpty)
                            ? data['images'][0]
                            : '',
                    'stock': data['stock'] ?? 0,
                    'sponsored': data['sponsored'] ?? false,
                    'description': data['description'] ?? '',
                    'category': data['category'] ?? '',
                    'sellerId': data['sellerId'] ?? '',
                    'timestamp': data['createdAt'] ?? Timestamp.now(),
                  };
                } catch (e) {
                  debugPrint('Error parsing product ${doc.id}: $e');
                  return {};
                }
              })
              .where((product) => product.isNotEmpty)
              .toList()
          as FutureOr<List<Map<String, dynamic>>>?,
    );
  }

  Future<void> _fetchCartCount([Source source = Source.server]) async {
    if (_auth.currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get(GetOptions(source: source));

      if (mounted) {
        setState(() => _cartCount = doc.size);
      }
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to add items to cart');
      return;
    }

    try {
      setState(() => _cartCount++);

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

      _showSuccessToast('${product['name']} added to cart');
    } catch (e) {
      setState(() => _cartCount--);
      debugPrint('Error adding to cart: $e');
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
      debugPrint('Error toggling saved product: $e');
      _showErrorToast('Failed to update saved status');
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await Future.wait([
        _firestore
            .collection('products')
            .where('approved', isEqualTo: true)
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get(),
        _firestore
            .collection('categories')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get(),
      ]);

      final combinedResults = [
        ...results[0].docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'No Name',
            'type': 'product',
            'price': (data['price'] as num?)?.toDouble() ?? 0.0,
            'image':
                (data['images'] is List && data['images'].isNotEmpty)
                    ? data['images'][0]
                    : '',
          };
        }),
        ...results[1].docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'No Name',
            'type': 'category',
            'imageUrl': data['imageUrl'] ?? '',
          };
        }),
      ];

      setState(() {
        _searchResults = combinedResults;
      });
    } catch (e) {
      debugPrint('Error searching: $e');
      _showErrorToast('Failed to perform search');
    }
  }

  void _navigateToSearchResult(Map<String, dynamic> result) {
    if (result['type'] == 'product') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProductDetailsPage(
                product: {
                  'id': result['id'],
                  'name': result['name'],
                  'price': result['price'],
                  'image': result['image'],
                },
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProductFeed(
                categoryId: result['id'],
                categoryName: result['name'],
              ),
        ),
      );
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
                  fontSize: 16,
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
          height: 220,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ),
      );
    }

    if (_carouselImages.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Center(
          child: Text(
            'No carousel images available',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: _carouselImages.length,
            options: CarouselOptions(
              height: 220,
              autoPlay: true,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              onPageChanged: (index, _) {
                setState(() => _currentCarouselIndex = index);
              },
            ),
            itemBuilder: (context, index, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: _carouselImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder:
                        (_, __) =>
                            Container(color: Colors.white.withOpacity(0.1)),
                    errorWidget:
                        (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.1),
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                  ),
                ),
              );
            },
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
                        border: Border.all(color: Colors.orange, width: 2),
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

    if (_categories.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'No categories found',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
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
                      border: Border.all(color: Colors.orange, width: 2),
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

  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 170,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Card(
                      color: const Color(0xFF1A3A6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                ),
                TextButton(
                  onPressed: _fetchInitialProducts,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_products[index]);
          },
        ),
      ),
    );
  }

  Widget _buildSponsoredProductsList() {
    if (_isLoadingProducts) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 2,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 170,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Card(
                      color: const Color(0xFF1A3A6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (_sponsoredProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _sponsoredProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_sponsoredProducts[index]);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 170,
        child: Card(
          color: const Color(0xFF1A3A6A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange, width: 2),
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
                        height: 140,
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
                      padding: const EdgeInsets.all(10),
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
                          const SizedBox(height: 6),
                          Text(
                            '₦${product['price'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No results found',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = _searchResults[index];
        return Card(
          color: const Color(0xFF1A3A6A),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange, width: 2),
          ),
          child: ListTile(
            leading:
                item['type'] == 'product'
                    ? CachedNetworkImage(
                      imageUrl: item['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) =>
                              Container(color: Colors.white.withOpacity(0.1)),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(Icons.error, color: Colors.white),
                          ),
                    )
                    : CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) =>
                              Container(color: Colors.white.withOpacity(0.1)),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(
                              Icons.category,
                              color: Colors.white,
                            ),
                          ),
                    ),
            title: Text(
              item['name'],
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              item['type'] == 'product'
                  ? '₦${item['price'].toStringAsFixed(2)}'
                  : 'Category',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => _navigateToSearchResult(item),
          ),
        );
      }, childCount: _searchResults.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      body: IndexedStack(index: _currentIndex, children: _screens),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>()!;

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
            border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
          ),
          child: TextField(
            controller: state._searchController,
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
            icon: const Icon(Icons.notifications, color: Colors.white),
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
              if (state._cartCount > 0)
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
                      '${state._cartCount}',
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
        onRefresh: state._initializeData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (state._isSearching)
              state._buildSearchResults()
            else ...[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    state._buildSectionHeader(
                      icon: Icons.location_on,
                      title: 'Nearby Products & Stores',
                      onSeeAll: () {},
                    ),
                    state._buildImageCarousel(),
                    state._buildSectionHeader(
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
                    state._buildCategories(),
                    state._buildSectionHeader(
                      title: 'Trending Products',
                      onSeeAll: () {},
                    ),
                  ],
                ),
              ),
              state._buildProductsList(),
              SliverToBoxAdapter(
                child: state._buildSectionHeader(
                  title: 'Sponsored',
                  onSeeAll: () {},
                ),
              ),
              state._buildSponsoredProductsList(),
              SliverToBoxAdapter(
                child: state._buildSectionHeader(
                  title: 'Top Sellers',
                  onSeeAll: () {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
    );
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
