import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

// ======================= MODELES =========================
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
      price: double.tryParse((json['price'] ?? "0").toString()) ?? 0.0,
      unitPrice: double.tryParse((json['unit_price'] ?? "0").toString()) ?? 0.0,
    );
  }
}

class CommandeResto {
  final int id;
  final String clientName;
  final String status;
  final double totalPlats;
  final double deliveryFee;
  final DateTime createdAt;
  final List<CommandeItem> items;
  final String address;
  final String phone;

  CommandeResto({
    required this.id,
    required this.clientName,
    required this.status,
    required this.totalPlats,
    required this.deliveryFee,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.phone,
  });

  double get total => totalPlats + deliveryFee;

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => CommandeItem.fromJson(e))
        .toList();

    double totalPlats = itemsJson.fold(0.0, (sum, item) => sum + item.price);
    double deliveryFee = totalPlats * 0.03;

    return CommandeResto(
      id: json['id'] ?? 0,
      clientName: json['client_name'] ?? "Client",
      phone: json['client_phone'] ?? "0000000000",
      address: json['client_address'] ?? "Adresse non définie",
      status: json['status'] ?? "pending",
      totalPlats: totalPlats,
      deliveryFee: deliveryFee,
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ?? DateTime.now(),
      items: itemsJson,
    );
  }
}

// ======================= UTILITAIRES =========================
Color statusColor(String status) {
  switch (status.toLowerCase()) {
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

// ======================= PAGE LISTE COMMANDES =========================
class CommandeRestoPage extends StatefulWidget {
  const CommandeRestoPage({super.key});

  @override
  State<CommandeRestoPage> createState() => _CommandeRestoPageState();
}

class _CommandeRestoPageState extends State<CommandeRestoPage> {
  late Future<List<CommandeResto>> _commandesFuture;
  static const String baseUrl = "https://deligood-backend.onrender.com/";

  @override
  void initState() {
    super.initState();
    _commandesFuture = fetchCommandesResto();
  }

  Future<List<CommandeResto>> fetchCommandesResto() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null) throw Exception("Token manquant");

    final isJwt = token.startsWith("ey");
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': isJwt ? 'Bearer $token' : 'Token $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/orders/restaurant/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => CommandeResto.fromJson(e)).toList();
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
        backgroundColor: Colors.deepOrange,
        title: const Text("Vos commandes"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<CommandeResto>>(
        future: _commandesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final commandes = snapshot.data ?? [];
          if (commandes.isEmpty) {
            return const Center(child: Text("Aucune commande pour l'instant"));
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
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade200,
                      Colors.deepOrange.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      cmd.clientName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor(cmd.status),
                      ),
                    ),
                  ),
                  title: Text(
                    cmd.clientName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Total: ${cmd.total.toStringAsFixed(2)} FCFA\nDate: ${DateFormat('dd/MM/yyyy – kk:mm').format(cmd.createdAt.toLocal())}",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cmd.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommandeDetailPage(commande: cmd),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        _commandesFuture = fetchCommandesResto();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= PAGE DETAIL COMMANDE PREMIUM =========================
class CommandeDetailPage extends StatelessWidget {
  final CommandeResto commande;
  static const String baseUrl = "https://deligood-backend.onrender.com/";

  const CommandeDetailPage({super.key, required this.commande});

  Future<void> prendreCommande(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) throw Exception("Utilisateur non connecté");

      final response = await http.patch(
        Uri.parse(
          '$baseUrl/api/orders/orders/restaurant/${commande.id}/status/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith("ey")
              ? 'Bearer $token'
              : 'Token $token',
        },
        body: jsonEncode({"status": "accepted"}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Commande prise avec succès ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ❌ $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dejaPrise = commande.status.toLowerCase() != 'pending';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text("Commande #${commande.id}"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Card client info
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    ),
                  ),
                  Text(
                    "Téléphone : ${commande.phone}",
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    "Adresse : ${commande.address}",
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    "Date : ${DateFormat('dd/MM/yyyy – kk:mm').format(commande.createdAt.toLocal())}",
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          commande.status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: statusColor(commande.status),
                      ),
                      const Spacer(),
                      Text(
                        "Total: ${commande.total.toStringAsFixed(2)} FCFA",
                        style: TextStyle(
                          fontSize: 14.sp,
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
            // Items list
            Expanded(
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      title: Text(
                        item.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Quantité : ${item.quantity}"),
                      trailing: Text(
                        "${item.unitPrice.toStringAsFixed(2)} FCFA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (!dejaPrise)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => prendreCommande(context),
                    child: Text(
                      "ACCEPTER COMMANDE",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
