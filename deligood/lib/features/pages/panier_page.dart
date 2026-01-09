import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "http://deligood-production.up.railway.app";

// ================== MODELE ==================
class CartItem {
  final int id;
  final int menuItemId;
  final String name;
  final String imageUrl;
  int quantity;
  final double price;
  final int restaurantId;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      menuItemId: json['menu_item'],
      name: json['menu_item_name'],
      imageUrl: json['menu_item_image_url'] ?? '',
      quantity: json['quantity'],
      price: (json['menu_item_price'] as num).toDouble(),
      restaurantId: json['restaurant_id'],
    );
  }
}

// ================== PAGE ==================
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
    _futureCart = fetchCartItems();
  }

  // ================== TOKEN ==================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Utilisateur non connecté");
    return token;
  }

  // ================== FETCH PANIER ==================
 Future<List<CartItem>> fetchCartItems() async {
  final token = await _getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/cart/'),
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode != 200) {
    throw Exception("Erreur chargement panier");
  }

  final List data = jsonDecode(response.body);
  return data.map((e) => CartItem.fromJson(e)).toList();
}

Future<void> createOrder(List<CartItem> items) async {
  final token = await _getToken();

  final body = {
    "restaurant_id": items.first.restaurantId,
    "items": items
        .map((i) => {"menu_item_id": i.menuItemId, "quantity": i.quantity})
        .toList(),
  };

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/orders/create/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 201) {
    debugPrint(response.body);
    throw Exception("Erreur création commande");
  }

  // vider panier côté backend
  await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/cart/clear/'),
    headers: {'Authorization': 'Token $token'},
  );

  setState(() {
    _futureCart = fetchCartItems();
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Commande validée ✅"),
      backgroundColor: Colors.green,
    ),
  );

  
}
 Future<void> removeFromCart(int cartItemId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$cartItemId/delete/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _futureCart = fetchCartItems();
      });
    }
  }


  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Panier"),
        backgroundColor: Colors.deepOrange,
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
            return const Center(child: Text("Votre panier est vide 🛒"));
          }

          final total = items.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Row(
                          children: [
                            Image.network(
                              item.imageUrl,
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(width: 20.w, color: Colors.grey),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    "${(item.price * item.quantity).toStringAsFixed(0)} FCFA",
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeFromCart(item.id),
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
                color: Colors.deepOrange.shade100,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${total.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                      onPressed: () => createOrder(items),
                      child: const Text("Commander"),
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
