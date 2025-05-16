import 'package:blorbmart2/Screens/order_confirmation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String paymentMethod;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.paymentMethod,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _saveAddress = true;
  String _selectedDeliveryOption = 'Standard Delivery (3-5 days)';
  final List<String> _deliveryOptions = [
    'Standard Delivery (3-5 days)',
    'Express Delivery (1-2 days)',
    'Same Day Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_auth.currentUser == null) return;

    try {
      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (mounted) {
          setState(() {
            _addressController.text = userData?['address'] ?? '';
            _phoneController.text = userData?['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      _showErrorToast('Failed to load user data');
    }
  }

  Future<void> _placeOrder() async {
    if (_auth.currentUser == null) {
      _showErrorToast('Please login to place an order');
      return;
    }

    if (_addressController.text.isEmpty) {
      _showErrorToast('Please enter your delivery address');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showErrorToast('Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _firestore.batch();
      final ordersRef = _firestore.collection('orders');
      final orderId = ordersRef.doc().id;
      final userId = _auth.currentUser!.uid;
      final now = DateTime.now();

      // Create order document
      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'items':
            widget.cartItems.map((item) {
              return {
                'productId': item['productId'],
                'name': item['name'],
                'price': item['price'],
                'quantity': item['quantity'],
                'image': item['image'],
              };
            }).toList(),
        'subtotal': widget.subtotal,
        'deliveryFee': widget.deliveryFee,
        'discount': widget.discount,
        'total': widget.subtotal + widget.deliveryFee - widget.discount,
        'deliveryAddress': _addressController.text,
        'phoneNumber': _phoneController.text,
        'deliveryOption': _selectedDeliveryOption,
        'paymentMethod': widget.paymentMethod,
        'notes': _notesController.text,
        'status': 'Processing',
        'createdAt': now,
        'updatedAt': now,
      };

      batch.set(ordersRef.doc(orderId), orderData);

      // Clear cart
      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart');

      for (var item in widget.cartItems) {
        batch.delete(cartRef.doc(item['id']));
      }

      // Update user address if requested
      if (_saveAddress) {
        batch.update(_firestore.collection('users').doc(userId), {
          'address': _addressController.text,
          'phone': _phoneController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      _showErrorToast('Failed to place order. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + widget.deliveryFee - widget.discount;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3D),
        elevation: 0,
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Address Section
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery Address',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your full address',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Colors.white54,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _saveAddress,
                              onChanged: (value) {
                                setState(() {
                                  _saveAddress = value ?? false;
                                });
                              },
                              activeColor: Colors.orange,
                              checkColor: Colors.white,
                            ),
                            Text(
                              'Save this address for future orders',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Options
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery Options',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._deliveryOptions.map((option) {
                          return RadioListTile<String>(
                            title: Text(
                              option,
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            value: option,
                            groupValue: _selectedDeliveryOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedDeliveryOption = value!;
                              });
                            },
                            activeColor: Colors.orange,
                            tileColor: Colors.transparent,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Method',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(
                            _getPaymentMethodIcon(widget.paymentMethod),
                            color: Colors.orange,
                          ),
                          title: Text(
                            widget.paymentMethod,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Change',
                              style: GoogleFonts.poppins(color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Summary
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = widget.cartItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0xFF0A1E3D),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item['image'],
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              color: const Color(0xFF0A1E3D),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.orange,
                                                    ),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => const Icon(
                                              Icons.error,
                                              color: Colors.white54,
                                            ),
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
                                          item['name'],
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item['quantity']} x ₦${item['price'].toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₦${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(
                          height: 24,
                          thickness: 1,
                          color: Colors.white24,
                        ),
                        _buildSummaryRow('Subtotal', widget.subtotal),
                        _buildSummaryRow('Delivery Fee', widget.deliveryFee),
                        _buildSummaryRow(
                          'Discount',
                          -widget.discount,
                          isDiscount: true,
                        ),
                        const Divider(
                          height: 24,
                          thickness: 1,
                          color: Colors.white24,
                        ),
                        _buildSummaryRow('Total', total, isTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Notes
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Notes',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Any special instructions?',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom button
              ],
            ),
          ),

          // Place Order Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1E3D),
                border: Border(
                  top: BorderSide(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              'Place Order - ₦${total.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isTotal ? Colors.white : Colors.white70,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount && amount > 0 ? '-' : ''}₦${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color:
                  isTotal
                      ? Colors.orange
                      : isDiscount
                      ? Colors.greenAccent
                      : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Pay on Delivery':
        return Icons.money;
      case 'Credit/Debit Card':
        return Icons.credit_card;
      case 'BlorbPay Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
