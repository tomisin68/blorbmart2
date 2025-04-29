import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Mock cart data
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': '1',
      'name': '6L Extra Large Capacity Air Fryer',
      'image': 'https://images.unsplash.com/photo-1618442302325-8b5f8e3a3b0d',
      'price': 129.99,
      'originalPrice': 159.99,
      'quantity': 1,
      'color': 'Black',
      'size': 'Standard',
      'seller': 'Campus Appliances',
      'inStock': true,
    },
    {
      'id': '2',
      'name': 'Wireless Bluetooth Headphones',
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
      'price': 59.99,
      'originalPrice': 79.99,
      'quantity': 2,
      'color': 'White',
      'size': 'One Size',
      'seller': 'TechGadgets',
      'inStock': true,
    },
    {
      'id': '3',
      'name': 'Organic Cotton T-Shirt',
      'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab',
      'price': 24.99,
      'quantity': 1,
      'color': 'Blue',
      'size': 'M',
      'seller': 'FashionHub',
      'inStock': false,
    },
  ];

  bool _showCouponField = false;
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = 'Pay on Delivery';

  @override
  Widget build(BuildContext context) {
    double subtotal = _calculateSubtotal();
    double deliveryFee = 5.99; // Fixed delivery fee for example
    double discount = 15.00; // Example discount
    double total = subtotal + deliveryFee - discount;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart (${_cartItems.length})'),
        actions: [
          IconButton(icon: Icon(Icons.delete_outline), onPressed: _clearCart),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(_cartItems[index]);
              },
            ),
          ),
          _buildOrderSummary(subtotal, deliveryFee, discount, total),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12),
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
                          (context, url) =>
                              Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'by ${item['seller']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      if (item['color'] != null || item['size'] != null)
                        Text(
                          '${item['color']} • ${item['size']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      SizedBox(height: 8),

                      // Price and Quantity
                      Row(
                        children: [
                          Text(
                            '\$${item['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                          if (item['originalPrice'] != null)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                '\$${item['originalPrice'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    _updateQuantity(item['id'], -1);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text(
                                  '${item['quantity']}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    _updateQuantity(item['id'], 1);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
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
            SizedBox(height: 8),

            // Stock status and actions
            Row(
              children: [
                Icon(
                  item['inStock'] ? Icons.check_circle : Icons.error,
                  color: item['inStock'] ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  item['inStock'] ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color: item['inStock'] ? Colors.green : Colors.red,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    _removeItem(item['id']);
                  },
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // Save for later functionality
                  },
                  child: Text('Save for later'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    double subtotal,
    double deliveryFee,
    double discount,
    double total,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Coupon Code Field
          if (_showCouponField)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                    ),
                    child: Text('Apply'),
                  ),
                ],
              ),
            ),

          // Order Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: Colors.grey)),
              Text('\$${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
              Text('\$${deliveryFee.toStringAsFixed(2)}'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Discount', style: TextStyle(color: Colors.grey)),
                  if (_couponController.text.isNotEmpty)
                    Padding(
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
                '-\$${discount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
          Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Payment Method Selection
          ExpansionTile(
            title: Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              RadioListTile<String>(
                title: Text('Pay on Delivery'),
                value: 'Pay on Delivery',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Credit/Debit Card'),
                value: 'Credit/Debit Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('BlorbPay Wallet'),
                value: 'BlorbPay Wallet',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8),

          // Coupon and Checkout Buttons
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCouponField = !_showCouponField;
                  });
                },
                child: Row(
                  children: [
                    Icon(Icons.local_offer, size: 18),
                    SizedBox(width: 4),
                    Text(_showCouponField ? 'Hide Coupon' : 'Add Coupon'),
                  ],
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('Checkout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    return _cartItems.fold(0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  void _updateQuantity(String itemId, int change) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        int newQuantity = _cartItems[index]['quantity'] + change;
        if (newQuantity > 0) {
          _cartItems[index]['quantity'] = newQuantity;
        }
      }
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == itemId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item removed from cart'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // In a real app, you would implement undo functionality
          },
        ),
      ),
    );
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Cart'),
          content: Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cartItems.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _applyCoupon() {
    // Coupon validation logic would go here
    setState(() {
      _showCouponField = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon applied successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _checkout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/checkout');
  }
}
