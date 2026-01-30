import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
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

class _PanierPageState extends State<PanierPage> {
  late Future<List<CartItem>> _futureCart;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    print("🔄 Chargement du panier...");
    _futureCart = LivreurApi.fetchCart().then((data) {
      print("✅ Panier chargé avec ${data.length} items");
      return data.map((e) => CartItem.fromJson(e)).toList();
    });
  }

  Future<void> removeItem(int itemId) async {
    print("🗑️ Suppression de l'item $itemId...");
    try {
      await LivreurApi.removeCartItem(itemId);
      print("✅ Item $itemId supprimé");
      setState(() {
        _loadCart();
      });
    } catch (e) {
      print("❌ Erreur suppression item $itemId: $e");
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
    print("🔑 Token trouvé: $token");
    
    print("🛠️ Tentative récupération du profil utilisateur...");
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/users/profile/'), // <-- URL correcte
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 200) {
      print("❌ Profil non trouvé: ${response.statusCode} ${response.body}");
      throw Exception("Impossible de récupérer le profil");
    }

    final user = jsonDecode(response.body);
    print("✅ Profil récupéré: $user");

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
  } catch (e) {
    if (!mounted) return;
    print("❌ Erreur récupération profil utilisateur: $e");
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
        title: const Text(
          "Mon Panier",
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _futureCart,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("⏳ En attente du panier...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("❌ Erreur chargement panier: ${snapshot.error}");
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            print("🛒 Panier vide");
            return const Center(
              child: Text(
                "Votre panier est vide 🛒",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final total = items.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );
          print("💰 Total panier: $total FCFA");

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2.h),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    "${item.quantity} x ${item.price.toStringAsFixed(0)} FCFA",
                                    style: TextStyle(
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Text(
                          "${total.toStringAsFixed(0)} FCFA",
                          style: TextStyle(
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
                              color: Colors.deepOrange.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Commander",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            fontFamily: 'Roboto',
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
