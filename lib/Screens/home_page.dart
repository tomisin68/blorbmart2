// ignore_for_file: unused_import, duplicate_ignore

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
// ignore: unused_import
import 'package:intl/intl.dart';
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
  // ignore: unused_field
  int _cartCount = 0;
  LocationData? _currentLocation;

  // Updated categories with proper Nigerian product images
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Appliances',
      'icon': Icons.kitchen,
      'image': 'https://i.imgur.com/JQJxZ4A.jpg', // Nigerian home appliance
    },
    {
      'name': 'Clothes',
      'icon': Icons.shopping_bag,
      'image': 'https://i.imgur.com/5XJQJxZ.jpg', // Nigerian fashion
    },
    {
      'name': 'Books',
      'icon': Icons.menu_book,
      'image': 'https://i.imgur.com/3XJQJxZ.jpg', // Nigerian books
    },
    {
      'name': 'Cosmetics',
      'icon': Icons.spa,
      'image': 'https://i.imgur.com/7XJQJxZ.jpg', // Nigerian beauty products
    },
    {
      'name': 'Gadgets',
      'icon': Icons.phone_iphone,
      'image': 'https://i.imgur.com/9XJQJxZ.jpg', // Nigerian tech gadgets
    },
    {
      'name': 'Furniture',
      'icon': Icons.chair,
      'image': 'https://i.imgur.com/1XJQJxZ.jpg', // Nigerian furniture
    },
  ];

  // Updated products with Nigerian prices in Naira and proper images
  final List<Map<String, dynamic>> _products = [
    {
      'name': '6L Extra Large Capacity Air Fryer',
      'price': 45000, // in Naira
      'stock': 5,
      'image': 'https://i.imgur.com/JQJxZ4A.jpg',
      'sponsored': false,
    },
    {
      'name': 'Wireless Bluetooth Headphones',
      'price': 25000, // in Naira
      'stock': 12,
      'image': 'https://i.imgur.com/5XJQJxZ.jpg',
      'sponsored': false,
    },
    {
      'name': 'Ankara Cotton T-Shirt',
      'price': 8000, // in Naira
      'stock': 8,
      'image': 'https://i.imgur.com/3XJQJxZ.jpg',
      'sponsored': true,
    },
    {
      'name': 'Programming Textbook',
      'price': 15000, // in Naira
      'stock': 3,
      'image': 'https://i.imgur.com/7XJQJxZ.jpg',
      'sponsored': false,
    },
    {
      'name': 'Smart Watch',
      'price': 35000, // in Naira
      'stock': 7,
      'image': 'https://i.imgur.com/9XJQJxZ.jpg',
      'sponsored': true,
    },
    {
      'name': 'Wireless Charging Pad',
      'price': 12000, // in Naira
      'stock': 15,
      'image': 'https://i.imgur.com/1XJQJxZ.jpg',
      'sponsored': false,
    },
    {
      'name': 'Leather Wallet',
      'price': 10000, // in Naira
      'stock': 6,
      'image': 'https://i.imgur.com/2XJQJxZ.jpg',
      'sponsored': false,
    },
    {
      'name': 'Bluetooth Speaker',
      'price': 20000, // in Naira
      'stock': 4,
      'image': 'https://i.imgur.com/4XJQJxZ.jpg',
      'sponsored': true,
    },
  ];

  // Updated top sellers with Nigerian stores
  final List<Map<String, dynamic>> _topSellers = [
    {
      'name': 'TechGadgetsNG',
      'rating': 4.8,
      'image': 'https://i.imgur.com/9XJQJxZ.jpg',
    },
    {
      'name': 'FashionHubNG',
      'rating': 4.6,
      'image': 'https://i.imgur.com/5XJQJxZ.jpg',
    },
    {
      'name': 'BookWormNG',
      'rating': 4.9,
      'image': 'https://i.imgur.com/7XJQJxZ.jpg',
    },
  ];

  // Updated official stores with Nigerian stores
  final List<Map<String, dynamic>> _officialStores = [
    {
      'name': 'Royal Elegance Perfume Store',
      'image': 'https://i.imgur.com/8XJQJxZ.jpg',
    },
    {'name': "Dhemhi's Glam Store", 'image': 'https://i.imgur.com/6XJQJxZ.jpg'},
    {'name': 'Lagos Tech Hub', 'image': 'https://i.imgur.com/9XJQJxZ.jpg'},
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
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      _showErrorToast('Failed to get location: ${e.toString()}');
    }
  }

  Future<void> _fetchCarouselImages() async {
    try {
      final querySnapshot = await _firestore.collection('carouselImages').get();
      final images =
          querySnapshot.docs
              .map((doc) {
                // Assuming each document has fields image1, image2, etc.
                // Or if they're separate documents with an 'imageurl' field
                return doc.data()['imageurl'] as String? ?? '';
              })
              .where((url) => url.isNotEmpty)
              .toList();

      // Fallback to default images if no images are fetched
      if (images.isEmpty) {
        setState(() {
          _carouselImages = [
            'https://i.imgur.com/JQJxZ4A.jpg',
            'https://i.imgur.com/5XJQJxZ.jpg',
            'https://i.imgur.com/7XJQJxZ.jpg',
            'https://i.imgur.com/9XJQJxZ.jpg',
          ];
          _isLoading = false;
        });
      } else {
        setState(() {
          _carouselImages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _carouselImages = [
          'https://i.imgur.com/JQJxZ4A.jpg',
          'https://i.imgur.com/5XJQJxZ.jpg',
          'https://i.imgur.com/7XJQJxZ.jpg',
          'https://i.imgur.com/9XJQJxZ.jpg',
        ];
        _isLoading = false;
      });
      _showErrorToast('Using default carousel images');
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
      if (mounted) {
        _showErrorToast('Failed to load cart count');
      }
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

      setState(() {
        _cartCount++;
      });

      _showSuccessToast('${product['name']} added to cart');
    } catch (e) {
      _showErrorToast('Failed to add to cart');
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
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
              // Nearby feeds section with location info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.orange),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Products & Stores',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentLocation != null)
                          Text(
                            'Lat: ${_currentLocation!.latitude!.toStringAsFixed(4)}, Long: ${_currentLocation!.longitude!.toStringAsFixed(4)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all feeds page
                      },
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
              ),

              // Carousel slider
              _isLoading
                  ? _buildCarouselShimmer()
                  : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.9,
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                          ),
                          items:
                              _carouselImages.map((imageUrl) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1A3A6A),
                                            Color(0xFF0A1E3D),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    child: const Icon(
                                                      Icons.error,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    );
                                  },
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
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
                  ),

              // Rest of your existing widgets...
              // Categories section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Categories',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all categories page
                      },
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
              ),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Navigate to category page
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726),
                                    Color(0xFFFB8C00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _categories[index]['icon'],
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _categories[index]['name'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Flash sale banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Up to 50% off',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                      onPressed: () {
                        // Navigate to flash sale products
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
              ),

              // Products section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Trending Products',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all products page
                      },
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
              ),

              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    if (_products[index]['sponsored']) {
                      return const SizedBox.shrink();
                    }
                    return _buildProductCard(_products[index]);
                  },
                ),
              ),

              // Sponsored products section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Sponsored',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all sponsored products
                      },
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
              ),

              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    if (!_products[index]['sponsored']) {
                      return const SizedBox.shrink();
                    }
                    return _buildProductCard(_products[index]);
                  },
                ),
              ),

              // Top sellers section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Top Sellers',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all top sellers
                      },
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
              ),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _topSellers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Navigate to seller's store
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726),
                                    Color(0xFFFB8C00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundImage: CachedNetworkImageProvider(
                                    _topSellers[index]['image'],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _topSellers[index]['name'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
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
                      ),
                    );
                  },
                ),
              ),

              // Official stores section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Official Stores',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all official stores
                      },
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
              ),

              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _officialStores.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Navigate to official store
                        },
                        child: Container(
                          width: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A3A6A), Color(0xFF0A1E3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: _officialStores[index]['image'],
                                  height: 110,
                                  width: 220,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.error,
                                        color: Colors.white,
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
              ),

              const SizedBox(height: 80), // Extra space for bottom nav bar
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          _showBecomeSellerDialog(context);
        },
        child: const Icon(Icons.store, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(product: product),
            ),
          );
        },
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A6A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product['image'],
                      height: 120,
                      width: 160,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              Container(color: Colors.white.withOpacity(0.1)),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.error, color: Colors.white),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: Colors.white),
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
                    Text(
                      '${product['stock']} left',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }

  Widget _buildCarouselShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.2),
        child: Container(
          height: 200,
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
                    imageUrl: 'https://i.imgur.com/JQJxZ4A.jpg',
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
