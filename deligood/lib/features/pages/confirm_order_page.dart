
import 'package:deligood/features/pages/panier_page.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';


class ConfirmOrderPage extends StatefulWidget {
  final List<CartItem> items;

  const ConfirmOrderPage({super.key, required this.items});

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  bool loading = false;

  String get phone => "0700000000"; // tu peux remplacer par profile API
  String get address => "Abidjan";

  Future<void> sendOrder() async {
    setState(() => loading = true);

    try {
      final restaurantId = widget.items.first.restaurantId;

      final itemsPayload = widget.items
          .map(
            (e) => {
              "menu_item_id": e.menuItemId,
              "quantity": e.quantity,
            },
          )
          .toList();

      await LivreurApi.confirmOrder(
        restaurantId: restaurantId,
        items: itemsPayload,
        address: address,
        phone: phone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commande envoyée 🚀"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final total = widget.items.fold<double>(
  0.0,
  (sum, item) => sum + item.price * item.quantity,
);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF1F2937)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirmation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  "Total: $total FCFA",
                  style: const TextStyle(color: Colors.white70),
                ),

                SizedBox(height: 4.h),

                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Adresse", style: TextStyle(color: Colors.white)),
                      Text("Téléphone", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: loading ? null : sendOrder,
                  child: Container(
                    height: 6.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Confirmer",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}