import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:deligood/features/client/screens/ConfirmOrderPage.dart';

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

// ================== MODELE UTILISATEUR ==================
class UserInfo {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String locality;

  UserInfo({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.locality,
  });
}

// ================== PAGE PANIER ==================
class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  late Future<List<CartItem>> _futureCart;

  final String cartBaseUrl =
      'https://deligood-backend.onrender.com//api/orders/cart';

  @override
  void initState() {
    super.initState();
    _futureCart = fetchCartItems();
  }

  // ================== TOKEN ==================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    print("🔐 TOKEN: $token");

    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }
    return token;
  }

  // ================== FETCH PANIER ==================
  Future<List<CartItem>> fetchCartItems() async {
    final token = await _getToken();

    print("📡 Fetch panier...");

    final response = await http.get(
      Uri.parse('$cartBaseUrl/'),
      headers: {'Authorization': 'Token $token'},
    );

    print("📥 Panier status: ${response.statusCode}");
    print("📦 Panier body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Erreur chargement panier");
    }

    final List data = jsonDecode(response.body);
    print("🛒 Nombre d’articles: ${data.length}");

    return data.map((e) => CartItem.fromJson(e)).toList();
  }

  // ================== SUPPRIMER ARTICLE ==================
  Future<void> removeFromCart(int cartItemId) async {
    final token = await _getToken();

    print("🗑 Suppression item ID: $cartItemId");

    final response = await http.delete(
      Uri.parse('$cartBaseUrl/$cartItemId/delete/'),
      headers: {'Authorization': 'Token $token'},
    );

    print("🗑 Delete status: ${response.statusCode}");

    setState(() {
      _futureCart = fetchCartItems();
    });
  }

  // ================== FETCH UTILISATEUR ==================
  Future<UserInfo> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = prefs.getString('first_name');
    final lastName = prefs.getString('last_name');
    final phoneNumber = prefs.getString('phone_number');
    final locality = prefs.getString('locality');

    print("👤 USER INFO:");
    print("   Prénom: $firstName");
    print("   Nom: $lastName");
    print("   Téléphone: $phoneNumber");
    print("   Localité: $locality");

    if (firstName == null ||
        lastName == null ||
        phoneNumber == null ||
        locality == null) {
      throw Exception("Informations utilisateur manquantes");
    }

    return UserInfo(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      locality: locality,
    );
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
            print("❌ PANIER ERROR: ${snapshot.error}");
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            print("🛒 Panier vide");
            return const Center(child: Text("Votre panier est vide 🛒"));
          }

          final total = items.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );

          print("💰 Total panier: $total");

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
                              item.image,
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
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
                    Container(
                      padding: EdgeInsets.all(4.w),
                      child: SlideToConfirmOrder(
                        isLoading:
                            false, // si tu veux gérer le loader, tu peux créer un bool isLoading
                        onConfirm: () async {
                          print("➡️ Slide COMMANDER confirmé");
                          try {
                            final user = await fetchUserInfo();

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmOrderPage(
                                  firstName: user.firstName,
                                  lastName: user.lastName,
                                  phoneNumber: user.phoneNumber,
                                  locality: user.locality,
                                ),
                              ),
                            );
                          } catch (e) {
                            print("❌ ERREUR USER INFO: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Profil utilisateur incomplet"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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

// ================== BOUTON SLIDE POUR COMMANDER ==================
class SlideToConfirmOrder extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onConfirm;

  const SlideToConfirmOrder({
    super.key,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  State<SlideToConfirmOrder> createState() => _SlideToConfirmOrderState();
}

class _SlideToConfirmOrderState extends State<SlideToConfirmOrder> {
  double dragPosition = 0.0;
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 8.w;

    return Stack(
      children: [
        // BACKGROUND
        Container(
          height: 6.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3.h),
          ),
        ),

        // PROGRESS BAR
        Positioned(
          left: 0,
          child: Container(
            height: 6.h,
            width: dragPosition + 6.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(3.h),
            ),
          ),
        ),

        // TEXTE
        Container(
          height: 6.h,
          alignment: Alignment.center,
          child: widget.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  confirmed ? "Commande confirmée !" : "Glisser pour commander",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),

        // SLIDER
        Positioned(
          left: dragPosition,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragPosition += details.delta.dx;
                if (dragPosition < 0) dragPosition = 0;
                if (dragPosition > width - 6.h) dragPosition = width - 6.h;
              });
            },
            onHorizontalDragEnd: (details) async {
              if (dragPosition >= width - 6.h - 5) {
                // SLIDE COMPLET
                setState(() {
                  confirmed = true;
                  dragPosition = width - 6.h;
                });

                widget.onConfirm();

                Future.delayed(const Duration(milliseconds: 800), () {
                  setState(() {
                    confirmed = false;
                    dragPosition = 0.0;
                  });
                });
              } else {
                setState(() => dragPosition = 0.0);
              }
            },
            child: Container(
              height: 6.h,
              width: 6.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: confirmed
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.arrow_forward, color: Colors.deepOrange),
            ),
          ),
        ),
      ],
    );
  }
}

class ConfirmOrderPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String locality;
  final String phoneNumber;

  const ConfirmOrderPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.locality,
    required this.phoneNumber,
  });

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  bool _isLoading = false;

  final String orderUrl =
      'https://deligood-backend.onrender.com//api/orders/orders/create/';
  final String clearCartUrl =
      'https://deligood-backend.onrender.com//api/cart/clear/';

  // ================== TOKEN ==================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }
    return token;
  }

  // ================== CLEAR CART BACKEND ==================
  Future<void> clearCartBackend() async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(clearCartUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Échec suppression panier");
    }
  }

  // ================== CLEAR CART LOCAL ==================
  Future<void> clearCartLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    await prefs.remove('cart_items');
    await prefs.remove('cart_count');
  }

  // ================== CONFIRM ORDER ==================
  Future<void> confirmOrder() async {
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(orderUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "first_name": widget.firstName,
          "last_name": widget.lastName,
          "locality": widget.locality,
          "phone_number": widget.phoneNumber,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 🔥 nettoyage total panier
        await clearCartBackend();
        await clearCartLocal();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Commande confirmée avec succès ✅"),
            backgroundColor: Colors.green,
          ),
        );

        // retour page d'accueil
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception("Erreur lors de la confirmation");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation de commande"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Récapitulatif",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3.h),

            _infoTile("Nom", "${widget.firstName} ${widget.lastName}"),
            _infoTile("Téléphone", widget.phoneNumber),
            _infoTile("Localité", widget.locality),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: Size(double.infinity, 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : confirmOrder,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "Confirmer la commande",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== INFO TILE ==================
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
