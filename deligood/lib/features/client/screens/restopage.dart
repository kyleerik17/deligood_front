import 'dart:convert';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/api/menu_service.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/orders/screens/cart_page.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

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

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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

  /// ✅ Version robuste avec logs, parsing sécurisé et gestion d'erreur
  Future<void> _fetchMenus() async {
    final rawId = widget.restaurant['id'];
    debugPrint(
      '🍽️ Tentative de chargement du menu. Restaurant ID brut: $rawId (${rawId.runtimeType})',
    );

    if (rawId == null) {
      debugPrint(
        '⚠️ ID du restaurant manquant. Vérifie les données passées à Restopage.',
      );
      if (mounted) setState(() => loading = false);
      return;
    }

    // Convertit en int si nécessaire (ex: vient de JSON sous forme de String)
    final restaurantId = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (restaurantId == null) {
      debugPrint('❌ ID du restaurant invalide après parsing: $rawId');
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      debugPrint('🌐 Appel MenuService.getMenuItems($restaurantId)');
      final result = await MenuService.getMenuItems(restaurantId);

      if (!mounted) return;

      // Sécurité : garantit que c'est bien une liste de Map
      menus = result.map((e) => Map<String, dynamic>.from(e)).toList();

      debugPrint('✅ ${menus.length} plat(s) reçu(s) pour ID $restaurantId');

      setState(() => loading = false);
      if (menus.isNotEmpty) {
        _anim.forward(from: 0);
      }
    } catch (e, st) {
      debugPrint('❌ Erreur fetchMenus: $e\n$st');
      if (mounted) {
        setState(() {
          loading = false;
          menus = [];
        });
      }
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final idx = cart.indexWhere((e) => e['id'] == item['id']);
      if (idx != -1) {
        cart[idx]['quantity'] = (cart[idx]['quantity'] as int) + 1;
      } else {
        cart.add({
          'id': item['id'],
          'name': item['name'],
          'price': _priceOf(item),
          'image': item['image'],
          'quantity': 1,
        });
      }
    });
    _showSnackBar(
      '${item['name'] ?? 'Produit'} ajouté au panier',
      isError: false,
    );
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
    return idx == -1 ? 0 : cart[idx]['quantity'] as int;
  }

  double _priceOf(Map<String, dynamic> item) {
    final value = item['price'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get totalPrice => cart.fold(
    0.0,
    (sum, item) => sum + (_priceOf(item) * (item['quantity'] as int)),
  );

  int get totalItems =>
      cart.fold(0, (sum, item) => sum + (item['quantity'] as int));

  Future<void> _sendCart() async {
    if (sending) return;

    final prefs = await SharedPreferences.getInstance();
    final freshToken = prefs.getString('access_token');

    if (freshToken == null || freshToken.isEmpty) {
      _showSnackBar('Connectez-vous pour commander.', isError: true);
      return;
    }
    if (cart.isEmpty) {
      _showSnackBar('Votre panier est vide.', isError: true);
      return;
    }

    setState(() => sending = true);

    try {
      final snapshot = List<Map<String, dynamic>>.from(cart);
      var allOk = true;

      for (final item in snapshot) {
        final ok = await _postCartItem(
          menuItemId: item['id'] as int,
          quantity: item['quantity'] as int,
        );
        if (!ok) {
          allOk = false;
          break;
        }
      }

      if (!mounted) return;
      setState(() => sending = false);

      if (allOk) {
        setState(() => cart.clear());
        _showSnackBar('Panier envoyé avec succès', isError: false);
        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PanierPage()),
        );
      } else {
        _showSnackBar('Une erreur est survenue, réessayez.', isError: true);
      }
    } catch (e) {
      debugPrint('send cart error: $e');
      if (!mounted) return;
      setState(() => sending = false);
      _showSnackBar('Erreur réseau.', isError: true);
    }
  }

  Future<bool> _postCartItem({
    required int menuItemId,
    required int quantity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final freshToken = prefs.getString('access_token');
    if (freshToken == null || freshToken.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse('${Api.baseUrl}/api/orders/cart/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Api.authHeaderValue(freshToken),
        },
        body: jsonEncode({'menu_item_id': menuItemId, 'quantity': quantity}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('post cart item error: $e');
      return false;
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
              child: Text(msg, style: AppText.bodySm(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.greenDark,
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _restaurantName(widget.restaurant);
    final restaurantPhoto = MenuService.fixImageUrl(
      (widget.restaurant['photo_url'] ?? widget.restaurant['photo'])
          ?.toString(),
    );

    return PremiumScaffold(
      addSafeArea: false,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(name, restaurantPhoto),
              SliverToBoxAdapter(
                child: _RestaurantSummary(restaurant: widget.restaurant),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    2.h,
                    AppSpacing.page,
                    1.h,
                  ),
                  child: Row(
                    children: [
                      Text('Menu signature', style: AppText.h3()),
                      const Spacer(),
                      const PremiumBadge(
                        label: 'Populaire',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              _buildMenuSliver(),
              SliverToBoxAdapter(
                child: SizedBox(height: cart.isNotEmpty ? 15.h : 3.h),
              ),
            ],
          ),
          if (cart.isNotEmpty) _buildCartBar(),
        ],
      ),
    );
  }

  String _restaurantName(Map<String, dynamic> r) {
    final business = (r['name'] ?? r['restaurant_name'] ?? '')
        .toString()
        .trim();
    if (business.isNotEmpty) return business;
    final name = '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
    return name.isEmpty ? 'Restaurant DeliGood' : name;
  }

  SliverAppBar _buildHeader(String name, String restaurantPhoto) {
    return SliverAppBar(
      expandedHeight: 34.h,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: EdgeInsets.only(left: 3.w),
        child: PremiumIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        PremiumIconButton(icon: Icons.favorite_border_rounded, onTap: () {}),
        SizedBox(width: 3.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            restaurantPhoto.isNotEmpty
                ? Image.network(
                    restaurantPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroFallback(),
                  )
                : _heroFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .15),
                    Colors.black.withValues(alpha: .15),
                    Colors.black.withValues(alpha: .78),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.page,
              right: AppSpacing.page,
              bottom: 2.5.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PremiumBadge(
                    label: 'Top resto',
                    icon: Icons.verified_rounded,
                    color: AppColors.orange,
                  ),
                  Gap(1.h),
                  Text(
                    name,
                    style: AppText.h1(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(.8.h),
                  Text(
                    'Cuisine fraiche - livraison rapide - suivi en direct',
                    style: AppText.bodySm(
                      color: Colors.white.withValues(alpha: .78),
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

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientOrange),
      child: Center(
        child: Image.asset(
          'assets/images/n.png',
          height: 13.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildMenuSliver() {
    if (loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    if (menus.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: PremiumCard(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_meals_rounded,
                  size: 52,
                  color: AppColors.textMuted,
                ),
                Gap(1.5.h),
                Text('Aucun plat disponible', style: AppText.h3()),
                Gap(.8.h),
                Text(
                  'Ce restaurant actualise son menu\nou la connexion a échoué.',
                  style: AppText.body(),
                  textAlign: TextAlign.center,
                ),
                Gap(2.h),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => loading = true);
                    _fetchMenus();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.4.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: SliverList.separated(
        itemCount: menus.length,
        separatorBuilder: (_, __) => Gap(1.4.h),
        itemBuilder: (_, i) {
          final animation = CurvedAnimation(
            parent: _anim,
            curve: Interval(
              (i * .05).clamp(0.0, .72),
              1,
              curve: Curves.easeOutCubic,
            ),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: _MenuCard(
                item: menus[i],
                qty: _quantityInCart(menus[i]),
                price: _priceOf(menus[i]),
                onAdd: () => _addToCart(menus[i]),
                onRemove: () => _removeFromCart(menus[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            gradient: AppColors.gradientDark,
            borderRadius: AppSpacing.xlRadius,
            boxShadow: AppShadows.raised,
          ),
          child: Row(
            children: [
              Container(
                width: 11.w,
                height: 11.w,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$totalItems',
                    style: AppText.label(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Votre panier',
                      style: AppText.bodySm(color: Colors.white70),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(0)} FCFA',
                      style: AppText.h3(color: Colors.white),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: sending ? null : _sendCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 1.55.h,
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Text('Commander', style: AppText.label()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantSummary extends StatelessWidget {
  final Map<String, dynamic> restaurant;

  const _RestaurantSummary({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final locality = (restaurant['locality'] ?? 'Autour de vous').toString();
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, 2.h, AppSpacing.page, 0),
      child: PremiumCard(
        child: Row(
          children: [
            const PremiumBadge(
              label: '4.8',
              icon: Icons.star_rounded,
              color: AppColors.gold,
            ),
            SizedBox(width: 2.w),
            const PremiumBadge(
              label: '25-35 min',
              icon: Icons.schedule_rounded,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                locality,
                style: AppText.bodySm(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int qty;
  final double price;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuCard({
    required this.item,
    required this.qty,
    required this.price,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = MenuService.fixImageUrl(item['image']?.toString());
    final name = (item['name'] ?? 'Produit').toString();
    final description = (item['description'] ?? '').toString();

    return PremiumCard(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppSpacing.lgRadius,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 25.w,
                    height: 12.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.h4(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  Gap(.5.h),
                  Text(
                    description,
                    style: AppText.bodySm(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Gap(1.h),
                Row(
                  children: [
                    Text(
                      '${price.toStringAsFixed(0)} FCFA',
                      style: AppText.price(),
                    ),
                    const Spacer(),
                    qty == 0
                        ? _AddButton(onTap: onAdd)
                        : _QtyStepper(
                            qty: qty,
                            onAdd: onAdd,
                            onRemove: onRemove,
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

  Widget _imagePlaceholder() {
    return Container(
      width: 25.w,
      height: 12.h,
      decoration: BoxDecoration(
        gradient: AppColors.gradientOrange,
        borderRadius: AppSpacing.lgRadius,
      ),
      child: Center(child: Image.asset('assets/images/n.png', height: 7.h)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.pillRadius,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.2.w, vertical: 1.h),
        decoration: const BoxDecoration(
          gradient: AppColors.gradientOrange,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 1.w),
            Text('Ajouter', style: AppText.label(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(.6.w),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft.withValues(alpha: .55),
        borderRadius: AppSpacing.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundIcon(Icons.remove_rounded, onRemove),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.2.w),
            child: Text('$qty', style: AppText.label()),
          ),
          _roundIcon(Icons.add_rounded, onAdd),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.pillRadius,
      child: Container(
        padding: EdgeInsets.all(1.4.w),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.orange, size: 15),
      ),
    );
  }
}
