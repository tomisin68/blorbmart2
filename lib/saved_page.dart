import 'package:blorbmart2/Screens/product_details.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _savedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedItems();
  }

  Future<void> _fetchSavedItems() async {
    if (_auth.currentUser == null) return;

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('saved')
              .orderBy('savedAt', descending: true)
              .get();

      final List<Map<String, dynamic>> items = [];

      // Fetch product details for each saved item
      for (final doc in snapshot.docs) {
        final productId = doc.data()['productId'];
        final productDoc =
            await _firestore.collection('products').doc(productId).get();

        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          items.add({
            'id': productId,
            'name': productData['name'] ?? 'No Name',
            'price': (productData['price'] as num?)?.toDouble() ?? 0.0,
            'image':
                (productData['imageUrls'] is List &&
                        productData['imageUrls'].isNotEmpty)
                    ? productData['imageUrls'][0]
                    : '',
            'savedId': doc.id,
          });
        }
      }

      if (mounted) {
        setState(() {
          _savedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorToast('Failed to load saved items');
    }
  }

  Future<void> _removeSavedItem(String savedId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('saved')
          .doc(savedId)
          .delete();

      if (mounted) {
        setState(() {
          _savedItems.removeWhere((item) => item['savedId'] == savedId);
        });
      }
      _showSuccessToast('Item removed from saved');
    } catch (e) {
      _showErrorToast('Failed to remove item');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3D),
        elevation: 0,
        title: Text(
          'Saved Items',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? _buildLoadingShimmer()
              : _savedItems.isEmpty
              ? _buildEmptyState()
              : _buildSavedItemsList(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Saved Items',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save items you like to view them later',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedItems.length,
      itemBuilder: (context, index) {
        final item = _savedItems[index];
        return Dismissible(
          key: Key(item['savedId']),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          onDismissed: (direction) => _removeSavedItem(item['savedId']),
          child: GestureDetector(
            onTap: () {
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
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A6A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item['image'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              Container(color: Colors.white.withOpacity(0.1)),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(Icons.error, color: Colors.white),
                          ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₦${item['price'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => _removeSavedItem(item['savedId']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
