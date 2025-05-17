// ignore: unused_import
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
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  List<String> _carouselImages = [];
  bool _isLoadingCarousel = true;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _sponsoredProducts = [];
  int _currentCarouselIndex = 0;
  int _cartCount = 0;
  int _currentIndex = 0;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

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
    _loadInitialData();
    _setupAuthListener();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCarouselImages(),
      _fetchCategories(),
      _fetchInitialProducts(),
    ]);
    if (_auth.currentUser != null) _fetchCartCount();
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

  Future<void> _fetchCarouselImages() async {
    if (_cachedCarouselImages != null) {
      setState(() {
        _carouselImages = _cachedCarouselImages!;
        _isLoadingCarousel = false;
      });
      return;
    }

    setState(() => _isLoadingCarousel = true);

    try {
      final snapshot = await _firestore.collection('carouselImages').get();
      final images =
          snapshot.docs
              .where((doc) => doc.exists && doc.data().containsKey('imageurl'))
              .map((doc) => doc['imageurl'] as String)
              .toList();

      _cachedCarouselImages = images;
      setState(() {
        _carouselImages = images;
        _isLoadingCarousel = false;
      });
    } catch (e) {
      setState(() => _isLoadingCarousel = false);
    }
  }

  Future<void> _fetchCategories() async {
    if (_cachedCategories != null) {
      setState(() {
        _categories = _cachedCategories!;
        _isLoadingCategories = false;
      });
      return;
    }

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

      _cachedCategories = categories;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchInitialProducts() async {
    if (_cachedProducts != null && _cachedSponsoredProducts != null) {
      setState(() {
        _products = _cachedProducts!;
        _sponsoredProducts = _cachedSponsoredProducts!;
        _isLoadingProducts = false;
      });
      return;
    }

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

      _cachedProducts = products.where((p) => !p['sponsored']).toList();
      _cachedSponsoredProducts = products.where((p) => p['sponsored']).toList();

      setState(() {
        _products = _cachedProducts!;
        _sponsoredProducts = _cachedSponsoredProducts!;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<List<Map<String, dynamic>>> _parseProductDocuments(
    List<DocumentSnapshot> docs,
  ) async {
    return docs.map((doc) {
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
    }).toList();
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
        setState(() => _cartCount = doc.size);
      }
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
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

    setState(() => _isSearching = true);

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

      setState(() {
        _searchResults = [
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
      });
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  // ignore: unused_element
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
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _carouselImages.length,
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            viewportFraction: 0.95,
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
        color: const Color(0xFF0A1E3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FLASH SALES',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'Ends in 17h : 38m : 49s',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Up to 80% Off',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: product['image'],
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
          const SizedBox(height: 8),
          Text(
            product['name'],
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '₦${product['price'].toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '42 items left',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return SizedBox(
        height: 200,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 16, width: 120, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 14, width: 80, color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    if (_products.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No products found',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ProductDetailsPage(product: _products[index]),
                ),
              );
            },
            child: _buildProductCard(_products[index]),
          );
        },
      ),
    );
  }

  Widget _buildSponsoredProductsList() {
    if (_isLoadingProducts) {
      return const SizedBox.shrink();
    }

    if (_sponsoredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _sponsoredProducts.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProductDetailsPage(
                        product: _sponsoredProducts[index],
                      ),
                ),
              );
            },
            child: _buildProductCard(_sponsoredProducts[index]),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return Card(
          color: const Color(0xFF1A3A6A),
          margin: const EdgeInsets.only(bottom: 16),
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
            onTap: () {
              if (item['type'] == 'product') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailsPage(
                          product: {
                            'id': item['id'],
                            'name': item['name'],
                            'price': item['price'],
                            'image': item['image'],
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
                          categoryId: item['id'],
                          categoryName: item['name'],
                        ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A1E3D),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
            border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
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
      body:
          state._isSearching
              ? state._buildSearchResults()
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MAKE UP SALE Banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MAKE UP SALE',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Elevate your Look',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UP TO 25% OFF',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TAGS Apply
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'TAGS Apply',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Awoof of the Month
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1E3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Awoof of the Month',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appliances',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to 80% Off',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phones & Tablets',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Flash Sales
                    state._buildFlashSaleBanner(),

                    // Accelerator
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1E3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Accelerator',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-50%',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-50%',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Categories',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    state._buildCategories(),
                    const SizedBox(height: 24),

                    // Trending Products
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Trending Products',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'See all',
                              style: GoogleFonts.poppins(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    state._buildProductsList(),
                    const SizedBox(height: 24),

                    // Sponsored Products
                    if (state._sponsoredProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Sponsored',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'See all',
                                style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      state._buildSponsoredProductsList(),
                      const SizedBox(height: 24),
                    ],

                    // Sample product listings
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductListing(
                            'Alpods Pro2 Wireless St...',
                            '₦5,045',
                            '42 items left',
                          ),
                          const SizedBox(height: 16),
                          _buildProductListing(
                            'AM + PM Facial Moisturiz...',
                            '₦6,999',
                            '43 items left',
                          ),
                          const SizedBox(height: 16),
                          _buildProductListing(
                            'Nordic Simple',
                            '₦3,900',
                            '1 item left',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }

  Widget _buildProductListing(String name, String price, String stock) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, color: Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          stock,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
