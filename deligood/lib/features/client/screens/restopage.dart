import 'dart:convert';
import 'package:deligood/features/pages/panier_page.dart';
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

const String _baseUrl = 'https://deligood-backend.onrender.com';

class Restopage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const Restopage({super.key, required this.restaurant});

  @override
  State<Restopage> createState() => _RestopageState();
}

class _RestopageState extends State<Restopage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> menus = [];
  List<Map<String, dynamic>> cart = [];
  bool loading = true;
  bool sending = false;
  String? token;

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initAuth();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    await _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    final id = widget.restaurant['id'];
    final url = '$_baseUrl/api/menu/items/?restaurant_id=$id';

    debugPrint('🍔 Fetching menus for restaurant ID: $id');

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      debugPrint('📦 Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final rawList = data is List ? data : (data['results'] ?? []);

        menus = rawList.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"] ?? 0,
            "name": e["name"] ?? e["menu_item_name"] ?? e["title"] ?? "Produit",
            "price": _parsePrice(e["price"] ?? e["menu_item_price"] ?? 0),
            "image": e["image"] ?? e["menu_item_image"] ?? "",
          };
        }).toList();

        debugPrint('✅ Menus normalisés: ${menus.length}');
      }
    } catch (e) {
      debugPrint('❌ fetchMenus error: $e');
    }

    if (!mounted) return;
    setState(() => loading = false);
    _anim.forward();
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add({
        "id": item['id'],
        "name": item['name'],
        "price": item['price'],
        "image": item['image'],
        "quantity": 1,
      });
    });
    _showSnackBar('${item['name']} ajouté au panier', isError: false);
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      final idx = cart.lastIndexWhere((e) => e['id'] == item['id']);
      if (idx != -1) cart.removeAt(idx);
    });
  }

  int _quantityInCart(Map<String, dynamic> item) =>
      cart.where((e) => e['id'] == item['id']).length;

  double get totalPrice {
    return cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _sendCart() async {
    if (sending) return;
    if (token == null) {
      _showSnackBar('Non connecté. Veuillez vous reconnecter.', isError: true);
      return;
    }
    if (cart.isEmpty) {
      _showSnackBar('Votre panier est vide.', isError: true);
      return;
    }

    setState(() => sending = true);

    // Préparer les données dans le format attendu par l'API
    final List<Map<String, dynamic>> itemsToSend = [];
    final Map<int, int> quantityMap = {};

    // Compter les quantités
    for (var item in cart) {
      final id = item['id'] as int;
      quantityMap[id] = (quantityMap[id] ?? 0) + 1;
    }

    // Créer la structure attendue
    for (var entry in quantityMap.entries) {
      final menuItem = menus.firstWhere((m) => m['id'] == entry.key);
      itemsToSend.add({
        'menu_item_id': entry.key,
        'quantity': entry.value,
        'menu_item': {
          'id': menuItem['id'],
          'name': menuItem['name'],
          'price': menuItem['price'],
          'image': menuItem['image'],
        }
      });
    }

    bool success = true;

    for (final item in itemsToSend) {
      try {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/orders/cart/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token!',
          },
          body: jsonEncode({
            'menu_item_id': item['menu_item_id'],
            'quantity': item['quantity'],
          }),
        ).timeout(const Duration(seconds: 15));

        debugPrint('📬 STATUS => ${res.statusCode} | BODY => ${res.body}');

        if (res.statusCode != 200 && res.statusCode != 201) {
          success = false;
          debugPrint('❌ Échec item ${item['menu_item_id']}: ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Erreur réseau item ${item['menu_item_id']}: $e');
        success = false;
      }
    }

    if (!mounted) return;
    setState(() => sending = false);

    if (success) {
      setState(() => cart.clear());
      _showSnackBar('Panier envoyé avec succès ✅', isError: false);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PanierPage(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      _showSnackBar('Erreur lors de l\'envoi. Réessayez.', isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        '${widget.restaurant['first_name']} ${widget.restaurant['last_name']}';

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Column(
            children: [
              // Header image + titre
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
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(0.5.h),
                        if (widget.restaurant['locality'] != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${widget.restaurant['locality']}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        Gap(1.h),
                      ],
                    ),
                  ),
                ),
              ),

              // Liste des menus
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: kOrange),
                      )
                    : menus.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_meals_rounded,
                                  size: 52,
                                  color: Colors.grey.shade300,
                                ),
                                Gap(2.h),
                                Text(
                                  'Aucun plat disponible',
                                  style: GoogleFonts.poppins(color: kTextSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              4.w,
                              2.h,
                              4.w,
                              cart.isNotEmpty ? 14.h : 2.h,
                            ),
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

          // Bottom bar panier
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
                    // Infos total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.length} article${cart.length > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              color: kTextSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            '${totalPrice.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bouton commander
                    ElevatedButton(
                      onPressed: sending ? null : _sendCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        disabledBackgroundColor: kOrange.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        elevation: 0,
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Commander',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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

  Widget _card(Map<String, dynamic> m) {
    final qty = _quantityInCart(m);

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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: m['image'] != null && m['image'].toString().isNotEmpty
                ? Image.network(
                    m['image'].toString(),
                    width: 22.w,
                    height: 10.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/n.png',
                      width: 22.w,
                      height: 10.h,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/n.png',
                    width: 22.w,
                    height: 10.h,
                    fit: BoxFit.cover,
                  ),
          ),

          // Infos
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name'] ?? 'Produit',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Gap(0.5.h),
                  Text(
                    '${m['price'].toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                      color: kOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contrôle quantité
          Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: qty == 0
                ? GestureDetector(
                    onTap: () => _addToCart(m),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: kOrange),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyBtn(
                        icon: Icons.remove,
                        onTap: () => _removeFromCart(m),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          '$qty',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      _qtyBtn(icon: Icons.add, onTap: () => _addToCart(m)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kOrange.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kOrange, size: 16),
      ),
    );
  }
}