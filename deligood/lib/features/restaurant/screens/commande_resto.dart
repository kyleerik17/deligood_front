import 'dart:convert';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

/// ======================= MODELES =========================
class CommandeItem {
  final String name;
  final int quantity;
  final double price;
  final double unitPrice;

  CommandeItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.unitPrice,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      name: json['menu_item_name'] ?? "Plat",
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
    );
  }
}

class CommandeResto {
  final int id;
  final String clientName;
  final String status;
  final DateTime createdAt;
  final List<CommandeItem> items;
  final String address;
  final String phone;

  CommandeResto({
    required this.id,
    required this.clientName,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.phone,
  });

  double get total =>
      items.fold<double>(0.0, (sum, item) => sum + item.price) * 1.03;

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((e) => CommandeItem.fromJson(e))
        .toList();

    return CommandeResto(
      id: json['id'],
      clientName: json['client_name'] ?? "Client",
      phone: json['client_phone'] ?? "",
      address: json['client_address'] ?? "",
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      items: items,
    );
  }
}

/// ======================= UTILS =========================
Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'accepted':
      return Colors.blue;
    case 'picked':
      return Colors.purple;
    case 'delivered':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// ======================= PAGE LISTE =========================
class CommandeRestoPage extends StatefulWidget {
  const CommandeRestoPage({super.key});

  @override
  State<CommandeRestoPage> createState() => _CommandeRestoPageState();
}

class _CommandeRestoPageState extends State<CommandeRestoPage> {
  static const baseUrl = "http://127.0.0.1:8000";
  late Future<List<CommandeResto>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchCommandes();
  }

  Future<List<CommandeResto>> fetchCommandes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token')!;
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/orders/restaurant/'),
      headers: {
        'Authorization': token.startsWith('ey')
            ? 'Bearer $token'
            : 'Token $token',
      },
    );
    final data = jsonDecode(response.body) as List;
    return data.map((e) => CommandeResto.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Commandes"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<CommandeResto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final commandes = snapshot.data ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommandeDetailPage(commande: cmd),
                      ),
                    );
                    if (result == true) {
                      setState(() => _future = fetchCommandes());
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: statusColor(
                          cmd.status,
                        ).withOpacity(0.15),
                        child: Text(
                          cmd.clientName[0].toUpperCase(),
                          style: TextStyle(
                            color: statusColor(cmd.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Gap(4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cmd.clientName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                              ),
                            ),
                            Gap(0.6.h),
                            Text(
                              DateFormat(
                                'dd MMM yyyy • HH:mm',
                              ).format(cmd.createdAt),
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey,
                              ),
                            ),
                            Gap(1.h),
                            Text(
                              "${cmd.total.toStringAsFixed(0)} FCFA",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor(cmd.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cmd.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor(cmd.status),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

class CommandeDetailPage extends StatelessWidget {
  final CommandeResto commande;
  static const baseUrl = "http://127.0.0.1:8000";

  const CommandeDetailPage({super.key, required this.commande});

  // ================= ACCEPTER COMMANDE =================
  Future<void> accepterCommande(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Token manquant");

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/restaurant/${commande.id}/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith('ey')
              ? 'Bearer $token'
              : 'Token $token',
        },
        body: jsonEncode({"status": "accepted"}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Commande acceptée ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeRestaurant(orderId: commande.id),
          ),
        );
      } else {
        throw Exception("Erreur serveur ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ❌ $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ================= MARQUER LIVRÉE =================
  Future<void> marquerLivree(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Token manquant");

      final response = await http.patch(
        Uri.parse(
          'http://127.0.0.1:8000/api/orders/orders/restaurant/${commande.id}/status/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith('ey')
              ? 'Bearer $token'
              : 'Token $token',
        },
        body: jsonEncode({"status": "delivered"}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Commande livrée ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Erreur ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ❌ $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dejaPrise = commande.status != 'pending';
    final livrable = commande.status == 'accepted';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text("Commande #${commande.id}"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // ===== INFOS CLIENT =====
            Container(
              padding: EdgeInsets.all(4.w),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commande.clientName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(1.h),
                  Text("📞 ${commande.phone}"),
                  Text("📍 ${commande.address}"),
                  Gap(1.h),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor(commande.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          commande.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor(commande.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${commande.total.toStringAsFixed(0)} FCFA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Gap(2.h),

            // ===== LISTE DES ITEMS =====
            Expanded(
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListView.separated(
                  itemCount: commande.items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = commande.items[i];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text("Quantité : ${item.quantity}"),
                      trailing: Text(
                        "${item.unitPrice.toStringAsFixed(0)} FCFA",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Gap(2.h),

            // ===== BOUTONS ACTION =====
            if (!dejaPrise)
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => accepterCommande(context),
                  child: const Text(
                    "ACCEPTER LA COMMANDE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (livrable)
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => marquerLivree(context),
                  child: const Text(
                    "MARQUER COMME LIVRÉE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
