import 'dart:convert';
import 'package:deligood/features/livreur/screens/pages/details_commande_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:gap/gap.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> restaurants = [];
  List<dynamic> filteredRestaurants = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'Tous';
  final List<String> categories = [
    'Tous',
    'Fast-food',
    'Africain',
    'Italien',
    'Asiatique',
    'Français',
  ];

  final String baseUrl = 'http://127.0.0.1:8000/api/menu/restaurants/';

  late final AnimationController _listAnimationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _filterRestaurants();
    });
  }

  void _filterRestaurants() {
    final query = searchQuery.toLowerCase();
    filteredRestaurants = restaurants.where((restaurant) {
      final name = (restaurant['name'] ?? '').toLowerCase();
      final desc = (restaurant['description'] ?? '').toLowerCase();
      final category = restaurant['category'] ?? '';
      return (name.contains(query) || desc.contains(query)) &&
          (selectedCategory == 'Tous' || category == selectedCategory);
    }).toList();
  }

  Future<void> fetchRestaurants() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Délai de connexion dépassé');
            },
          );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          restaurants = decoded;
          filteredRestaurants = decoded;
          isLoading = false;
        });
        _listAnimationController.forward(from: 0);
      } else {
        setState(() => isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement des restaurants');
      }
    } catch (e) {
      debugPrint('Erreur fetch: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Impossible de charger les restaurants');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const Gap(12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: fetchRestaurants,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 20.h,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00D9B1),
                          const Color(0xFF00BFA5),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 1.h),
                            Text(
                              'Découvrez',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'Les meilleurs restaurants',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            // Search bar
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un restaurant...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    CupertinoIcons.search,
                                    color: const Color(0xFF00D9B1),
                                    size: 20.sp,
                                  ),
                                  suffixIcon: searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            CupertinoIcons.clear_thick_circled,
                                            color: Colors.grey.shade400,
                                            size: 20.sp,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 1.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  child: SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: CupertinoButton(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            color: isSelected
                                ? const Color(0xFF00D9B1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            onPressed: () {
                              setState(() {
                                selectedCategory = category;
                                _filterRestaurants();
                              });
                            },
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF00D9B1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Restaurants list
              if (isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF00D9B1),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        Gap(3.h),
                        Text(
                          'Chargement...',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredRestaurants.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      searchQuery.isNotEmpty
                          ? 'Aucun restaurant trouvé'
                          : 'Aucun restaurant disponible',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final restaurant = filteredRestaurants[index];
                      return _buildRestaurantCard(restaurant);
                    }, childCount: filteredRestaurants.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
   
     final firstName = restaurant['first_name'] ?? '';
  final lastName = restaurant['last_name'] ?? '';
  // ignore: prefer_interpolation_to_compose_strings
  final name = (firstName + ' ' + lastName).trim();
  
    final description = restaurant['description'] ?? 'Pas de description';
    final rating = restaurant['rating'] ?? 4.5;
    final isOpen = restaurant['is_open'] ?? true;
    final deliveryTime = restaurant['delivery_time'] ?? '30-40';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => CommandePage(
              restaurantId: restaurant['id'],
              restaurantName: name,
              image: 'assets/images/n.png', // Image fixe
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/n.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Gap(0.5.h),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber.shade700,
                                  size: 12.sp,
                                ),
                                Gap(1.w),
                                Text(
                                  rating.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              Gap(1.w),
                              Text(
                                '$deliveryTime min',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
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
}

// Page de commandes
