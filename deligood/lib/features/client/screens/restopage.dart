import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 COLORS
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Colors.black54;

class Restopage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const Restopage({super.key, required this.restaurant});

  @override
  State<Restopage> createState() => _RestopageState();
}

class _RestopageState extends State<Restopage> with TickerProviderStateMixin {
  List menus = [];
  List<Map> cart = [];

  bool loading = true;

  String? token;

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    initAuth();
  }

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("access_token");
    await fetchMenus();
  }

  Future<void> fetchMenus() async {
    final id = widget.restaurant['id'];
    final url =
        "https://deligood-backend.onrender.com/api/menu/items/?restaurant_id=$id";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      menus = data is List ? data : data['results'] ?? [];
    }

    setState(() => loading = false);
    _anim.forward();
  }

  void addToCart(Map item) {
    setState(() => cart.add(item));
  }

  double get totalPrice {
    double total = 0;

    for (var item in cart) {
      final p = item['price'];
      if (p is String) total += double.tryParse(p) ?? 0;
      if (p is int) total += p;
      if (p is double) total += p;
    }

    return total;
  }

  Future<void> sendCart() async {
    if (token == null) return;

    final url = "https://deligood-backend.onrender.com/api/orders/cart/add/";

    for (var item in cart) {
      await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
        body: jsonEncode({"menu_id": item['id'], "quantity": 1}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        "${widget.restaurant['first_name']} ${widget.restaurant['last_name']}";

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Column(
            children: [
              // 🔥 HEADER IMAGE + TITLE
              Container(
                height: 30.h,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/n.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 🍔 MENU LIST
              Expanded(
                child: loading
                    ? Center(child: CircularProgressIndicator(color: kOrange))
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: menus.length,
                        itemBuilder: (_, i) {
                          return FadeTransition(
                            opacity: _anim,
                            child: _card(menus[i]),
                          );
                        },
                      ),
              ),
            ],
          ),

          // 🛒 BOTTOM BAR PREMIUM
          if (cart.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 💰 TOTAL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${cart.length} articles",
                            style: GoogleFonts.poppins(
                              color: kTextSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            "${totalPrice.toStringAsFixed(0)} FCFA",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🚀 BUTTON
                    ElevatedButton(
                      onPressed: sendCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Commander",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  // 🍽 CARD FOOD PREMIUM
  Widget _card(Map m) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // 🖼 IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: Image.asset(
              'assets/images/n.png',
              width: 22.w,
              height: 10.h,
              fit: BoxFit.cover,
            ),
          ),

          // 📄 INFOS
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${m['name']}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Gap(0.5.h),
                  Text(
                    "${m['price']} FCFA",
                    style: GoogleFonts.poppins(
                      color: kOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ➕ ADD BUTTON
          GestureDetector(
            onTap: () => addToCart(m),
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: kOrange),
            ),
          ),
        ],
      ),
    );
  }
}
