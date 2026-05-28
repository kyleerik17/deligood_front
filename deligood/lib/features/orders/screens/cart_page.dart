import 'dart:convert';

import 'package:deligood/core/network/api.dart' show Api;

import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/payments/screens/payment_page.dart';
import 'package:deligood/widgets/premium_ui.dart';

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
  static String get _baseUrl => Api.baseUrl;
  static const Duration _timeout = Duration(seconds: 20);

  static String fixImageUrl(String? raw) {
    return Api.resolveMediaUrl(raw);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🔑 HEADERS avec logs de diagnostic complets
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();

      // ── DIAGNOSTIC BLOC START ──────────────────────────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════╗');
      debugPrint('║  🔑  AUTH HEADERS DIAGNOSTIC                     ║');
      debugPrint('╠══════════════════════════════════════════════════╣');

      // Liste toutes les clés présentes dans SharedPreferences
      final allKeys = prefs.getKeys();
      debugPrint('║  📦  Toutes les clés SharedPrefs: $allKeys');

      // Tentative de lecture du token avec la clé attendue
      final token = prefs.getString('access_token');
      if (token == null) {
        debugPrint('║  ❌  access_token = NULL  ← TOKEN ABSENT');
        debugPrint('║      → Vérifiez que la clé utilisée lors de la');
        debugPrint('║        connexion est bien "access_token".');
        debugPrint('║      → Sur Flutter Web, vérifiez localStorage');
        debugPrint('║        dans DevTools → Application → Storage.');
      } else if (token.isEmpty) {
        debugPrint('║  ⚠️   access_token = "" (chaîne vide)');
      } else {
        debugPrint('║  ✅  access_token trouvé (${token.length} chars)');
        debugPrint(
          '║      Début: ${token.substring(0, token.length.clamp(0, 20))}…',
        );
      }

      // Vérifie aussi d'autres noms de clés courants au cas où
      final altKeys = ['token', 'auth_token', 'authToken', 'jwt', 'Bearer'];
      for (final k in altKeys) {
        final v = prefs.getString(k);
        if (v != null && v.isNotEmpty) {
          debugPrint(
            '║  ⚠️   Clé alternative trouvée: "$k" (${v.length} chars)',
          );
          debugPrint('║      → Vous sauvegardez peut-être sous "$k"');
          debugPrint('║        mais lisez sous "access_token" !');
        }
      }

      // Infos utilisateur présentes
      final firstName = prefs.getString('first_name');
      final phone = prefs.getString('phone_number');
      debugPrint('║  👤  first_name: ${firstName ?? "absent"}');
      debugPrint('║  📱  phone_number: ${phone ?? "absent"}');
      debugPrint('╚══════════════════════════════════════════════════╝');
      debugPrint('');
      // ── DIAGNOSTIC BLOC END ───────────────────────────────────────────

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = Api.authHeaderValue(token);
      } else {
        // Token absent : on throw pour que l'appelant puisse réagir
        // (rediriger vers login, afficher un message, etc.)
        throw Exception(
          '⛔ Non authentifié : access_token absent de SharedPreferences.\n'
          'Clés présentes : $allKeys',
        );
      }
    }

    return headers;
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    final status = response.statusCode;
    final body = response.body;

    debugPrint('');
    debugPrint(
      '📬 CART ITEM ${response.hashCode} => $status | '
      '${body.length > 120 ? '${body.substring(0, 120)}…' : body}',
    );

    if (body.isEmpty) {
      if (status >= 200 && status < 300) return null;
      throw Exception('Empty response from server ($status)');
    }
    if (body.trim().startsWith('<')) {
      throw Exception('Server returned HTML instead of JSON');
    }
    try {
      final data = jsonDecode(body);
      if (status >= 200 && status < 300) return data;
      if (data is Map) {
        final msg =
            data['detail'] ??
            data['message'] ??
            data['error'] ??
            'Unknown error';
        throw Exception(msg is String ? msg : msg.toString());
      }
      throw Exception('Server error ($status)');
    } catch (e) {
      throw Exception('Failed to parse response: ${e.toString()}');
    }
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
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
    debugPrint('🌐 GET $uri');
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
                  fontSize: 11.sp,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _CircleIcon(icon: Icons.refresh_rounded, onTap: onRefresh),
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
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, color: kOrange),
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
      itemBuilder: (_, i) => CartItemWidget(
        item: items[i],
        animation: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(i / items.length, 1, curve: Curves.easeOut),
          ),
        ),
      ),
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
  final String message;
  final VoidCallback onRetry;
  final bool isAuthError;

  const CartError({
    super.key,
    required this.message,
    required this.onRetry,
    this.isAuthError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuthError ? Icons.lock_outline_rounded : Icons.wifi_off_rounded,
              color: isAuthError ? kOrange : Colors.red,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              isAuthError
                  ? 'Session expirée'
                  : 'Impossible de charger le panier',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: kTextSecondary,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 2.h),
            if (isAuthError)
              ElevatedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (_) => false),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  'Se reconnecter',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
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
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(color: kTextSecondary)),
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
  bool _isAuthError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logSharedPrefsOnInit(); // ← diagnostic au démarrage de la page
    _loadCart();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🔍 Diagnostic SharedPreferences au moment de l'init
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _logSharedPrefsOnInit() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════╗');
    debugPrint('║  🚀  PanierPage initState — DIAGNOSTIC               ║');
    debugPrint('╠══════════════════════════════════════════════════════╣');
    debugPrint('║  📦  Nb de clés dans SharedPrefs : ${allKeys.length}');
    debugPrint('║  🗝️   Clés: $allKeys');
    debugPrint('║');

    // Vérification du token
    final token = prefs.getString('access_token');
    if (token == null) {
      debugPrint('║  ❌  access_token : ABSENT');
      debugPrint('║      Le token n\'a jamais été sauvegardé sous cette clé.');
    } else if (token.isEmpty) {
      debugPrint('║  ⚠️   access_token : VIDE (chaîne vide)');
    } else {
      debugPrint('║  ✅  access_token : OK — ${token.length} caractères');
    }

    // Vérifie les clés alternatives
    for (final k in [
      'token',
      'auth_token',
      'authToken',
      'jwt',
      'Bearer',
      'userToken',
    ]) {
      final v = prefs.getString(k);
      if (v != null && v.isNotEmpty) {
        debugPrint(
          '║  ⚠️   Clé alternative "$k" trouvée ! (${v.length} chars)',
        );
        debugPrint(
          '║      → Probablement la bonne clé, mais mal nommée côté lecture.',
        );
      }
    }

    // Infos profil
    final firstName = prefs.getString('first_name');
    final lastName = prefs.getString('last_name');
    final phone = prefs.getString('phone_number');
    final locality = prefs.getString('locality');
    debugPrint('║');
    debugPrint('║  👤  first_name   : ${firstName ?? "absent"}');
    debugPrint('║  👤  last_name    : ${lastName ?? "absent"}');
    debugPrint('║  📱  phone_number : ${phone ?? "absent"}');
    debugPrint('║  📍  locality     : ${locality ?? "absent"}');
    debugPrint('╚══════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  void _loadCart() {
    setState(() {
      _isAuthError = false;
      _errorMessage = '';
    });
    _futureCart = _fetchCart()
        .then((items) {
          _anim.forward(from: 0);
          return items;
        })
        .catchError((error) {
          debugPrint("❌ Error loading cart: $error");
          throw error;
        });
    setState(() {});
  }

  Future<List<CartItem>> _fetchCart() async {
    try {
      debugPrint('🛒 Fetching cart from /api/orders/cart/');
      final data = await ApiService.get('/api/orders/cart/');

      if (data is List) {
        debugPrint('✅ Cart loaded: ${data.length} items (List)');
        return data.map((item) => CartItem.fromJson(item)).toList();
      } else if (data is Map && data['results'] != null) {
        final list = data['results'] as List;
        debugPrint('✅ Cart loaded: ${list.length} items (Map.results)');
        return list.map((item) => CartItem.fromJson(item)).toList();
      }
      debugPrint('⚠️  Cart response format inconnu: ${data.runtimeType}');
      return [];
    } catch (e) {
      final msg = e.toString();
      debugPrint("❌ Failed to fetch cart: $msg");

      // Détecte si c'est une erreur d'authentification
      final isAuth =
          msg.contains('Non authentifié') ||
          msg.contains('access_token') ||
          msg.contains('401') ||
          msg.contains('Authentication credentials');

      if (isAuth && mounted) {
        setState(() {
          _isAuthError = true;
          _errorMessage = msg.replaceAll('Exception: ', '');
        });
      }

      throw Exception('Failed to load cart: $msg');
    }
  }

  double _total(List<CartItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  // ──────────────────────────────────────────────────────────────────────────
  // Commander → confirme la commande puis navigue vers le backend actuel
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _commander(double total, List<CartItem> items) async {
    if (_ordering) return;
    if (!mounted) return;

    setState(() => _ordering = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? '';
      final lastName = prefs.getString('last_name') ?? '';
      final phone = prefs.getString('phone_number') ?? '';
      final locality = prefs.getString('locality') ?? 'Grand-Bassam';

      debugPrint('');
      debugPrint('╔════════════════════════════════════════════════╗');
      debugPrint('║  🛒  COMMANDER — données utilisateur           ║');
      debugPrint('╠════════════════════════════════════════════════╣');
      debugPrint('║  first_name  : $firstName');
      debugPrint('║  last_name   : $lastName');
      debugPrint('║  phone       : $phone');
      debugPrint('║  locality    : $locality');
      debugPrint('╚════════════════════════════════════════════════╝');
      debugPrint('');

      final result = await ApiService.post(
        '/api/orders/client/create/',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phone,
          'locality': locality,
        },
      );

      debugPrint("✅ Order confirmation result: $result");

      final orderId = result is Map ? result['order_id'] ?? result['id'] : null;
      final parsedOrderId = int.tryParse(orderId?.toString() ?? '');
      debugPrint("Order id extrait: $orderId");

      if (!mounted) return;

      _showSnackBar('Commande passee avec succes');
      setState(() => _ordering = false);
      if (parsedOrderId != null && parsedOrderId > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              orderTotal: total,
              orderId: parsedOrderId,
              orderItems: items
                  .map(
                    (item) => CartSummaryItem(
                      name: item.name,
                      quantity: item.quantity,
                      price: item.price,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }
      if (mounted) _loadCart();
    } catch (e) {
      debugPrint("❌ Order error: $e");
      if (!mounted) return;

      final msg = e.toString().replaceAll('Exception: ', '');
      final isAuth =
          msg.contains('Non authentifié') ||
          msg.contains('access_token') ||
          msg.contains('401');

      if (isAuth) {
        // Redirection automatique vers le login
        _showSnackBar('Session expirée. Reconnexion…', error: true);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      } else {
        _showSnackBar('Échec de la commande: $msg', error: true);
        setState(() => _ordering = false);
      }
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
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: FutureBuilder<List<CartItem>>(
        future: _futureCart,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final items = snapshot.data ?? const <CartItem>[];
          final total = _total(items);

          return Column(
            children: [
              PremiumTopBar(
                eyebrow: 'Checkout',
                title: 'Votre panier',
                subtitle: items.isEmpty
                    ? 'Préparez votre prochaine commande.'
                    : '${items.length} article(s) prêts à commander.',
                actionIcon: Icons.refresh_rounded,
                onAction: _loadCart,
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (loading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.orange,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return CartError(
                        message: _errorMessage.isNotEmpty
                            ? _errorMessage
                            : snapshot.error.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                        onRetry: _loadCart,
                        isAuthError: _isAuthError,
                      );
                    }
                    if (items.isEmpty) return const EmptyCart();

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        1.4.h,
                        AppSpacing.page,
                        17.h,
                      ),
                      itemBuilder: (_, i) => _premiumCartItem(items[i]),
                      separatorBuilder: (_, __) => SizedBox(height: 1.4.h),
                      itemCount: items.length,
                    );
                  },
                ),
              ),
              if (!loading && items.isNotEmpty)
                _premiumCheckoutBar(total, items),
            ],
          );
        },
      ),
    );
  }

  Widget _premiumCartItem(CartItem item) {
    return PremiumCard(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 22.w,
              height: 22.w,
              color: AppColors.surfaceWarm,
              child: item.image.isEmpty
                  ? const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.orange,
                    )
                  : Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.orange,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppText.h3(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: .6.h),
                Text(
                  '${item.quantity} × ${item.price.toStringAsFixed(0)} FCFA',
                  style: AppText.bodySm(),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    PremiumBadge(
                      label: 'Prêt en 25 min',
                      icon: Icons.schedule_rounded,
                      color: AppColors.greenDark,
                    ),
                    const Spacer(),
                    Text(
                      '${item.subtotal.toStringAsFixed(0)} FCFA',
                      style: AppText.price(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumCheckoutBar(double total, List<CartItem> items) {
    return Container(
      margin: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 1.4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline.withValues(alpha: .35)),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: AppText.bodySm()),
                Text(
                  '${total.toStringAsFixed(0)} FCFA',
                  style: AppText.priceLg(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5.8.h,
            child: ElevatedButton.icon(
              onPressed: _ordering ? null : () => _commander(total, items),
              icon: _ordering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_ordering ? 'Validation...' : 'Commander'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.pillRadius,
                ),
              ),
            ),
          ),
        ],
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
      throw Exception('Failed to load cart items');
    }
  }

  static Future<void> removeCartItem(int cartItemId) async {
    try {
      await ApiService.delete('/api/orders/cart/$cartItemId/delete/');
    } catch (e) {
      throw Exception('Failed to remove item from cart');
    }
  }

  static Future<void> clearCart() async {
    try {
      await ApiService.post('/api/orders/cart/clear/');
    } catch (e) {
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
        '/api/orders/client/create/',
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
      throw Exception('Order confirmation failed: ${e.toString()}');
    }
  }
}
