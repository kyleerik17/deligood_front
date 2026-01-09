import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deligood/models/menu_item.dart';

class ValidateCommandePage extends StatefulWidget {
  final MenuItem item;

  const ValidateCommandePage({super.key, required this.item});

  @override
  State<ValidateCommandePage> createState() => _ValidateCommandePageState();
}

class _ValidateCommandePageState extends State<ValidateCommandePage> {
  int quantity = 1;
  bool loading = false;

  double get total => double.tryParse(widget.item.price) ?? 0.0 * quantity;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> submitCommande() async {
    setState(() => loading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Utilisateur non connecté");

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          "menu_item_id": widget.item.id,
          "quantity": quantity,
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Commande envoyée avec succès ✅")),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        debugPrint("Erreur API: ${response.body}");
        throw Exception("Erreur serveur");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la commande ❌\n$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Valider la commande"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              '${widget.item.price} FCFA / unité',
              style: TextStyle(fontSize: 15.sp),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantité"),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Text(
                      quantity.toString(),
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 1.h),
            Text(
              "Total : ${total.toStringAsFixed(0)} FCFA",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1.5.h),
                  ),
                ),
                onPressed: loading ? null : submitCommande,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Confirmer la commande",
                        style: TextStyle(fontSize: 16.sp, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
