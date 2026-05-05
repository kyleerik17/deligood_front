import 'dart:convert';
import 'package:deligood/features/client/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 DESIGN SYSTEM
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Colors.grey;

// ================== API SERVICE ==================
class ApiService {
  static const String _baseUrl = 'https://deligood-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 20);

  /// ✅ Corrige les URLs d'images : ajoute le slash manquant si besoin
  static String fixImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    // Assure qu'il y a un slash entre la base et le chemin relatif
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$_baseUrl$path';
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    final status = response.statusCode;
    final body = response.body;

    debugPrint('📦 API Response [$status]: ${body.length > 200 ? '${body.substring(0, 200)}...' : body}');

    if (body.isEmpty) {
      if (status >= 200 && status < 300) return null;
      throw Exception('Empty response from server ($status)');
    }

    if (body.trim().startsWith('<')) {
      throw Exception('Server returned HTML instead of JSON');
    }

    try {
      final data = jsonDecode(body);

      if (status >= 200 && status < 300) {
        return data;
      }

      if (data is Map) {
        final msg = data['detail'] ?? data['message'] ?? data['error'] ?? 'Unknown error';
        throw Exception(msg is String ? msg : msg.toString());
      }

      throw Exception('Server error ($status)');
    } catch (e) {
      throw Exception('Failed to parse response: ${e.toString()}');
    }
  }

  static Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handleResponse(response);
  }
}

// ================== MODELS ==================
class CartItem {
  final int id;
  final String name;
  final String image;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    debugPrint("📦 Parsing CartItem from JSON: $json");

    final int id = json['id'] ?? json['menu_item_id'] ?? 0;
    final String name =
        json['menu_item_name'] ?? json['name'] ?? 'Produit inconnu';

    // ✅ Fix URL image : ajoute le slash manquant
    final String rawImage = json['menu_item_image'] ?? json['image'] ?? '';
    final String image = ApiService.fixImageUrl(rawImage);

    final int quantity = json['quantity'] ?? 1;

    dynamic priceValue = json['menu_item_price'] ?? json['price'] ?? 0;
    double price;
    if (priceValue is String) {
      price = double.tryParse(priceValue) ?? 0;
    } else if (priceValue is int) {
      price = priceValue.toDouble();
    } else if (priceValue is double) {
      price = priceValue;
    } else {
      price = 0;
    }

    return CartItem(
      id: id,
      name: name,
      image: image,
      quantity: quantity,
      price: price,
    );
  }

  double get subtotal => price * quantity;
}

// ================== WIDGETS ==================
class CartHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const CartHeader({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Row(
        children: [
          _CircleIcon(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'Mon panier',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              Text(
                'Vos plats sélectionnés',
                style: GoogleFonts.poppins(
                    fontSize: 11.sp, color: kTextSecondary),
              ),
            ],
          ),
          const Spacer(),
          _CircleIcon(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: kWhite,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Icon(icon, size: 18, color: kTextPrimary),
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Animation<double> animation;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 72,
                color: kBg,
                child: item.image.isNotEmpty
                    ? Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("❌ Error loading image: $error");
                          return const Icon(Icons.fastfood, color: kOrange);
                        },
                      )
                    : const Icon(Icons.fastfood, color: kOrange),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${item.price.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(color: kTextSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.quantity}x',
                style: GoogleFonts.poppins(
                  color: kOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartList extends StatelessWidget {
  final List<CartItem> items;
  final AnimationController animationController;

  const CartList({
    super.key,
    required this.items,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: items.length,
      itemBuilder: (_, i) {
        return CartItemWidget(
          item: items[i],
          animation: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Interval(i / items.length, 1, curve: Curves.easeOut),
            ),
          ),
        );
      },
    );
  }
}

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: kOrange,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Panier vide',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Ajoute des plats pour commencer',
            style: GoogleFonts.poppins(color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

class CartError extends StatelessWidget {
  final VoidCallback onRetry;

  const CartError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 48),
          SizedBox(height: 2.h),
          Text(
            'Impossible de charger le panier',
            style: GoogleFonts.poppins(color: kTextSecondary),
          ),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GoogleFonts.poppins(
                color: kOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartBottom extends StatelessWidget {
  final double total;
  final bool isLoading;
  final VoidCallback onCommand;

  const CartBottom({
    super.key,
    required this.total,
    required this.isLoading,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(color: kTextSecondary),
              ),
              Text(
                '${total.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : onCommand,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                disabledBackgroundColor: kOrange.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Commander',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14.sp,
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
}

// ================== MAIN PAGE ==================
class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CartItem>> _futureCart;
  late AnimationController _anim;
  bool _ordering = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadCart();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _loadCart() {
    _futureCart = _fetchCart().then((items) {
      _anim.forward(from: 0);
      return items;
    }).catchError((error) {
      debugPrint("❌ Error loading cart: $error");
      throw error;
    });
    setState(() {});
  }

  Future<List<CartItem>> _fetchCart() async {
    try {
      final data = await ApiService.get('/api/orders/cart/');

      if (data is List) {
        return data.map((item) => CartItem.fromJson(item)).toList();
      } else if (data is Map && data['results'] != null) {
        return (data['results'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint("❌ Failed to fetch cart: $e");
      throw Exception('Failed to load cart: ${e.toString()}');
    }
  }

  double _total(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _commander() async {
    if (_ordering) return;
    if (!mounted) return;

    setState(() => _ordering = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? '';
      final lastName = prefs.getString('last_name') ?? '';
      final phone = prefs.getString('phone_number') ?? '';
      final locality = prefs.getString('locality') ?? 'Grand-Bassam';

      debugPrint("🛒 Confirming order for: $firstName $lastName");
      debugPrint("📞 Phone: $phone");
      debugPrint("📍 Locality: $locality");

      final result = await ApiService.post(
        '/api/orders/create/',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phone,
          'locality': locality,
        },
      );

      debugPrint("✅ Order confirmation result: $result");

      // ✅ L'API retourne { "message": "...", "order_id": 7, ... }
      // On essaie 'order_id' en priorité, puis 'id' en fallback
      final int? orderId = result['order_id'] ?? result['id'];

      debugPrint("🆔 orderId extrait: $orderId");

      if (!mounted) return;

      _showSnackBar('Commande passée avec succès ✅');

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(orderId: orderId),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      debugPrint("❌ Order error: $e");
      if (!mounted) return;
      _showSnackBar(
        'Échec de la commande: ${e.toString().replaceAll('Exception: ', '')}',
        error: true,
      );
      setState(() => _ordering = false);
    }
  }

  void _showSnackBar(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🏗️ Building PanierPage UI");
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(onRefresh: _loadCart),
            Expanded(
              child: FutureBuilder<List<CartItem>>(
                future: _futureCart,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    debugPrint("⏳ Loading cart data...");
                    return const Center(
                      child: CircularProgressIndicator(color: kOrange),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                        "❌ Error in cart FutureBuilder: ${snapshot.error}");
                    return CartError(onRetry: _loadCart);
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint("📭 Cart is empty");
                    return const EmptyCart();
                  }

                  final items = snapshot.data!;
                  debugPrint("🛒 Displaying ${items.length} cart items");

                  return Column(
                    children: [
                      Expanded(
                        child: CartList(
                          items: items,
                          animationController: _anim,
                        ),
                      ),
                      CartBottom(
                        total: _total(items),
                        isLoading: _ordering,
                        onCommand: _commander,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== PANIER API HELPER ==================
class PanierApi {
  static Future<List<CartItem>> fetchCart() async {
    try {
      final data = await ApiService.get('/api/orders/cart/');

      if (data is List) {
        return data.map((item) => CartItem.fromJson(item)).toList();
      } else if (data is Map && data['results'] != null) {
        return (data['results'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint("❌ Failed to fetch cart: $e");
      throw Exception('Failed to load cart items');
    }
  }

  static Future<void> removeCartItem(int cartItemId) async {
    try {
      await ApiService.delete('/api/orders/cart/$cartItemId/delete/');
    } catch (e) {
      debugPrint("❌ Failed to remove cart item: $e");
      throw Exception('Failed to remove item from cart');
    }
  }

  static Future<void> clearCart() async {
    try {
      await ApiService.post('/api/orders/cart/clear/');
    } catch (e) {
      debugPrint("❌ Failed to clear cart: $e");
      throw Exception('Failed to clear cart');
    }
  }

  static Future<Map<String, dynamic>> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    try {
      final result = await ApiService.post(
        '/api/orders/create/',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'locality': locality,
        },
      );

      await clearCart();
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ Order confirmation failed: $e");
      throw Exception('Order confirmation failed: ${e.toString()}');
    }
  }
}