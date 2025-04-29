// ignore_for_file: unused_import

import 'package:blorbmart2/Screens/cart_screen.dart';
import 'package:blorbmart2/Screens/product_details.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Mock data for demonstration
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Appliances',
      'icon': Icons.kitchen,
      'image': 'https://images.unsplash.com/photo-1556911220-bff31c812dba',
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

  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a',
    'https://images.unsplash.com/photo-1556905055-8f358a7a47b2',
    'https://images.unsplash.com/photo-1556909211-d64b6b0516d4',
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'name': '6L Extra Large Capacity Air Fryer',
      'price': 129.99,
      'stock': 5,
      'image': 'https://images.unsplash.com/photo-1618442302325-8b5f8e3a3b0d',
      'sponsored': false,
    },
    {
      'name': 'Wireless Bluetooth Headphones',
      'price': 59.99,
      'stock': 12,
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
      'sponsored': false,
    },
    {
      'name': 'Organic Cotton T-Shirt',
      'price': 24.99,
      'stock': 8,
      'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab',
      'sponsored': true,
    },
    {
      'name': 'Programming Textbook',
      'price': 49.99,
      'stock': 3,
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
      'sponsored': false,
    },
    {
      'name': 'Smart Watch',
      'price': 199.99,
      'stock': 7,
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
      'sponsored': true,
    },
  ];

  final List<Map<String, dynamic>> _topSellers = [
    {
      'name': 'TechGadgets',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c',
    },
    {
      'name': 'FashionHub',
      'rating': 4.6,
      'image': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f',
    },
    {
      'name': 'BookWorm',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    },
  ];

  final List<Map<String, dynamic>> _officialStores = [
    {
      'name': 'Royal Elegance Perfume Store',
      'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
    },
    {
      'name': "Dhemhi's Glam Store",
      'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e',
    },
    {
      'name': 'Campus Tech Hub',
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c',
    },
  ];

  final int _cartCount = 3; // Example cart count
  final DateTime _flashSaleEnd = DateTime.now().add(Duration(hours: 2));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search on Blorbmart',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to cart page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 5,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
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
          // Refresh logic here
          await Future.delayed(Duration(seconds: 2));
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nearby feeds section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Nearby Products & Stores',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all feeds page
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              // Carousel slider
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 180,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                    enlargeCenterPage: true,
                  ),
                  items:
                      _carouselImages.map((imageUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) =>
                                          Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                ),
              ),

              // Categories section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all categories page
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    _categories[index]['image'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  _categories[index]['icon'],
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _categories[index]['name'],
                              style: TextStyle(fontSize: 12),
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
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[600]!],
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
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Up to 50% off',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ends in ${_formatCountdown()}',
                            style: TextStyle(
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
                      ),
                      child: Text(
                        'Shop Now',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),

              // Products section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Trending Products',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all products page
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    if (_products[index]['sponsored']) return SizedBox.shrink();

                    return _buildProductCard(_products[index]);
                  },
                ),
              ),

              // Sponsored products section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Sponsored',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all sponsored products
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    if (!_products[index]['sponsored'])
                      return SizedBox.shrink();

                    return _buildProductCard(_products[index]);
                  },
                ),
              ),

              // Top sellers section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Top Sellers',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all top sellers
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topSellers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Navigate to seller's store
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: CachedNetworkImageProvider(
                                _topSellers[index]['image'],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(_topSellers[index]['name']),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(_topSellers[index]['rating'].toString()),
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Official Stores',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to all official stores
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _officialStores.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Navigate to official store
                        },
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: _officialStores[index]['image'],
                                  height: 100,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  _officialStores[index]['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
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

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () {
          _showBecomeSellerDialog(context);
        },
        child: Icon(Icons.store, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home is selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product['image'],
                      height: 120,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (product['sponsored'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Sponsored',
                          style: TextStyle(
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
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${product['price'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${product['stock']} left',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
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

  String _formatCountdown() {
    Duration remaining = _flashSaleEnd.difference(DateTime.now());
    return '${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _showBecomeSellerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Become a Seller on Blorbmart'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1556740738-b6a63e27c4df',
                height: 120,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 16),
              Text(
                'Join our community of student sellers and start making money from your unused items!',
              ),
              SizedBox(height: 16),
              Text('Benefits:'),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('No listing fees'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Campus-wide reach'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Secure transactions'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  context,
                ); // Close any dialog or pop the current screen if needed
                const url =
                    'https://market-monitor-five.vercel.app'; // Replace with your actual URL
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  throw 'Could not launch $url';
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Go to Seller Portal'),
            ),
          ],
        );
      },
    );
  }
}
