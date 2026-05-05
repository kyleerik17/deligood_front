import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

// 🎨 Thème DeliGood
const kOrange       = Color(0xFFFF6B35);
const kBg           = Color(0xFFF7F3EF);
const kWhite        = Colors.white;
const kTextPrimary  = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF9E9E9E);
const kGreen        = Color(0xFF27AE60);

/// ====================== MODEL ======================

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['menu_item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
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

  OrderModel({
    required this.id,
    required this.clientName,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      status: json['status'] ?? '',
      total: double.tryParse(json['total_price'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    );
  }
}

/// ====================== SERVICE ======================

class OrderService {
  static Future<List<OrderModel>> fetchDeliveredOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception("Token non trouvé, veuillez vous connecter");
    }

    final response = await http.get(
      Uri.parse('https://deligood-backend.onrender.com/api/orders/livreur/delivered/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Erreur API ${response.statusCode}');
    }
  }
}

/// ====================== PAGE HISTORIQUE ======================

class HistoryLivPage extends StatefulWidget {
  const HistoryLivPage({super.key});

  @override
  State<HistoryLivPage> createState() => _HistoryLivPageState();
}

class _HistoryLivPageState extends State<HistoryLivPage>
    with SingleTickerProviderStateMixin {
  late Future<List<OrderModel>> futureOrders;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    futureOrders = OrderService.fetchDeliveredOrders()
      ..then((_) => _anim.forward());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔝 Header
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Historique",
                    style: GoogleFonts.syne(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Gap(0.5.h),
                  Text(
                    "Toutes vos livraisons effectuées",
                    style: GoogleFonts.syne(
                      fontSize: 11.sp,
                      color: kTextSecondary,
                    ),
                  ),
                  Gap(2.h),
                  // Ligne déco orange
                  Container(
                    width: 10.w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            Gap(2.h),

            // 📋 Liste
            Expanded(
              child: FutureBuilder<List<OrderModel>>(
                future: futureOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kOrange),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48, color: Colors.grey.shade300),
                          Gap(2.h),
                          Text(
                            "Erreur de chargement",
                            style: GoogleFonts.syne(color: kTextSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!;

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 52, color: Colors.grey.shade300),
                          Gap(2.h),
                          Text(
                            "Aucune livraison effectuée",
                            style: GoogleFonts.syne(color: kTextSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                        horizontal: 5.w, vertical: 1.h),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => Gap(1.5.h),
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _anim,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  OrderDetailPage(order: orders[index]),
                              transitionsBuilder:
                                  (_, animation, __, child) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                              transitionDuration:
                                  const Duration(milliseconds: 350),
                            ),
                          ),
                          child: _OrderCard(order: orders[index]),
                        ),
                      );
                    },
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

/// ====================== CARD ======================

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône statut
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: kGreen,
            ),
          ),

          SizedBox(width: 3.w),

          // Infos
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
                Gap(0.4.h),
                Text(
                  order.clientName,
                  style: GoogleFonts.syne(
                    fontSize: 10.sp,
                    color: kTextSecondary,
                  ),
                ),
                Gap(0.3.h),
                Text(
                  DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt),
                  style: GoogleFonts.syne(
                    fontSize: 9.sp,
                    color: kTextSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Total + chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${order.total.toStringAsFixed(0)} F",
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                  color: kOrange,
                ),
              ),
              Gap(0.5.h),
              Icon(Icons.chevron_right_rounded,
                  color: kTextSecondary.withOpacity(0.4), size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

/// ====================== PAGE DÉTAIL ======================

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;
  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final total = order.items.fold<double>(
        0, (sum, i) => sum + (i.price * i.quantity));

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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: kTextPrimary),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    "Commande #${order.id}",
                    style: GoogleFonts.syne(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Gap(3.h),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 📋 Infos commande
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Statut",
                                style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w600,
                                  color: kTextSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 3.w, vertical: 0.6.h),
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: GoogleFonts.syne(
                                    color: kGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Gap(1.5.h),
                          _infoRow(
                            Icons.person_rounded,
                            "Client",
                            order.clientName,
                          ),
                          Gap(1.h),
                          _infoRow(
                            Icons.calendar_today_rounded,
                            "Date",
                            DateFormat('dd MMM yyyy · HH:mm')
                                .format(order.createdAt),
                          ),
                        ],
                      ),
                    ),

                    Gap(2.5.h),

                    Text(
                      "Articles commandés",
                      style: GoogleFonts.syne(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),

                    Gap(1.5.h),

                    // 🍽 Articles
                    ...order.items.map((item) => _ItemTile(item: item)),

                    Gap(2.h),

                    // 💰 Total
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kOrange, Colors.deepOrangeAccent],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: kOrange.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: GoogleFonts.syne(
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
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
                    ),

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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kOrange, size: 16),
        SizedBox(width: 2.w),
        Text(
          "$label : ",
          style: GoogleFonts.syne(
            color: kTextSecondary,
            fontSize: 10.sp,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.syne(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ),
      ],
    );
  }
}

/// ====================== ITEM TILE ======================

class _ItemTile extends StatelessWidget {
  final OrderItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantité badge
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "${item.quantity}x",
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
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                color: kTextPrimary,
              ),
            ),
          ),

          Text(
            "${item.price.toStringAsFixed(0)} F",
            style: GoogleFonts.syne(
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
              color: kOrange,
            ),
          ),
        ],
      ),
    );
  }
}