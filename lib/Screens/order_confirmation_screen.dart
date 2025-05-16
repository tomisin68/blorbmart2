import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blorbmart2/Screens/home_page.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Order Confirmed!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your order has been placed successfully',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Order ID: $orderId',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OrderDetailsScreen(
                            orderId: orderId,
                            status: 'confirmed', // Initial status
                          ),
                    ),
                  );
                },
                child: Text(
                  'View Order Details',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final String status;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.status,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // Simulated order data - replace with your actual data fetching logic
  final Map<String, dynamic> _orderDetails = {
    'items': [
      {
        'name': 'Wireless Headphones',
        'price': 59.99,
        'quantity': 1,
        'image': 'https://example.com/headphones.jpg',
      },
      {
        'name': 'Smart Watch',
        'price': 129.99,
        'quantity': 1,
        'image': 'https://example.com/watch.jpg',
      },
    ],
    'shippingAddress': '123 Campus Ave, Student Dorm 45, University Town',
    'paymentMethod': 'Pay on Delivery',
    'subtotal': 189.98,
    'shippingFee': 5.00,
    'total': 194.98,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3D),
        elevation: 0,
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Timeline
            _buildStatusTimeline(),

            const SizedBox(height: 24),

            // Order Summary
            Text(
              'Order Summary',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1A3A6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final item in _orderDetails['items'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withOpacity(0.1),
                                image: DecorationImage(
                                  image: NetworkImage(item['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₦${item['price'].toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '×${item['quantity']}',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    const Divider(color: Colors.white24),
                    _buildOrderDetailRow(
                      'Subtotal',
                      '₦${_orderDetails['subtotal'].toStringAsFixed(2)}',
                    ),
                    _buildOrderDetailRow(
                      'Shipping Fee',
                      '₦${_orderDetails['shippingFee'].toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildOrderDetailRow(
                      'Total',
                      '₦${_orderDetails['total'].toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Shipping Information
            Text(
              'Shipping Information',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1A3A6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.location_on,
                      'Delivery Address',
                      _orderDetails['shippingAddress'],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.payment,
                      'Payment Method',
                      _orderDetails['paymentMethod'],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order ID
            Center(
              child: Text(
                'Order ID: ${widget.orderId}',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Implement any action needed
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Need Help? Contact Support',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final List<String> statuses = [
      'pending',
      'confirmed',
      'picked up',
      'in transit',
      'out for delivery',
      'delivered',
    ];

    final currentStatusIndex = statuses.indexOf(widget.status);

    return Card(
      color: const Color(0xFF1A3A6A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < statuses.length; i++)
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              i <= currentStatusIndex
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.1),
                        ),
                        child: Icon(
                          i < currentStatusIndex ? Icons.check : Icons.circle,
                          color:
                              i <= currentStatusIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statuses[i].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color:
                                i <= currentStatusIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            fontWeight:
                                i <= currentStatusIndex
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (i == currentStatusIndex)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CURRENT',
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (i != statuses.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 4,
                        bottom: 4,
                      ),
                      child: Container(
                        width: 1,
                        height: 20,
                        color:
                            i < currentStatusIndex
                                ? Colors.green
                                : Colors.white.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isTotal ? Colors.orange : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(color: Colors.orange, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
