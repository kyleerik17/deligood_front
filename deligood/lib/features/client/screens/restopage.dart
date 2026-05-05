import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:deligood/features/pages/panier_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/menu_service.dart';

// 🎨 COLORS
const kOrange = Color(0xFFFF6B35);
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
    debugPrint('🆔 ID restaurant: $id');

    // ✅ Utilise MenuService centralisé
    menus = await MenuService.getMenuItems(id);

    debugPrint('✅ Items reçus: ${menus.length}');

    if (!mounted) return;
    setState(() => loading = false);
    _anim.forward();
  }

  // ─── PANIER ───

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final idx = cart.indexWhere((e) => e['id'] == item['id']);
      if (idx != -1) {
        // Incrémenter la quantité si déjà dans le panier
        cart[idx]['quantity'] = (cart[idx]['quantity'] as int) + 1;
      } else {
        cart.add({
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'image': item['image'],
          'quantity': 1,
        });
      }
    });
    _showSnackBar('${item['name']} ajouté au panier', isError: false);
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      final idx = cart.indexWhere((e) => e['id'] == item['id']);
      if (idx == -1) return;
      final qty = cart[idx]['quantity'] as int;
      if (qty <= 1) {
        cart.removeAt(idx);
      } else {
        cart[idx]['quantity'] = qty - 1;
      }
    });
  }

  int _quantityInCart(Map<String, dynamic> item) {
    final idx = cart.indexWhere((e) => e['id'] == item['id']);
    if (idx == -1) return 0;
    return cart[idx]['quantity'] as int;
  }

  double get totalPrice =>
      cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

  int get totalItems =>
      cart.fold(0, (sum, item) => sum + (item['quantity'] as int));

  // ─── ENVOI PANIER ───

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

    bool success = true;

    for (final item in cart) {
      try {
        final res = await _postCartItem(
          menuItemId: item['id'] as int,
          quantity: item['quantity'] as int,
        );
        if (!res) success = false;
      } catch (e) {
        debugPrint('❌ sendCart item error: $e');
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
      _showSnackBar("Erreur lors de l'envoi. Réessayez.", isError: true);
    }
  }

  Future<bool> _postCartItem({
    required int menuItemId,
    required int quantity,
  }) async {
    try {
      final res = await _http().post(
        Uri.parse(
            'https://deligood-backend.onrender.com/api/orders/cart/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: _json({
          'menu_item_id': menuItemId,
          'quantity': quantity,
        }),
      );

      debugPrint(
          '📬 CART ITEM $menuItemId => ${res.statusCode} | ${res.body}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('❌ postCartItem error: $e');
      return false;
    }
  }

  // petits helpers pour éviter import http partout
  http.Client _http() => http.Client();
  String _json(Map<String, dynamic> data) => jsonEncode(data);

  // ─── SNACKBAR ───

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
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final firstName = widget.restaurant['first_name'] ?? '';
    final lastName = widget.restaurant['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();
    final restaurantPhoto =
        MenuService.fixImageUrl(widget.restaurant['photo']?.toString());

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Column(
            children: [
              // ─── HEADER IMAGE ───
              _buildHeader(name, restaurantPhoto),

              // ─── LISTE MENUS ───
              Expanded(child: _buildMenuList()),
            ],
          ),

          // ─── BOTTOM BAR PANIER ───
          if (cart.isNotEmpty) _buildCartBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String restaurantPhoto) {
    return Container(
      height: 30.h,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: restaurantPhoto.isNotEmpty
              ? NetworkImage(restaurantPhoto) as ImageProvider
              : const AssetImage('assets/images/n.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.60),
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
              // Bouton retour
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
                name.isEmpty ? 'Restaurant' : name,
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
    );
  }

  Widget _buildMenuList() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: kOrange),
      );
    }

    if (menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_meals_rounded, size: 52, color: Colors.grey.shade300),
            Gap(2.h),
            Text(
              'Aucun plat disponible',
              style: GoogleFonts.poppins(color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        4.w,
        2.h,
        4.w,
        cart.isNotEmpty ? 14.h : 2.h,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) => FadeTransition(
        opacity: _anim,
        child: _card(menus[i]),
      ),
    );
  }

  Widget _buildCartBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalItems article${totalItems > 1 ? 's' : ''}',
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
                        const Icon(Icons.shopping_cart_rounded,
                            color: Colors.white, size: 18),
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
    );
  }

  // ─── CARD PLAT ───

  Widget _card(Map<String, dynamic> m) {
    final qty = _quantityInCart(m);
    final imageUrl = m['image']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
      child: Row(
        children: [
          // 🖼 Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 22.w,
                    height: 10.h,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _imagePlaceholder(isLoading: true);
                    },
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
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
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((m['description'] ?? '').toString().isNotEmpty) ...[
                    Gap(0.3.h),
                    Text(
                      m['description'],
                      style: GoogleFonts.poppins(
                        color: kTextSecondary,
                        fontSize: 9.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Gap(0.5.h),
                  Text(
                    '${(m['price'] as double).toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                      color: kOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
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
                          onTap: () => _removeFromCart(m)),
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
                      _qtyBtn(
                          icon: Icons.add, onTap: () => _addToCart(m)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder({bool isLoading = false}) {
    return Container(
      width: 22.w,
      height: 10.h,
      color: Colors.grey.shade100,
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(color: kOrange, strokeWidth: 2)
            : Image.asset(
                'assets/images/n.png',
                fit: BoxFit.cover,
              ),
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