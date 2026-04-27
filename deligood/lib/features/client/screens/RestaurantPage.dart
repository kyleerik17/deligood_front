import 'dart:convert';
import 'package:deligood/features/client/screens/restopage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:gap/gap.dart';

// 🎨 COLORS (DeliGood)
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Colors.black54;

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
  String selectedCategory = 'Tous';

  final TextEditingController _search = TextEditingController();

  final List<String> categories = [
    'Tous',
    'Fast-food',
    'Africain',
    'Italien',
    'Asiatique',
  ];

  late AnimationController _anim;

  final String baseUrl = 'http://127.0.0.1:8000/api/menu/restaurants/';

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fetchRestaurants();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _search.text.toLowerCase();

    setState(() {
      filteredRestaurants = restaurants.where((r) {
        final name = (r['first_name'] ?? '').toLowerCase();
        final desc = (r['description'] ?? '').toLowerCase();
        final cat = r['category'] ?? '';

        return (name.contains(query) || desc.contains(query)) &&
            (selectedCategory == 'Tous' || cat == selectedCategory);
      }).toList();
    });
  }

  Future<void> fetchRestaurants() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(Uri.parse(baseUrl));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          restaurants = data;
          filteredRestaurants = data;
          isLoading = false;
        });

        _anim.forward(from: 0);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // 🔥 HEADER PREMIUM
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Découvrez",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    "Restaurants autour de vous",
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: kTextSecondary,
                    ),
                  ),
                  Gap(2.h),

                  // 🔍 SEARCH
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: kOrange),
                        hintText: "Rechercher un restaurant...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🧩 CATEGORIES
            SizedBox(
              height: 6.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = cat == selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                        _filter();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: 3.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [kOrange, Colors.deepOrangeAccent])
                            : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (selected)
                            BoxShadow(
                              color: kOrange.withOpacity(0.3),
                              blurRadius: 10,
                            )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(
                            color: selected ? Colors.white : kTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Gap(2.h),

            // 🍽 LIST
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: kOrange),
                    )
                  : filteredRestaurants.isEmpty
                      ? Center(
                          child: Text(
                            "Aucun restaurant",
                            style: GoogleFonts.poppins(
                                color: kTextSecondary),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: filteredRestaurants.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 4.w,
                            mainAxisSpacing: 2.h,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (_, i) {
                            return FadeTransition(
                              opacity: _anim,
                              child: _card(filteredRestaurants[i]),
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }

  // 🍔 CARD PREMIUM
  Widget _card(Map<String, dynamic> r) {
    final name =
        "${r['first_name'] ?? ''} ${r['last_name'] ?? ''}".trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => Restopage(restaurant: r),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
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
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  'assets/images/n.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Gap(0.5.h),
                  Row(
                    children: [
                      Icon(Icons.star, color: kOrange, size: 14),
                      Gap(1.w),
                      Text("4.6",
                          style: GoogleFonts.poppins(
                              color: kTextSecondary)),
                      const Spacer(),
                      Text(
                        "25-35 min",
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: kTextSecondary,
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
}