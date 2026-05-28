import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

import 'package:deligood/core/network/api.dart';

// ─────────────────────────────────────────────
// DESIGN SYSTEM
// ─────────────────────────────────────────────
const kOrange = Color(0xFFFF6B35);
const kBg = Color(0xFFF5F0EB);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF9E9E9E);
const kGreen = Color(0xFF27AE60);
const kSurface = Color(0xFFFAFAFA);

String get _baseUrl => Api.baseUrl;

// ─────────────────────────────────────────────
// MODE : livreur, restaurant ou client
// ─────────────────────────────────────────────
enum HistoryMode { livreur, restaurant, client }

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['menu_item_name'] ?? json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String clientName;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String deliveryAddress;
  final String livreurName;
  final String phoneNumber;
  final String restaurantName;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.deliveryAddress = '',
    this.livreurName = 'Non assigné',
    this.phoneNumber = '',
    this.restaurantName = '',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Gestion des différentes structures de réponse
    if (json.containsKey('data')) {
      return OrderModel.fromJson(json['data']);
    }

    return OrderModel(
      id: json['id'] ?? 0,
      clientName:
          json['client_name'] ??
          json['client']?['name'] ??
          json['user']?['name'] ??
          'Client',
      status: json['status'] ?? 'unknown',
      total:
          double.tryParse(
            (json['total_price'] ?? json['total'] ?? json['amount'] ?? 0)
                .toString(),
          ) ??
          0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      deliveryAddress:
          json['address'] ??
          json['delivery_address'] ??
          json['location']?['address'] ??
          '',
      livreurName:
          json['livreur_name'] ??
          json['livreur']?['name'] ??
          json['delivery_person']?['name'] ??
          'Non assigné',
      phoneNumber: json['phone'] ?? json['client_phone'] ?? '',
      restaurantName:
          json['restaurant_name'] ?? json['restaurant']?['name'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────
class HistoryService {
  static Future<List<OrderModel>> fetchOrders(HistoryMode mode) async {
    try {
      final endpoint = _getEndpoint(mode);
      final response = await ApiService.get(endpoint);

      if (response == null) return [];

      // Si la réponse est une Map avec "data"
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          final List ordersData = response['data'];
          return ordersData.map((e) => OrderModel.fromJson(e)).toList();
        }
        return [];
      }

      // Si la réponse est directement une List
      if (response is List) {
        return response.map((e) => OrderModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static String _getEndpoint(HistoryMode mode) {
    switch (mode) {
      case HistoryMode.livreur:
        return '/api/orders/livreur/delivered/';
      case HistoryMode.restaurant:
        return '/api/orders/restaurant/';
      case HistoryMode.client:
        return '/api/orders/client/history/';
      default:
        return '/api/orders/';
    }
  }

  static List<OrderModel> _parseResponse(
    String responseBody,
    HistoryMode mode,
  ) {
    try {
      final data = jsonDecode(responseBody);

      if (mode == HistoryMode.client) {
        if (data is Map && data.containsKey('data')) {
          final List ordersData = data['data'];
          return ordersData.map((e) => OrderModel.fromJson(e)).toList();
        }
        return [];
      }

      if (data is List) {
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print('Error parsing response: $e');
      return [];
    }
  }
}

// ─────────────────────────────────────────────
// PAGE PRINCIPALE
// ─────────────────────────────────────────────
class HistoryPage extends StatefulWidget {
  final HistoryMode mode;

  const HistoryPage({super.key, required this.mode});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late Future<List<OrderModel>> _futureOrders;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadOrders();
  }

  void _loadOrders() {
    _futureOrders = HistoryService.fetchOrders(widget.mode)
        .then((orders) {
          if (mounted) {
            _animationController.forward();
          }
          return orders;
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${error.toString()}')),
            );
          }
          return <OrderModel>[];
        });
  }

  void _reload() {
    setState(() {
      _animationController.reset();
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: FutureBuilder<List<OrderModel>>(
          future: _futureOrders,
          builder: (context, snapshot) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  _buildStats(snapshot.data!),
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  _buildSectionLabel(),
                _buildContent(snapshot),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withOpacity(0.07),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: kTextPrimary,
                ),
              ),
            ),
            Gap(2.h),
            Text(
              "Historique",
              style: GoogleFonts.syne(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Gap(0.3.h),
            Text(
              _getSubtitle(),
              style: GoogleFonts.syne(fontSize: 11.sp, color: kTextSecondary),
            ),
            Gap(1.2.h),
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: kOrange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (widget.mode) {
      case HistoryMode.livreur:
        return "Toutes vos livraisons effectuées";
      case HistoryMode.restaurant:
        return "Commandes livrées par vos soins";
      case HistoryMode.client:
        return "Vos commandes passées";
    }
  }

  Widget _buildStats(List<OrderModel> orders) {
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final formattedRevenue = totalRevenue >= 1000
        ? "${(totalRevenue / 1000).toStringAsFixed(1)}k"
        : totalRevenue.toStringAsFixed(0);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 0),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_rounded,
                label: "Commandes",
                value: "${orders.length}",
                unit: "total",
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _StatCard(
                icon: Icons.payments_rounded,
                label: "Revenus",
                value: formattedRevenue,
                unit: "FCFA",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
        child: Text(
          "RÉCENTES",
          style: GoogleFonts.syne(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: kTextSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AsyncSnapshot<List<OrderModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoading();
    }

    if (snapshot.hasError) {
      return _buildError(snapshot.error.toString());
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return _buildEmpty();
    }

    return _buildOrderList(snapshot.data!);
  }

  Widget _buildLoading() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kOrange, strokeWidth: 2),
          Gap(2.h),
          Text(
            "Chargement...",
            style: GoogleFonts.syne(color: kTextSecondary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: Colors.grey.shade300,
              ),
            ),
            Gap(2.h),
            Text(
              "Erreur de chargement",
              style: GoogleFonts.syne(color: kTextSecondary, fontSize: 12.sp),
            ),
            Gap(0.5.h),
            Text(
              error.replaceFirst('Exception: ', ''),
              style: GoogleFonts.syne(
                color: kTextSecondary.withOpacity(0.6),
                fontSize: 9.sp,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(2.h),
            GestureDetector(
              onTap: _reload,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Réessayer",
                  style: GoogleFonts.syne(
                    color: kWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: Colors.grey.shade300,
              ),
            ),
            Gap(2.h),
            Text(
              _getEmptyMessage(),
              style: GoogleFonts.syne(color: kTextSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (widget.mode) {
      case HistoryMode.livreur:
        return "Aucune livraison effectuée";
      case HistoryMode.restaurant:
        return "Aucune commande livrée";
      case HistoryMode.client:
        return "Aucune commande passée";
    }
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final order = orders[index];
          final delay = (index * 0.08).clamp(0.0, 0.8);

          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay,
                    (delay + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                ),
              );

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                delay,
                (delay + 0.4).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          );

          return Padding(
            padding: EdgeInsets.only(bottom: 1.2.h),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          OrderDetailPage(order: order, mode: widget.mode),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: OrderCard(order: order, mode: widget.mode),
                ),
              ),
            ),
          );
        }, childCount: orders.length),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: kOrange, size: 16),
          ),
          Gap(1.h),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.syne(
              fontSize: 8.sp,
              color: kTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Gap(0.2.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.syne(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                TextSpan(
                  text: "  $unit",
                  style: GoogleFonts.syne(
                    fontSize: 10.sp,
                    color: kTextSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final HistoryMode mode;

  const OrderCard({super.key, required this.order, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isRestaurant = mode == HistoryMode.restaurant;
    final isClient = mode == HistoryMode.client;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        children: [
          // Header de la carte
          Padding(
            padding: EdgeInsets.all(3.5.w),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: kGreen,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Commande #${order.id}",
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: kTextPrimary,
                        ),
                      ),
                      Gap(0.3.h),
                      Text(
                        isClient ? order.restaurantName : order.clientName,
                        style: GoogleFonts.syne(
                          fontSize: 10.sp,
                          color: kTextSecondary,
                        ),
                      ),
                      if (isRestaurant && order.livreurName.isNotEmpty) ...[
                        Gap(0.4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_bike_rounded,
                              size: 11,
                              color: kOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.livreurName,
                              style: GoogleFonts.syne(
                                fontSize: 9.5.sp,
                                color: kOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${order.total.toStringAsFixed(0)} F",
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: kOrange,
                      ),
                    ),
                    Gap(0.3.h),
                    Text(
                      DateFormat('dd MMM · HH:mm').format(order.createdAt),
                      style: GoogleFonts.syne(
                        fontSize: 8.5.sp,
                        color: kTextSecondary.withOpacity(0.6),
                      ),
                    ),
                    Gap(0.5.h),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: kTextSecondary.withOpacity(0.3),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer de la carte
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isRestaurant
                      ? Icons.location_on_rounded
                      : Icons.calendar_today_rounded,
                  size: 12,
                  color: kTextSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isRestaurant
                        ? (order.deliveryAddress.isNotEmpty
                              ? order.deliveryAddress
                              : 'Adresse non renseignée')
                        : isClient
                        ? order.restaurantName
                        : DateFormat(
                            'dd MMM yyyy · HH:mm',
                          ).format(order.createdAt),
                    style: GoogleFonts.syne(
                      fontSize: 9.sp,
                      color: kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 10, color: kGreen),
                      const SizedBox(width: 3),
                      Text(
                        "Livré",
                        style: GoogleFonts.syne(
                          fontSize: 8.5.sp,
                          color: const Color(0xFF1a7a44),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE DE DÉTAIL DE COMMANDE
// ─────────────────────────────────────────────
class OrderDetailPage extends StatelessWidget {
  final OrderModel order;
  final HistoryMode mode;

  const OrderDetailPage({super.key, required this.order, required this.mode});

  @override
  Widget build(BuildContext context) {
    final total = order.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final isRestaurant = mode == HistoryMode.restaurant;
    final isClient = mode == HistoryMode.client;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.07),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Commande #${order.id}",
                        style: GoogleFonts.syne(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy · HH:mm',
                        ).format(order.createdAt),
                        style: GoogleFonts.syne(
                          fontSize: 9.sp,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "LIVRÉ",
                      style: GoogleFonts.syne(
                        color: const Color(0xFF1a7a44),
                        fontWeight: FontWeight.w700,
                        fontSize: 8.sp,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Gap(2.h),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bloc d'informations
                    _buildInfoBlock(order, isRestaurant, isClient),

                    Gap(2.h),

                    // Liste des articles
                    _buildArticlesBlock(order.items),

                    Gap(2.h),

                    // Total
                    _buildTotalBlock(total),

                    Gap(3.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(OrderModel order, bool isRestaurant, bool isClient) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: isClient ? Icons.restaurant : Icons.person_rounded,
            label: isClient ? "Restaurant" : "Client",
            value: isClient ? order.restaurantName : order.clientName,
            isFirst: true,
          ),
          if (isRestaurant && order.livreurName.isNotEmpty)
            _InfoRow(
              icon: Icons.directions_bike_rounded,
              label: "Livreur",
              value: order.livreurName,
            ),
          if (order.deliveryAddress.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: "Adresse",
              value: order.deliveryAddress,
              isLast: !isClient,
            ),
          if (isClient && order.phoneNumber.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_rounded,
              label: "Téléphone",
              value: order.phoneNumber,
              isLast: true,
            ),
          if (isRestaurant)
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: "Date",
              value: DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildArticlesBlock(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 1.w, bottom: 1.h),
          child: Text(
            "ARTICLES",
            style: GoogleFonts.syne(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.black.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _ArticleRow(item: item, isLast: index == items.length - 1);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBlock(double total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total payé",
            style: GoogleFonts.syne(
              color: kWhite.withOpacity(0.85),
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
          Text(
            "${total.toStringAsFixed(0)} FCFA",
            style: GoogleFonts.syne(
              color: kWhite,
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: kOrange, size: 15),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.syne(
                    fontSize: 9.sp,
                    color: kTextSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.syne(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final OrderItem item;
  final bool isLast;

  const _ArticleRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                "${item.quantity}×",
                style: GoogleFonts.syne(
                  color: kOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.syne(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
            ),
          ),
          Text(
            "${(item.price * item.quantity).toStringAsFixed(0)} F",
            style: GoogleFonts.syne(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
