import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentImageIndex = 0;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;
  bool _isFavorite = false;
  List<String> _productImages = [];
  Map<String, dynamic>? _sellerInfo;

  @override
  void initState() {
    super.initState();
    _initializeProductData();
    _checkIfProductIsSaved();
    _fetchSellerInfo();
  }

  Future<void> _initializeProductData() async {
    setState(() {
      _productImages =
          widget.product['imageUrls'] is List
              ? List<String>.from(widget.product['imageUrls'])
              : [widget.product['image'] ?? ''];
    });
  }

  Future<void> _checkIfProductIsSaved() async {
    if (_auth.currentUser == null) return;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('saved')
              .doc(widget.product['id'])
              .get();

      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Failed to check saved status');
      }
    }
  }

  Future<void> _fetchSellerInfo() async {
    try {
      final sellerId = widget.product['sellerId'];
      if (sellerId == null || sellerId.isEmpty) return;

      final doc = await _firestore.collection('users').doc(sellerId).get();
      if (mounted && doc.exists) {
        setState(() {
          _sellerInfo = doc.data();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Failed to load seller info');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to save products');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final savedRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('saved')
          .doc(widget.product['id']);

      if (_isFavorite) {
        await savedRef.delete();
        _showSuccessToast('Removed from saved');
      } else {
        await savedRef.set({
          'productId': widget.product['id'],
          'name': widget.product['name'],
          'price': widget.product['price'],
          'image': _productImages.isNotEmpty ? _productImages[0] : '',
          'savedAt': FieldValue.serverTimestamp(),
        });
        _showSuccessToast('Saved for later');
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      _showErrorToast('Failed to update saved status');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to add items to cart');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(widget.product['id']);

      final doc = await cartRef.get();

      if (doc.exists) {
        await cartRef.update({
          'quantity': FieldValue.increment(_quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'productId': widget.product['id'],
          'name': widget.product['name'],
          'price': widget.product['price'],
          'image': _productImages.isNotEmpty ? _productImages[0] : '',
          'quantity': _quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      _showSuccessToast('Added to cart');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    } catch (e) {
      _showErrorToast('Failed to add to cart');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product['price']?.toDouble() ?? 0.0;
    final originalPrice = product['originalPrice']?.toDouble();
    final discount =
        originalPrice != null
            ? ((originalPrice - price) / originalPrice * 100).round()
            : null;
    final stock = product['stock'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProduct,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _isLoading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel
                _buildImageCarousel(),

                // Product Info Section
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Title and Brand
                        Text(
                          product['name'] ?? 'No Name',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (product['brand'] != null)
                          Text(
                            'by ${product['brand']}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Price and Discount
                        Row(
                          children: [
                            Text(
                              '₦${price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (originalPrice != null)
                              Text(
                                '₦${originalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white54,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '$discount% OFF',
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rating and Reviews
                        Row(
                          children: [
                            if (product['rating'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      product['rating'].toString(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.greenAccent,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (product['reviewCount'] != null)
                              Text(
                                '${product['reviewCount']} reviews',
                                style: GoogleFonts.poppins(
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '$stock left in stock',
                              style: GoogleFonts.poppins(
                                color:
                                    stock < 3
                                        ? Colors.redAccent
                                        : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Color Selection (if available)
                        if (product['colors'] != null &&
                            product['colors'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Color:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: product['colors'].length,
                                  itemBuilder: (context, index) {
                                    final color = product['colors'][index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(
                                          color['name'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                        selected: _selectedColorIndex == index,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedColorIndex = index;
                                          });
                                        },
                                        selectedColor: Colors.orange
                                            .withOpacity(0.2),
                                        backgroundColor: const Color(
                                          0xFF0A1E3D,
                                        ),
                                        labelStyle: GoogleFonts.poppins(
                                          color:
                                              _selectedColorIndex == index
                                                  ? Colors.orange
                                                  : Colors.white,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color:
                                                _selectedColorIndex == index
                                                    ? Colors.orange
                                                    : Colors.white54,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Size Selection (if available)
                        if (product['sizes'] != null &&
                            product['sizes'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Size:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: product['sizes'].length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(
                                          product['sizes'][index],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                        selected: _selectedSizeIndex == index,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedSizeIndex = index;
                                          });
                                        },
                                        selectedColor: Colors.orange
                                            .withOpacity(0.2),
                                        backgroundColor: const Color(
                                          0xFF0A1E3D,
                                        ),
                                        labelStyle: GoogleFonts.poppins(
                                          color:
                                              _selectedSizeIndex == index
                                                  ? Colors.orange
                                                  : Colors.white,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color:
                                                _selectedSizeIndex == index
                                                    ? Colors.orange
                                                    : Colors.white54,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Quantity Selector
                        Text(
                          'Quantity:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white54),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                if (_quantity < stock) {
                                  setState(() {
                                    _quantity++;
                                  });
                                }
                              },
                            ),
                            const Spacer(),
                            Text(
                              '$stock available',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Product Description
                        if (product['description'] != null &&
                            product['description'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product['description'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Key Features (if available)
                        if (product['features'] != null &&
                            product['features'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Key Features',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children:
                                    product['features'].map<Widget>((feature) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.greenAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                feature,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),

                        // Seller Information
                        if (_sellerInfo != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seller Information',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1E3D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white12,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.orange
                                          .withOpacity(0.2),
                                      child: Text(
                                        _sellerInfo!['name']?[0] ?? 'S',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _sellerInfo!['name'] ?? 'Seller',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              Text(
                                                ' ${_sellerInfo!['rating']?.toStringAsFixed(1) ?? '4.5'}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.white70,
                                              ),
                                              Text(
                                                ' ${_sellerInfo!['location'] ?? 'Nearby'}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        // Navigate to seller profile
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E3D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Chat Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('Chat', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  backgroundColor: const Color(0xFF1A3A6A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.orange),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Add to Cart Button
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Add to Cart',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_productImages.isEmpty) {
      return Container(
        height: 300,
        color: const Color(0xFF1A3A6A),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.white54,
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              _productImages.map((imageUrl) {
                return GestureDetector(
                  onTap: () => _showFullScreenImage(imageUrl),
                  child: Hero(
                    tag: imageUrl,
                    child: Container(
                      color: const Color(0xFF1A3A6A),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => Container(
                              color: const Color(0xFF1A3A6A),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: const Color(0xFF1A3A6A),
                              child: const Center(
                                child: Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.white54,
                                ),
                              ),
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
              _productImages.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentImageIndex == entry.key
                            ? Colors.orange
                            : Colors.white54,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _shareProduct() {
    // Implement share functionality
    _showSuccessToast('Sharing product...');
  }

  void _startChat() {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to chat with seller');
      return;
    }
    _showSuccessToast('Opening chat with seller...');
  }
}
