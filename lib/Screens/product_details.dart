import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter_icons/flutter_icons.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _currentImageIndex = 0;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  // Mock product data - in a real app this would come from the home page navigation
  final Map<String, dynamic> _product = {
    'name': '6L Extra Large Capacity Air Fryer',
    'brand': 'Instant Brands',
    'price': 129.99,
    'originalPrice': 159.99,
    'discount': 19,
    'rating': 4.7,
    'reviewCount': 128,
    'stock': 5,
    'description':
        'The Instant Vortex Plus 6L Air Fryer with ClearCook and OdorErase technology features a window so you can watch your food crisp to perfection, plus a stainless steel filter that reduces cooking odors. With 6-quart capacity, it\'s perfect for families and entertaining.',
    'images': [
      'https://images.unsplash.com/photo-1618442302325-8b5f8e3a3b0d',
      'https://images.unsplash.com/photo-1618442302390-5a2b220e395a',
      'https://images.unsplash.com/photo-1618442302401-5f3a0a3f3b0d',
    ],
    'colors': [
      {'name': 'Black', 'code': Colors.black},
      {'name': 'Silver', 'code': Colors.grey},
      {'name': 'Red', 'code': Colors.red},
    ],
    'sizes': ['Standard', 'Large', 'Extra Large'],
    'features': [
      '6-quart capacity',
      'ClearCook window',
      'OdorErase technology',
      '4-in-1 functionality',
      'EvenCrisp technology',
    ],
    'seller': {
      'name': 'Campus Appliances',
      'rating': 4.8,
      'location': '1.2 km from you',
      'responseRate': '98%',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareProduct),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            _buildImageCarousel(),

            // Product Info Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title and Brand
                  Text(
                    _product['name'],
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'by ${_product['brand']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),

                  // Price and Discount
                  Row(
                    children: [
                      Text(
                        '\$${_product['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(width: 8),
                      if (_product['originalPrice'] != null)
                        Text(
                          '\$${_product['originalPrice'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      SizedBox(width: 8),
                      if (_product['discount'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_product['discount']}% OFF',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Rating and Reviews
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _product['rating'].toString(),
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              color: Colors.green[800],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${_product['reviewCount']} reviews',
                        style: TextStyle(
                          color: Colors.blue[800],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_product['stock']} left in stock',
                        style: TextStyle(
                          color:
                              _product['stock'] < 3 ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Color Selection
                  Text(
                    'Color:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _product['colors'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_product['colors'][index]['name']),
                            selected: _selectedColorIndex == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedColorIndex = index;
                              });
                            },
                            selectedColor: Colors.blue[100],
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color:
                                  _selectedColorIndex == index
                                      ? Colors.blue[800]
                                      : Colors.black,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    _selectedColorIndex == index
                                        ? Colors.blue[800]!
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),

                  // Size Selection
                  Text(
                    'Size:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _product['sizes'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_product['sizes'][index]),
                            selected: _selectedSizeIndex == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSizeIndex = index;
                              });
                            },
                            selectedColor: Colors.blue[100],
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color:
                                  _selectedSizeIndex == index
                                      ? Colors.blue[800]
                                      : Colors.black,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    _selectedSizeIndex == index
                                        ? Colors.blue[800]!
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),

                  // Quantity Selector
                  Text(
                    'Quantity:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
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
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$_quantity',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (_quantity < _product['stock']) {
                            setState(() {
                              _quantity++;
                            });
                          }
                        },
                      ),
                      Spacer(),
                      Text(
                        '${_product['stock']} available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Product Description
                  Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _product['description'],
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 16),

                  // Key Features
                  Text(
                    'Key Features',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Column(
                    children:
                        _product['features'].map<Widget>((feature) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: 24),

                  // Seller Information
                  Text(
                    'Seller Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            _product['seller']['name'][0],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product['seller']['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  Text(
                                    ' ${_product['seller']['rating']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.location_on, size: 16),
                                  Text(
                                    ' ${_product['seller']['location']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: () {
                            // Navigate to seller profile
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Chat Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startChat,
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.blue[800]!),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
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
              _product['images'].map((imageUrl) {
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) =>
                          Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                );
              }).toList(),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              _product['images'].asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentImageIndex == entry.key
                            ? Colors.blue[800]
                            : Colors.grey[300],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareProduct() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing product...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _startChat() {
    // Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with seller...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addToCart() {
    // Add to cart logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity ${_product['name']} to cart'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartScreen()),
            );
            // Navigate to cart
          },
        ),
      ),
    );
  }
}
