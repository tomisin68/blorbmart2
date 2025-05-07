import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:blorbmart2/Screens/product_details.dart';
import 'package:blorbmart2/Screens/product_feed.dart';
import 'package:blorbmart2/Screens/profile.dart';
import 'package:blorbmart2/bottom_nav.dart';
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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const SavedPage(),
    const ProductFeed(),
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

  List<String> _carouselImages = [];
  bool _isLoading = true;
  int _currentCarouselIndex = 0;
  int _cartCount = 0;
  LocationData? _currentLocation;

  // Updated with real Unsplash URLs
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Appliances',
      'icon': Icons.kitchen,
      'image': 'https://images.unsplash.com/photo-1586449480533-bf4d8f579e6e',
    },
    {
      'name': 'Clothes',
      'icon': Icons.shopping_bag,
      'image': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f',
    },
    {
      'name': 'Books',
      'icon': Icons.menu_book,
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    },
    {
      'name': 'Cosmetics',
      'icon': Icons.spa,
      'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
    },
    {
      'name': 'Gadgets',
      'icon': Icons.phone_iphone,
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c',
    },
    {
      'name': 'Furniture',
      'icon': Icons.chair,
      'image': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc',
    },
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'name': '6L Air Fryer',
      'price': 45000,
      'stock': 5,
      'image': 'https://images.unsplash.com/photo-1618442302325-8b5f8e3a3b0d',
      'sponsored': false,
    },
    {
      'name': 'Bluetooth Headphones',
      'price': 25000,
      'stock': 12,
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
      'sponsored': false,
    },
    {
      'name': 'Ankara T-Shirt',
      'price': 8000,
      'stock': 8,
      'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab',
      'sponsored': true,
    },
    {
      'name': 'Programming Book',
      'price': 15000,
      'stock': 3,
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
      'sponsored': false,
    },
    {
      'name': 'Smart Watch',
      'price': 35000,
      'stock': 7,
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
      'sponsored': true,
    },
    {
      'name': 'Wireless Charger',
      'price': 12000,
      'stock': 15,
      'image': 'https://images.unsplash.com/photo-1583394838336-acd977736f90',
      'sponsored': false,
    },
  ];

  final List<Map<String, dynamic>> _topSellers = [
    {
      'name': 'TechGadgetsNG',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c',
    },
    {
      'name': 'FashionHubNG',
      'rating': 4.6,
      'image': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f',
    },
    {
      'name': 'BookWormNG',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    },
  ];

  final List<Map<String, dynamic>> _officialStores = [
    {
      'name': 'Royal Perfume Store',
      'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
    },
    {
      'name': "Dhemhi's Glam Store",
      'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e',
    },
    {
      'name': 'Lagos Tech Hub',
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c',
    },
  ];

  final DateTime _flashSaleEnd = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _fetchCarouselImages();
    _fetchCartCount();
    _getCurrentLocation();
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
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      _showErrorToast('Failed to get location');
    }
  }

  Future<void> _fetchCarouselImages() async {
    try {
      final querySnapshot = await _firestore.collection('carouselImages').get();
      final images =
          querySnapshot.docs
              .map((doc) => doc.data()['imageurl'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

      setState(() {
        _carouselImages =
            images.isNotEmpty
                ? images
                : [
                  'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
                  'https://images.unsplash.com/photo-1556740714-a8395b3bf30f',
                  'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
                  'https://images.unsplash.com/photo-1556740714-a8395b3bf30f',
                ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _carouselImages = [
          'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
          'https://images.unsplash.com/photo-1556740714-a8395b3bf30f',
          'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
          'https://images.unsplash.com/photo-1556740714-a8395b3bf30f',
        ];
        _isLoading = false;
      });
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
      setState(() {
        _cartCount = doc.size;
      });
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
          .doc(product['name'].replaceAll(' ', '_'))
          .set({
            'name': product['name'],
            'price': product['price'],
            'image': product['image'],
            'quantity': 1,
            'addedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _cartCount++);
      _showSuccessToast('${product['name']} added to cart');
    } catch (e) {
      _showErrorToast('Failed to add to cart');
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
        onRefresh: () async {
          await Future.wait([
            _fetchCarouselImages(),
            _fetchCartCount(),
            _getCurrentLocation(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
              _isLoading ? _buildCarouselShimmer() : _buildImageCarousel(),

              // Categories section
              _buildSectionHeader(title: 'Categories', onSeeAll: () {}),
              _buildCategories(),

              // Flash sale banner
              _buildFlashSaleBanner(),

              // Products section
              _buildSectionHeader(title: 'Trending Products', onSeeAll: () {}),
              _buildProductList(false),

              // Sponsored products section
              _buildSectionHeader(title: 'Sponsored', onSeeAll: () {}),
              _buildProductList(true),

              // Top sellers section
              _buildSectionHeader(title: 'Top Sellers', onSeeAll: () {}),
              _buildTopSellers(),

              // Official stores section
              _buildSectionHeader(title: 'Official Stores', onSeeAll: () {}),
              _buildOfficialStores(),

              const SizedBox(height: 20),
            ],
          ),
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
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _categories[index]['icon'],
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _categories[index]['name'],
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
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

  Widget _buildProductList(bool sponsored) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          if (_products[index]['sponsored'] != sponsored) {
            return const SizedBox.shrink();
          }
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 150,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SizedBox(
                        height: 100,
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
                        '₦${product['price'].toString()}',
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
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
        itemCount: _topSellers.length,
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
                      backgroundImage: CachedNetworkImageProvider(
                        _topSellers[index]['image'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _topSellers[index]['name'],
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(
                      _topSellers[index]['rating'].toString(),
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
        itemCount: _officialStores.length,
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
                        child: CachedNetworkImage(
                          imageUrl: _officialStores[index]['image'],
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
                      child: Text(
                        _officialStores[index]['name'],
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

  Widget _buildCarouselShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.2),
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
        ),
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
    super.dispose();
  }
}
