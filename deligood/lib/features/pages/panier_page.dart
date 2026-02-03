import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/pages/confirm_order_page.dart';

// ================== MODELE PANIER ==================
class CartItem {
  final int id;
  final int menuItemId;
  final String name;
  final String image;
  final int quantity;
  final double price;
  final int restaurantId;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    required this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      menuItemId: json['menu_item'],
      name: json['menu_item_name'],
      image: json['menu_item_image'] ?? 'assets/images/n.png',
      quantity: json['quantity'],
      price: (json['menu_item_price'] as num).toDouble(),
      restaurantId: json['restaurant_id'],
    );
  }
}

// ================== PAGE PANIER ==================
class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CartItem>> _futureCart;
  late final AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadCart();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  void _loadCart() {
    _futureCart = PanierApi.fetchCart().then((data) {
      return data.map((e) => CartItem.fromJson(e)).toList();
    });
  }

  Future<void> removeItem(int itemId) async {
    try {
      await PanierApi.removeCartItem(itemId);
      setState(() {
        _loadCart();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur suppression item : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> onConfirmOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/users/profile/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );

      if (response.statusCode != 200) throw Exception("Impossible de récupérer le profil");

      final user = jsonDecode(response.body);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmOrderPage(
            firstName: user['first_name'] ?? '',
            lastName: user['last_name'] ?? '',
            phoneNumber: user['phone_number'] ?? '',
            locality: user['locality'] ?? '',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil utilisateur incomplet"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          "Mon Panier",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _futureCart,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                "Votre panier est vide 🛒",
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
            );
          }

          final total = items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];

                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _listAnimationController,
                          curve: Interval(index / items.length, 1.0, curve: Curves.easeOut),
                        ),
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1).animate(
                          CurvedAnimation(
       parent: _listAnimationController,
                            curve: Interval(index / items.length, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.image,
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        "${item.quantity} x ${item.price.toStringAsFixed(0)} FCFA",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => removeItem(item.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3.h),
                    topRight: Radius.circular(3.h),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          "${total.toStringAsFixed(0)} FCFA",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    GestureDetector(
                      onTap: onConfirmOrder,
                      child: Container(
                        height: 6.h,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(3.h),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Commander",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
