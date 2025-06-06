import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends StatefulWidget {
  final Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  int _cartItemCount = 0;
  String _userName = '';
  int _currentCarouselIndex = 0;
  late PageController _carouselController;
  List<String> _savedItems = [];
  Timer? _carouselTimer;
  List<String> _carouselImages = [];
  List<DocumentSnapshot> _categories = [];
  List<DocumentSnapshot> _products = [];
  List<DocumentSnapshot> _recentProducts = [];
  List<DocumentSnapshot> _topSellers = [];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(initialPage: 0);
    _loadUserData();
    _loadCartCount();
    _loadSavedItems();
    _loadCarouselImages();
    _loadCategories();
    _loadProducts();
    _loadRecentProducts();
    _loadTopSellers();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselController.hasClients && _carouselImages.isNotEmpty) {
        final nextPage = (_currentCarouselIndex + 1) % _carouselImages.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadCarouselImages() async {
    try {
      final snapshot = await _firestore.collection('carouselImages').get();
      setState(() {
        _carouselImages =
            snapshot.docs.map((doc) => doc.get('imageurl') as String).toList();
      });
      if (_carouselImages.isNotEmpty) {
        _startCarouselAutoScroll();
      }
    } catch (e) {
      _showErrorToast('Failed to load carousel images');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      setState(() {
        _categories = snapshot.docs;
      });
    } catch (e) {
      _showErrorToast('Failed to load categories');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestore.collection('products').limit(8).get();
      setState(() {
        _products = snapshot.docs;
      });
    } catch (e) {
      _showErrorToast('Failed to load products');
    }
  }

  Future<void> _loadRecentProducts() async {
    try {
      final snapshot =
          await _firestore
              .collection('products')
              .orderBy('createdAt', descending: true)
              .limit(4)
              .get();
      setState(() {
        _recentProducts = snapshot.docs;
      });
    } catch (e) {
      _showErrorToast('Failed to load recent products');
    }
  }

  Future<void> _loadTopSellers() async {
    try {
      final snapshot =
          await _firestore
              .collection('products')
              .orderBy(
                'stock',
                descending: false,
              ) // Assuming low stock means popular
              .limit(4)
              .get();
      setState(() {
        _topSellers = snapshot.docs;
      });
    } catch (e) {
      _showErrorToast('Failed to load top sellers');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userName = doc.get('firstName') ?? '';
          });
        }
      }
    } catch (e) {
      _showErrorToast('Failed to load user data');
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('carts').doc(user.uid).get();
        if (doc.exists) {
          final items = doc.data()?['items'] ?? [];
          setState(() {
            _cartItemCount = items.length;
          });
        }
      }
    } catch (e) {
      _showErrorToast('Failed to load cart items');
    }
  }

  Future<void> _loadSavedItems() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('savedItems').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _savedItems = List<String>.from(doc.get('items') ?? []);
          });
        }
      }
    } catch (e) {
      _showErrorToast('Failed to load saved items');
    }
  }

  Future<void> _toggleSaveItem(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('savedItems').doc(user.uid);

        if (_savedItems.contains(productId)) {
          await docRef.update({
            'items': FieldValue.arrayRemove([productId]),
          });
          setState(() {
            _savedItems.remove(productId);
          });
          _showSuccessToast('Item removed from saved');
        } else {
          await docRef.set({
            'items': FieldValue.arrayUnion([productId]),
          }, SetOptions(merge: true));
          setState(() {
            _savedItems.add(productId);
          });
          _showSuccessToast('Item saved for later');
        }
      }
    } catch (e) {
      _showErrorToast('Failed to update saved items');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(
        'Error',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      autoCloseDuration: const Duration(seconds: 5),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      backgroundColor: Colors.red[700],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(color: Colors.white),
      closeButtonShowType: CloseButtonShowType.always,
    );
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(
        'Success',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      autoCloseDuration: const Duration(seconds: 5),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(color: Colors.white),
      closeButtonShowType: CloseButtonShowType.always,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(child: _buildAppBar(theme, isDarkMode)),
            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar(theme, isDarkMode)),
            // Carousel Section
            SliverToBoxAdapter(child: _buildCarouselSection(theme, isDarkMode)),
            // Categories Section
            SliverToBoxAdapter(
              child: _buildCategoriesSection(theme, isDarkMode),
            ),
            // Recently Added Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Recently Added', theme, isDarkMode),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalProducts(
                _recentProducts,
                theme,
                isDarkMode,
              ),
            ),
            // Top Sellers Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Top Sellers', theme, isDarkMode),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalProducts(_topSellers, theme, isDarkMode),
            ),
            // Featured Products Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Featured Products', theme, isDarkMode),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildProductsGrid(_products, theme, isDarkMode),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userName.isNotEmpty ? _userName : 'Welcome',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Badge(
                  backgroundColor: const Color(0xFF004aad),
                  label: Text(
                    '$_cartItemCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                  isLabelVisible: _cartItemCount > 0,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onPressed: () {
                  widget.onTabChange(3); // Navigate to cart
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // Handle notification
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            hintText: 'Search products...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onSubmitted: (value) {
            // Handle search
          },
        ),
      ),
    );
  }

  Widget _buildCarouselSection(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child:
              _carouselImages.isEmpty
                  ? _buildCarouselShimmer()
                  : PageView.builder(
                    controller: _carouselController,
                    itemCount: _carouselImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _carouselImages[index],
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 12),
        _carouselImages.isEmpty
            ? const SizedBox()
            : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_carouselImages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentCarouselIndex == index
                            ? const Color(0xFF004aad)
                            : (isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[300]),
                  ),
                );
              }),
            ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCarouselShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all categories page
                  widget.onTabChange(
                    4,
                  ); // Assuming 4 is the categories page index
                },
                child: Text(
                  'See All',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF004aad),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child:
                _categories.isEmpty
                    ? _buildCategoriesShimmer()
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to category products page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CategoryProductsPage(
                                      categoryId: category.id,
                                      categoryName: category.get('name'),
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(
                              right: index == _categories.length - 1 ? 0 : 16,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: category.get('imageUrl'),
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                            child: const Icon(Icons.error),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.get('name'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoriesShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 80,
          margin: EdgeInsets.only(right: index == 4 ? 0 : 16),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 60, height: 12, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildHorizontalProducts(
    List<DocumentSnapshot> products,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return SizedBox(
      height: 220,
      child:
          products.isEmpty
              ? _buildProductsShimmer(isHorizontal: true)
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(
                    product,
                    theme,
                    isDarkMode,
                    isHorizontal: true,
                  );
                },
              ),
    );
  }

  SliverGrid _buildProductsGrid(
    List<DocumentSnapshot> products,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return products.isEmpty
            ? _buildProductShimmer()
            : _buildProductCard(products[index], theme, isDarkMode);
      }, childCount: products.isEmpty ? 4 : products.length),
    );
  }

  Widget _buildProductCard(
    DocumentSnapshot product,
    ThemeData theme,
    bool isDarkMode, {
    bool isHorizontal = false,
  }) {
    final productId = product.id;
    final hasDiscount =
        product.get('discountPrice') != null &&
        product.get('discountPrice') < product.get('price');
    final isSaved = _savedItems.contains(productId);
    final images = List<String>.from(product.get('images') ?? []);
    final firstImage = images.isNotEmpty ? images[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: productId),
          ),
        );
      },
      child: Container(
        width: isHorizontal ? 160 : null,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: firstImage,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFff914d),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(((product.get('price') - product.get('discountPrice')) / product.get('price') * 100).toStringAsFixed(0))}% OFF',
                        style: const TextStyle(
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
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      _toggleSaveItem(productId);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.get('name'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.get('brandName'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.get('discountPrice')?.toStringAsFixed(2) ?? product.get('price').toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004aad),
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '\$${product.get('price').toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color:
                                  isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsShimmer({bool isHorizontal = false}) {
    return isHorizontal
        ? ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              width: 160,
              margin: EdgeInsets.only(left: 16, right: index == 3 ? 16 : 0),
              child: _buildProductShimmer(),
            );
          },
        )
        : MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 4,
          itemBuilder: (context, index) {
            return _buildProductShimmer();
          },
        );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: widget.onTabChange,
      selectedItemColor: const Color(0xFF004aad),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_rounded),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_rounded),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Placeholder for category products page
class CategoryProductsPage extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: Center(child: Text('Products for $categoryName')),
    );
  }
}

// Placeholder for product details page
class ProductDetailsPage extends StatelessWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Product Details for $productId')),
    );
  }
}
