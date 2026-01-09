import 'dart:convert';
import 'package:deligood/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/api.dart';

class ProductDetailPage extends StatefulWidget {
  final MenuItem item;

  const ProductDetailPage({super.key, required this.item});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // IMAGE
            SizedBox(
              height: 40.h,
              width: double.infinity,
              child: Image.network(
                widget.item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 80),
                ),
              ),
            ),

            // BOUTON RETOUR
            Positioned(
              top: 2.h,
              left: 2.w,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // CONTENU
            DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.65,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.h),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 10.w,
                          height: 0.6.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // NOM + PRIX
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${widget.item.price} FCFA",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 1.h),

                      if (widget.item.category != null)
                        Text(
                          widget.item.category!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),

                      SizedBox(height: 3.h),

                      // QUANTITÉ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quantité",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: quantity > 1
                                    ? () => setState(() => quantity--)
                                    : null,
                              ),
                              Text(
                                quantity.toString(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 3.h),

                      // DESCRIPTION
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        widget.item.description ??
                            "Aucune description disponible.",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 12.h),
                    ],
                  ),
                );
              },
            ),

            // BOUTON AJOUT PANIER
            Positioned(
              bottom: 2.h,
              left: 4.w,
              right: 4.w,
              child: SizedBox(
                height: 6.5.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.h),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Ajouter au panier ($quantity)",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) throw Exception("Utilisateur non connecté");

      final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/api/cart/add/'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Token $token',
  },
  body: jsonEncode({
    'menu_item_id': widget.item.id,
    'quantity': quantity,
  }),
);


      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ajouté au panier avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response.body);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'ajout au panier"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
