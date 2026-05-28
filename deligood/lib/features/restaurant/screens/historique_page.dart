import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';

// ======================= MODELES =========================
class HistoriqueItem {
  final int id;
  final String clientName;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<HistoriqueItemDetail> items;

  HistoriqueItem({
    required this.id,
    required this.clientName,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory HistoriqueItem.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final itemsList = itemsJson
        .map((e) => HistoriqueItemDetail.fromJson(e))
        .toList();

    return HistoriqueItem(
      id: json['id'] ?? 0,
      clientName: json['client_name'] ?? "Client",
      status: json['status'] ?? "pending",
      total: double.tryParse((json['total_price'] ?? 0).toString()) ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ?? DateTime.now(),
      items: itemsList,
    );
  }
}

class HistoriqueItemDetail {
  final String name;
  final int quantity;
  final double price;

  HistoriqueItemDetail({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory HistoriqueItemDetail.fromJson(Map<String, dynamic> json) {
    return HistoriqueItemDetail(
      name: json['menu_item_name'] ?? "Plat",
      quantity: json['quantity'] ?? 1,
      price: double.tryParse((json['price'] ?? "0").toString()) ?? 0.0,
    );
  }
}

// ======================= UTILITAIRES =========================
Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return Colors.blue;
    case 'delivered':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

// ======================= PAGE HISTORIQUE =========================
class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  late Future<List<HistoriqueItem>> _historiqueFuture;
  static String get baseUrl => Api.baseUrl;

  @override
  void initState() {
    super.initState();
    _historiqueFuture = fetchHistorique();
  }

  Future<List<HistoriqueItem>> fetchHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null) throw Exception("Token manquant");

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token.startsWith("ey")
          ? 'Bearer $token'
          : 'Token $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/restaurant/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final filtered = data
          .where((e) => e['status'] == 'accepted' || e['status'] == 'delivered')
          .map((e) => HistoriqueItem.fromJson(e))
          .toList();
      return filtered;
    } else if (response.statusCode == 401) {
      await prefs.remove('access_token');
      throw Exception("Token invalide ou expiré. Veuillez vous reconnecter.");
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Historique des commandes"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<HistoriqueItem>>(
        future: _historiqueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final commandes = snapshot.data ?? [];
          if (commandes.isEmpty) {
            return const Center(
              child: Text("Aucune commande historique pour l'instant"),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return Container(
                margin: EdgeInsets.only(bottom: 3.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: statusColor(cmd.status),
                    child: Text(
                      cmd.clientName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  title: Text(
                    cmd.clientName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  subtitle: Text(
                    "Total: ${cmd.total.toStringAsFixed(2)} FCFA\nDate: ${DateFormat('dd/MM/yyyy – kk:mm').format(cmd.createdAt.toLocal())}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11.sp,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: statusColor(cmd.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cmd.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor(cmd.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoriqueDetailPage(commande: cmd),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= DETAIL HISTORIQUE =========================
class HistoriqueDetailPage extends StatelessWidget {
  final HistoriqueItem commande;

  const HistoriqueDetailPage({super.key, required this.commande});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("Commande #${commande.id}"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Client : ${commande.clientName}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    "Status : ${commande.status.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: statusColor(commande.status),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    "Total : ${commande.total.toStringAsFixed(2)} FCFA",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "Items :",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 1.h),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  itemCount: commande.items.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final item = commande.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      subtitle: Text(
                        "Quantité : ${item.quantity}",
                        style: TextStyle(fontFamily: 'Roboto'),
                      ),
                      trailing: Text(
                        "${item.price.toStringAsFixed(2)} FCFA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
