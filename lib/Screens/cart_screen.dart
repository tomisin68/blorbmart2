import 'package:blorbmart2/Screens/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _couponController = TextEditingController();

  bool _showCouponField = false;
  bool _isLoading = false;
  String _selectedPaymentMethod = 'Pay on Delivery';
  List<Map<String, dynamic>> _cartItems = [];
  double _deliveryFee = 5.99; // Fixed delivery fee
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('cart')
              .get();

      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          // Fetch additional product details from products collection
          final productDoc =
              await _firestore
                  .collection('products')
                  .doc(data['productId'])
                  .get();
          final productData = productDoc.data() ?? {};

          return {
            'id': doc.id,
            'productId': data['productId'],
            'name': data['name'] ?? 'No Name',
            'image': data['image'] ?? '',
            'price': data['price']?.toDouble() ?? 0.0,
            'originalPrice': productData['originalPrice']?.toDouble(),
            'quantity': data['quantity'] ?? 1,
            'color': productData['color'] ?? '',
            'size': productData['size'] ?? '',
            'sellerId': productData['sellerId'] ?? '',
            'inStock': (productData['stock'] ?? 0) > 0,
            'sellerName': productData['sellerName'] ?? 'Seller',
          };
        }).toList(),
      );

      if (mounted) {
        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorToast('Failed to load cart items');
      }
    }
  }

  Future<void> _updateQuantity(String itemId, int change) async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final index = _cartItems.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        final newQuantity = _cartItems[index]['quantity'] + change;

        if (newQuantity > 0) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('cart')
              .doc(itemId)
              .update({
                'quantity': newQuantity,
                'updatedAt': FieldValue.serverTimestamp(),
              });

          if (mounted) {
            setState(() {
              _cartItems[index]['quantity'] = newQuantity;
            });
          }
        }
      }
    } catch (e) {
      _showErrorToast('Failed to update quantity');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeItem(String itemId) async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(itemId)
          .delete();

      if (mounted) {
        setState(() {
          _cartItems.removeWhere((item) => item['id'] == itemId);
        });
      }
      _showSuccessToast('Item removed from cart');
    } catch (e) {
      _showErrorToast('Failed to remove item');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCart() async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _firestore.batch();
      final cartRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart');

      for (var item in _cartItems) {
        batch.delete(cartRef.doc(item['id']));
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _cartItems.clear();
        });
      }
      _showSuccessToast('Cart cleared');
    } catch (e) {
      _showErrorToast('Failed to clear cart');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveForLater(String itemId) async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final index = _cartItems.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        final item = _cartItems[index];

        // Add to saved items
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('saved')
            .doc(item['productId'])
            .set({
              'productId': item['productId'],
              'name': item['name'],
              'price': item['price'],
              'image': item['image'],
              'savedAt': FieldValue.serverTimestamp(),
            });

        // Remove from cart
        await _removeItem(itemId);

        _showSuccessToast('Item saved for later');
      }
    } catch (e) {
      _showErrorToast('Failed to save item');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate coupon validation
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _discount = 15.00; // Example discount
        _showCouponField = false;
        _isLoading = false;
      });
      _showSuccessToast('Coupon applied successfully');
    }
  }

  void _checkout() {
    if (_cartItems.isEmpty) {
      _showErrorToast('Your cart is empty');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutScreen(
              cartItems: _cartItems,
              subtotal: _calculateSubtotal(),
              deliveryFee: _deliveryFee,
              discount: _discount,
              paymentMethod: _selectedPaymentMethod,
            ),
      ),
    );
  }

  double _calculateSubtotal() {
    return _cartItems.fold(0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _deliveryFee - _discount;
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

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final total = _calculateTotal();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Cart (${_cartItems.length})',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0A1E3D),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF0A1E3D)),
              onPressed: _isLoading ? null : _clearCart,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    _cartItems.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your cart is empty',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: Text(
                                  'Continue Shopping',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            return _buildCartItem(_cartItems[index]);
                          },
                        ),
              ),
              if (_cartItems.isNotEmpty) _buildOrderSummary(subtotal, total),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['image'],
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${item['sellerName']}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item['color'] != null || item['size'] != null)
                        Text(
                          '${item['color']} • ${item['size']}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Price and Quantity
                      Row(
                        children: [
                          Text(
                            '₦${item['price'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange,
                            ),
                          ),
                          if (item['originalPrice'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '₦${item['originalPrice'].toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () =>
                                              _updateQuantity(item['id'], -1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text(
                                  '${item['quantity']}',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () =>
                                              _updateQuantity(item['id'], 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock status and actions
            Row(
              children: [
                Icon(
                  item['inStock'] ? Icons.check_circle : Icons.error,
                  color: item['inStock'] ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  item['inStock'] ? 'In Stock' : 'Out of Stock',
                  style: GoogleFonts.poppins(
                    color: item['inStock'] ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : () => _removeItem(item['id']),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed:
                      _isLoading ? null : () => _saveForLater(item['id']),
                  child: Text('Save for later', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Coupon Code Field
          if (_showCouponField)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text('Apply', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),

          // Order Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.poppins(color: Colors.grey)),
              Text(
                '₦${subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              Text(
                '₦${_deliveryFee.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Discount',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  if (_couponController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
              Text(
                '-₦${_discount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(color: Colors.green),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '₦${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Selection
          ExpansionTile(
            title: Text(
              'Payment Method',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            children: [
              RadioListTile<String>(
                title: Text('Pay on Delivery', style: GoogleFonts.poppins()),
                value: 'Pay on Delivery',
                groupValue: _selectedPaymentMethod,
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
              ),
              RadioListTile<String>(
                title: Text('Credit/Debit Card', style: GoogleFonts.poppins()),
                value: 'Credit/Debit Card',
                groupValue: _selectedPaymentMethod,
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
              ),
              RadioListTile<String>(
                title: Text('BlorbPay Wallet', style: GoogleFonts.poppins()),
                value: 'BlorbPay Wallet',
                groupValue: _selectedPaymentMethod,
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Coupon and Checkout Buttons
          Row(
            children: [
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _showCouponField = !_showCouponField;
                          });
                        },
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _showCouponField ? 'Hide Coupon' : 'Add Coupon',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Checkout',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}
