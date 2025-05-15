import 'package:blorbmart2/Screens/product_feed.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final categories =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'No Name',
              'description': data['description'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
            };
          }).toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where(
          (category) =>
              category['name'].toLowerCase().contains(_searchQuery) ||
              (category['description'] as String).toLowerCase().contains(
                _searchQuery,
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Browse Categories',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Optional: Focus the search field when icon is pressed
              FocusScope.of(context).requestFocus(FocusNode());
              Future.delayed(Duration.zero, () {
                FocusScope.of(context).requestFocus(FocusNode());
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        color: const Color(0xFF4CAF50),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF9E9E9E),
                        size: 24,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                              : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    repeatPattern: QuiltedGridRepeatPattern.same,
                    pattern: [const QuiltedGridTile(1, 1)],
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCategory(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_filteredCategories.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No categories available'
                              : 'No matches found',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Check back later for new categories'
                              : 'Try a different search term',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Clear search',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    repeatPattern: QuiltedGridRepeatPattern.same,
                    pattern: [const QuiltedGridTile(1, 1)],
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = _filteredCategories[index];
                    return _buildCategoryCard(category);
                  }, childCount: _filteredCategories.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _navigateToCategoryProducts(category);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background image with gradient overlay
                Positioned.fill(
                  child:
                      category['imageUrl'] != null &&
                              category['imageUrl'].isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: category['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) =>
                                    Container(color: const Color(0xFFEEEEEE)),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: const Color(0xFFEEEEEE),
                                  child: Center(
                                    child: Icon(
                                      Icons.category,
                                      color: const Color(0xFF9E9E9E),
                                      size: 48,
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFEEEEEE),
                            child: Center(
                              child: Icon(
                                Icons.category,
                                color: const Color(0xFF9E9E9E),
                                size: 48,
                              ),
                            ),
                          ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        category['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category['description'] != null &&
                          (category['description'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            category['description'],
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Explore button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _navigateToCategoryProducts(category);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                          ),
                          child: Text(
                            'Explore',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hover effect
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _navigateToCategoryProducts(category);
                        },
                        splashColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryProducts(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductFeed(
              categoryId: category['id'],
              categoryName: category['name'],
            ),
      ),
    );
  }

  Widget _buildShimmerCategory() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFEEEEEE),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFEEEEEE),
              highlightColor: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Shimmer.fromColors(
                    baseColor: const Color(0xFFEEEEEE),
                    highlightColor: Colors.white,
                    child: Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: const Color(0xFFEEEEEE),
                    highlightColor: Colors.white,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Shimmer.fromColors(
                    baseColor: const Color(0xFFEEEEEE),
                    highlightColor: Colors.white,
                    child: Container(
                      height: 36,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
