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
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Location _location = Location();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

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
  bool _hasMoreProducts = true;
  DocumentSnapshot? _lastProductDocument;
  bool _isFetchingMore = false;
  int _currentIndex = 0;

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
    _setupScrollListener();
  }

  Future<void> _initializeData() async {
    // First try to load from cache
    await _fetchInitialDataFromCache();

    // Then fetch fresh data
    await _fetchInitialDataFromServer();
  }

  Future<void> _fetchInitialDataFromCache() async {
    try {
      await Future.wait([
        _fetchCarouselImages(Source.cache),
        _fetchCategories(Source.cache),
        _fetchInitialProducts(Source.cache),
        _fetchCartCount(Source.cache),
      ]);
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _fetchInitialDataFromServer() async {
    try {
      await Future.wait([
        _fetchCarouselImages(Source.server),
        _fetchCategories(Source.server),
        _fetchInitialProducts(Source.server),
        _fetchCartCount(Source.server),
        _getCurrentLocation(),
      ]);
    } catch (e) {
      debugPrint('Error loading from server: $e');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMore &&
          _hasMoreProducts) {
        _fetchMoreProducts();
      }
    });
  }

  Future<void> _fetchInitialProducts([Source source = Source.server]) async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none &&
          source == Source.server) {
        if (mounted) {
          _showErrorToast('No internet connection');
          setState(() => _isLoadingProducts = false);
        }
        return;
      }

      final query = _firestore
          .collection('products')
          .where('approved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10);

      final snapshot = await query.get(GetOptions(source: source));

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
          });
        }
        return;
      }

      _lastProductDocument = snapshot.docs.last;

      final products = await _parseProductDocuments(snapshot.docs);

      if (mounted) {
        setState(() {
          _products = products.where((p) => !p['sponsored']).toList();
          _sponsoredProducts = products.where((p) => p['sponsored']).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching products: $e\n$stackTrace');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        if (source == Source.server) {
          _showErrorToast('Failed to load products');
        }
      }
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMoreProducts || _lastProductDocument == null)
      return;

    if (!mounted) return;
    setState(() => _isFetchingMore = true);

    try {
      final query = _firestore
          .collection('products')
          .where('approved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastProductDocument!)
          .limit(10);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() => _hasMoreProducts = false);
        }
        return;
      }

      _lastProductDocument = snapshot.docs.last;

      final newProducts = await _parseProductDocuments(snapshot.docs);

      if (mounted && newProducts.isNotEmpty) {
        setState(() {
          _products.addAll(newProducts.where((p) => !p['sponsored']));
          _sponsoredProducts.addAll(newProducts.where((p) => p['sponsored']));
          _isFetchingMore = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching more products: $e\n$stackTrace');
      if (mounted) {
        setState(() => _isFetchingMore = false);
        _showErrorToast('Failed to load more products');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _parseProductDocuments(
    List<DocumentSnapshot> docs,
  ) async {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'price': (data['price'] as num?)?.toDouble() ?? 0.0,
        'image':
            data['imageUrls'] is List && data['imageUrls'].isNotEmpty
                ? data['imageUrls'][0]
                : '',
        'stock': data['stock'] ?? 0,
        'sponsored': data['sponsored'] ?? false,
        'description': data['description'] ?? '',
        'category': data['category'] ?? '',
        'sellerId': data['sellerId'] ?? '',
        'timestamp': data['createdAt'] ?? Timestamp.now(),
      };
    }).toList();
  }

  Future<void> _fetchCategories([Source source = Source.server]) async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

    try {
      final snapshot = await _firestore
          .collection('categories')
          .limit(6)
          .get(GetOptions(source: source));

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
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        if (source == Source.server) {
          _showErrorToast('Failed to load categories');
        }
      }
    }
  }

  Future<void> _fetchCarouselImages([Source source = Source.server]) async {
    if (!mounted) return;
    setState(() => _isLoadingCarousel = true);

    try {
      final snapshot = await _firestore
          .collection('carouselImages')
          .get(GetOptions(source: source));

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
      debugPrint('Error fetching carousel images: $e');
      if (mounted) {
        setState(() => _isLoadingCarousel = false);
        if (source == Source.server) {
          _showErrorToast('Failed to load carousel images');
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        final enabled = await _location.requestService();
        if (!enabled) return;
      }

      var permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() => _currentLocation = locationData);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
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
        _showSuccessToast('${product['name']} added to cart');
      }
    } catch (e) {
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
    final remaining = _flashSaleEnd.difference(DateTime.now());
    return '${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
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
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: _carouselImages.length,
            options: CarouselOptions(
              height: 180,
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _carouselImages[index],
                    fit: BoxFit.cover,
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
                color: Color(0xFFFB8C00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return SliverToBoxAdapter(
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
    );
  }

  Widget _buildSponsoredProductsList() {
    if (_isLoadingProducts) {
      return SliverToBoxAdapter(
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
      );
    }

    if (_sponsoredProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
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
        itemCount: 3,
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
                      child: const Icon(Icons.person, color: Colors.white),
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
        itemCount: 3,
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
                          child: const Center(
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
                        const url = 'https://blorb.vercel.app';
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
    _scrollController.dispose();
    super.dispose();
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
        key: state._refreshIndicatorKey,
        onRefresh: state._initializeData,
        child: CustomScrollView(
          controller: state._scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  state._buildSectionHeader(
                    icon: Icons.location_on,
                    title: 'Nearby Products & Stores',
                    subtitle:
                        state._currentLocation != null
                            ? 'Lat: ${state._currentLocation!.latitude!.toStringAsFixed(4)}, Long: ${state._currentLocation!.longitude!.toStringAsFixed(4)}'
                            : null,
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
                  state._buildFlashSaleBanner(),
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
            SliverToBoxAdapter(child: state._buildTopSellers()),
            SliverToBoxAdapter(
              child: state._buildSectionHeader(
                title: 'Official Stores',
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(child: state._buildOfficialStores()),
            SliverToBoxAdapter(
              child:
                  state._isFetchingMore
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
        onPressed: () => state._showBecomeSellerDialog(context),
        child: const Icon(Icons.store, color: Colors.white),
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
