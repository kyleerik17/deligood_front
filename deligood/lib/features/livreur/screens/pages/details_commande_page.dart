import 'dart:convert';
import 'package:deligood/features/pages/produit_detail_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==================== COMMANDE PAGE ====================
class CommandePage extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final String image;

  const CommandePage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.image,
  });

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage>
    with SingleTickerProviderStateMixin {
  late Future<List<MenuItem>> _futureMenu;
  late AnimationController _animationController;
  String _selectedCategory = 'Tout';
  List<String> _categories = ['Tout'];
  List<MenuItem> _allItems = [];
  List<MenuItem> _filteredItems = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _futureMenu = fetchMenu();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== FETCH MENU ====================
  Future<List<MenuItem>> fetchMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse(
        'https://deligood-backend.onrender.com/api/orders/menu/restaurant/${widget.restaurantId}/',
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    print('FetchMenu response status: ${response.statusCode}');
    print('FetchMenu response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final items = data.map((e) => MenuItem.fromJson(e)).toList();

      // Extraire les catégories uniques
      final cats = items
          .map((e) => e.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _allItems = items;
        _filteredItems = items;
        _categories = ['Tout', ...cats];
      });

      print('Fetched items: ${_allItems.length}');
      for (var item in _allItems) {
        print(
          'Item: ${item.name}, category: ${item.category}, price: ${item.price}',
        );
      }

      _animationController.forward();
      return items;
    } else {
      throw Exception("Erreur chargement menu (${response.statusCode})");
    }
  }

  // ==================== FILTER ITEMS ====================
  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchCat =
            _selectedCategory == 'Tout' ||
            item.category.toLowerCase().trim() ==
                _selectedCategory.toLowerCase().trim();
        final matchSearch =
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchCat && matchSearch;
      }).toList();

      print('Filter -> category=$_selectedCategory, search=$_searchQuery');
      print('Filtered items count: ${_filteredItems.length}');
    });
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: FutureBuilder<List<MenuItem>>(
        future: _futureMenu,
        builder: (context, snapshot) {
          print(
            'FutureBuilder snapshot: state=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}',
          );

          final items = snapshot.data ?? []; // sécurise null
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          // On initialise _allItems et _filteredItems si pas encore fait
          if (_allItems.isEmpty && items.isNotEmpty) {
            _allItems = items;
            _filteredItems = items;
            final cats = items
                .map((e) => e.category)
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            _categories = ['Tout', ...cats];
            _animationController.forward();
          }

          if (_filteredItems.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildSearchBar()),
              if (_categories.length > 1)
                SliverToBoxAdapter(child: _buildCategories()),
              SliverToBoxAdapter(child: _buildStatsBar()),
              _buildGrid(),
            ],
          );
        },
      ),
    );
  }

  // ==================== SLIVER APP BAR ====================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 28.h,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white30,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 · Livraison 20-30 min',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.white70,
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
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          SizedBox(width: 2.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterItems();
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un plat...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.poppins(fontSize: 12.sp),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _filterItems();
              },
              child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
            ),
        ],
      ),
    );
  }

  // ==================== CATEGORIES ====================
  Widget _buildCategories() {
    return SizedBox(
      height: 6.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _filterItems();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFFFF6B35).withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== STATS BAR ====================
  Widget _buildStatsBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Text(
            '${_filteredItems.length} plat${_filteredItems.length > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          Icon(Icons.tune, size: 18, color: Colors.grey.shade500),
        ],
      ),
    );
  }

  // ==================== GRID ====================
  Widget _buildGrid() {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 12.h),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _filteredItems[index];
          print('Building card for item: ${item.name}');
          return _buildMenuCard(item, index);
        }, childCount: _filteredItems.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  // ==================== MENU CARD ====================
  Widget _buildMenuCard(MenuItem item, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = (index * 0.1).clamp(0.0, 0.9);
        final animValue = Curves.easeOut.transform(
          (((_animationController.value - delay) / (1.0 - delay)).clamp(
            0.0,
            1.0,
          )),
        );
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => ProduitDetailPage(
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
                image: widget.image,
                menuItem: item,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (item.category.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category,
                            style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          color: const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.price} F',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
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
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Impossible de charger le menu',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => setState(() => _futureMenu = fetchMenu()),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Aucun plat trouvé 😕',
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ==================== MENU ITEM MODEL ====================
class MenuItem {
  final int id;
  final String name;
  final String description;
  final String price;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      category: json['category'] ?? '',
      imageUrl: json['image'] ?? '', // toujours string non-null
    );
  }
}
