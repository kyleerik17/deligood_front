import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      name: json['menu_item']?['name'] ?? "Plat",
      quantity: json['quantity'] ?? 1,
      price: double.tryParse((json['total_price'] ?? json['price'] ?? "0").toString()) ?? 0.0,
      unitPrice: double.tryParse((json['unit_price'] ?? "0").toString()) ?? 0.0,
    );
  }
}

class CommandeResto {
  final int id;
  final String clientName;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final List<CommandeItem> items;
  final String address;
  final String phone;
  final double deliveryFee;

  CommandeResto({
    required this.id,
    required this.clientName,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.phone,
    required this.deliveryFee,
  });

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CommandeResto(
      id: json['id'],
      clientName: json['client_name'] ?? "Client",
      status: json['status'] ?? "pending",
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      items: itemsJson.map((e) => CommandeItem.fromJson(e)).toList(),
      address: json['address'] ?? "Adresse non définie",
      phone: json['phone'] ?? "0000000000",
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? "0.0") ?? 0.0,
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
      Uri.parse('${ApiConfig.baseUrl}/orders/restaurant/'), // <-- utilisation du baseUrl
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
      appBar: AppBar(title: const Text("Vos commandes"), centerTitle: true),
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

          return ListView.separated(
            itemCount: commandes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor(cmd.status),
                  child: Text(
                    cmd.clientName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(cmd.clientName),
                subtitle: Text(
                  "Total: ${cmd.totalPrice.toStringAsFixed(2)} FCFA\n${cmd.createdAt.toLocal()}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusColor(cmd.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cmd.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor(cmd.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommandeDetailPage(commande: cmd),
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

// ======================= PAGE DETAIL COMMANDE =========================
class CommandeDetailPage extends StatelessWidget {
  final CommandeResto commande;

  const CommandeDetailPage({super.key, required this.commande});

  Future<void> prendreCommande(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/orders/restaurant/${commande.id}/status/'), // <-- baseUrl
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith("ey") ? 'Bearer $token' : 'Token $token',
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
      appBar: AppBar(
        title: Text("Commande #${commande.id}"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Client : ${commande.clientName}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Status : ${commande.status.toUpperCase()}",
                      style: TextStyle(
                          fontSize: 16,
                          color: statusColor(commande.status),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Total : ${commande.totalPrice.toStringAsFixed(2)} FCFA"),
                  const SizedBox(height: 8),
                  Text("Date : ${commande.createdAt.toLocal()}"),
                  const Divider(height: 32),
                  const Text("Items :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Adresse : ${commande.address}"),
                  Text("Téléphone : ${commande.phone}"),
                  Text("Frais de livraison : ${commande.deliveryFee.toStringAsFixed(2)} FCFA"),

                  Expanded(
                    child: ListView.builder(
                      itemCount: commande.items.length,
                      itemBuilder: (context, index) {
                        final item = commande.items[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text("Quantité : ${item.quantity}"),
                          trailing: Text("Prix unitaire : ${item.unitPrice.toStringAsFixed(2)} FCFA"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!dejaPrise)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => prendreCommande(context),
                  child: const Text(
                    "PRENDRE LA COMMANDE",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
