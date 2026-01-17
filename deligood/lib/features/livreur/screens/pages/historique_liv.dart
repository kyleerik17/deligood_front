import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

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

/// ====================== SERVICE API ======================

class OrderService {
  static Future<List<OrderModel>> fetchDeliveredOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception("Token non trouvé, veuillez vous connecter");
    }

    final response = await http.get(
      Uri.parse(
        'https://deligood-backend.onrender.com//api/orders/orders/livreur/delivered/',
      ),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Erreur API ${response.statusCode} : ${response.body}');
    }
  }
}

/// ====================== PAGE HISTORIQUE ======================

class HistoryLivPage extends StatefulWidget {
  const HistoryLivPage({super.key});

  @override
  State<HistoryLivPage> createState() => _HistoryLivPageState();
}

class _HistoryLivPageState extends State<HistoryLivPage> {
  late Future<List<OrderModel>> futureOrders;

  @override
  void initState() {
    super.initState();
    futureOrders = OrderService.fetchDeliveredOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Historique',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('Aucune commande livrée'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(order: order),
                    ),
                  );
                },
                child: _OrderCard(order: order),
              );
            },
          );
        },
      ),
    );
  }
}

/// ====================== CARD HISTORIQUE ======================

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF27AE60)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client : ${order.clientName}',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy – HH:mm').format(order.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${order.total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ====================== PAGE DÉTAIL COMMANDE ======================

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text('Commande #${order.id}'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _OrderInfo(order: order),
            const SizedBox(height: 16),
            Expanded(child: _OrderItems(items: order.items)),
          ],
        ),
      ),
    );
  }
}

/// ====================== INFO COMMANDE ======================

class _OrderInfo extends StatelessWidget {
  final OrderModel order;

  const _OrderInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
              const Text(
                'Statut',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Client : ${order.clientName}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17.sp),
          ),
        ],
      ),
    );
  }
}

/// ====================== LISTE ARTICLES ======================

class _OrderItems extends StatelessWidget {
  final List<OrderItem> items;

  const _OrderItems({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucun article'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item.quantity}x ${item.name}'),
              Text('${item.price.toStringAsFixed(0)} FCFA'),
            ],
          ),
        );
      },
    );
  }
}
