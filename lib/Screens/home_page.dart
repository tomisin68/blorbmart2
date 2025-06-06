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

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(initialPage: 0);
    _loadUserData();
    _loadCartCount();
    _loadSavedItems();
    // Auto-scroll carousel
    _startCarouselAutoScroll();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startCarouselAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_carouselController.hasClients) {
        final nextPage = _currentCarouselIndex + 1;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startCarouselAutoScroll();
      }
    });
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              _buildAppBar(theme, isDarkMode),
              const SizedBox(height: 16),
              // Search Bar
              _buildSearchBar(theme, isDarkMode),
              const SizedBox(height: 24),
              // Carousel Section
              _buildCarouselSection(theme, isDarkMode),
              const SizedBox(height: 24),
              // Categories Section
              _buildCategoriesSection(theme, isDarkMode),
              const SizedBox(height: 24),
              // Products Section
              _buildProductsSection(theme, isDarkMode),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('carouselImages').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCarouselShimmer();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load carousel',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No carousel images found',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              final images =
                  snapshot.data!.docs
                      .map((doc) => doc.get('imageurl') as String)
                      .toList();

              return PageView.builder(
                controller: _carouselController,
                itemCount: images.length,
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
                        imageUrl: images[index],
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('carouselImages').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }
            final itemCount = snapshot.data!.docs.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemCount, (index) {
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
            );
          },
        ),
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
          Text(
            'Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildCategoriesShimmer();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load categories',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories found',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final category = snapshot.data!.docs[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to category products
                      },
                      child: Container(
                        width: 80,
                        margin: EdgeInsets.only(
                          right:
                              index == snapshot.data!.docs.length - 1 ? 0 : 16,
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
                                  imageUrl: category.get('imageurl'),
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
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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

  Widget _buildProductsSection(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Products',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('products').limit(8).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildProductsShimmer();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load products',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No products found',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              return MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final product = snapshot.data!.docs[index];
                  final productId = product.id;
                  final hasDiscount =
                      product.get('discountPrice') != null &&
                      product.get('discountPrice') < product.get('price');
                  final isSaved = _savedItems.contains(productId);

                  return GestureDetector(
                    onTap: () {
                      // Navigate to product details
                    },
                    child: Container(
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
                                    imageUrl: product.get('images')[0],
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
                                      '${(((product.get('price')) - product.get('discountPrice')) / product.get('price') * 100).toStringAsFixed(0)}% OFF',
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
                                    isSaved
                                        ? Icons.favorite
                                        : Icons.favorite_border,
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
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.get('brandName'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '\$${product.get('discountPrice')?.toStringAsFixed(2) ?? product.get('price').toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF004aad),
                                          ),
                                    ),
                                    if (hasDiscount)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '\$${product.get('price').toStringAsFixed(2)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
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
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: 4,
      itemBuilder: (context, index) {
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
      },
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              isSelected: true,
              onTap: () => widget.onTabChange(0),
            ),
            _buildNavItem(
              icon: Icons.bookmark_rounded,
              label: 'Saved',
              index: 1,
              isSelected: false,
              onTap: () => widget.onTabChange(1),
            ),
            _buildNavItem(
              icon: Icons.search_rounded,
              label: 'Search',
              index: 2,
              isSelected: false,
              onTap: () => widget.onTabChange(2),
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 3,
              isSelected: false,
              onTap: () => widget.onTabChange(3),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF004aad) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF004aad) : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
