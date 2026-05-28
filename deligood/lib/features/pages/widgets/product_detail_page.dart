import 'dart:convert';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

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
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            // IMAGE DE FOND
            SizedBox(
              height: 40.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                child: Image.network(
                  widget.item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 80),
                  ),
                ),
              ),
            ),

            // BOUTON RETOUR
            Positioned(
              top: 2.h,
              left: 2.w,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // CONTENU GLASSY SHEET
            DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.65,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.h),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // INDICATEUR DRAG
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
                      Center(
                        child: Column(
                          children: [
                            Text(
                              widget.item.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              "${widget.item.price} FCFA",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 1.h),

                      if (widget.item.category != null)
                        Center(
                          child: Text(
                            widget.item.category!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),

                      SizedBox(height: 3.h),

                      // QUANTITÉ
                      // Remplace le Row actuel de quantité par ce widget
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
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // BOUTON -
                                GestureDetector(
                                  onTap: quantity > 1
                                      ? () => setState(() => quantity--)
                                      : null,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: quantity > 1
                                          ? Colors.deepOrange
                                          : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                // NOMBRE
                                Container(
                                  width: 10.w,
                                  alignment: Alignment.center,
                                  child: Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                // BOUTON +
                                GestureDetector(
                                  onTap: () => setState(() => quantity++),
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                        textAlign: TextAlign.justify,
                      ),

                      SizedBox(height: 12.h),
                    ],
                  ),
                );
              },
            ),

            Positioned(
              bottom: 2.h,
              left: 4.w,
              right: 4.w,
              child: SlideToAddCart(
                quantity: quantity,
                isLoading: isLoading,
                onConfirm: _addToCart,
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
        Uri.parse('${Api.baseUrl}/api/orders/cart/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': Api.authHeaderValue(token),
        },
        body: jsonEncode({
          'menu_item_id': widget.item.id,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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

class SlideToAddCart extends StatefulWidget {
  final int quantity;
  final bool isLoading;
  final VoidCallback onConfirm;

  const SlideToAddCart({
    super.key,
    required this.quantity,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  State<SlideToAddCart> createState() => _SlideToAddCartState();
}

class _SlideToAddCartState extends State<SlideToAddCart> {
  double dragPosition = 0.0;
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 8.w;

    return Stack(
      children: [
        // BACKGROUND
        Container(
          height: 7.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3.5.h),
          ),
        ),

        // PROGRESS BAR
        Positioned(
          left: 0,
          child: Container(
            height: 7.h,
            width: dragPosition + 7.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(3.5.h),
            ),
          ),
        ),

        // TEXTE
        Container(
          height: 7.h,
          alignment: Alignment.center,
          child: widget.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  confirmed
                      ? "Ajouté au panier !"
                      : "Glisser pour ajouter au panier • ${widget.quantity}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),

        // SLIDER
        Positioned(
          left: dragPosition,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragPosition += details.delta.dx;
                if (dragPosition < 0) dragPosition = 0;
                if (dragPosition > width - 7.h) dragPosition = width - 7.h;
              });
            },
            onHorizontalDragEnd: (details) {
              if (dragPosition >= width - 7.h - 5) {
                // ARRIVÉE À DROITE
                setState(() {
                  confirmed = true;
                  dragPosition = width - 7.h;
                });

                widget.onConfirm(); // Ajout au panier

                // RESET après 800ms pour nouvelle utilisation
                Future.delayed(const Duration(milliseconds: 800), () {
                  setState(() {
                    confirmed = false;
                    dragPosition = 0.0;
                  });
                });
              } else {
                // Retour si incomplet
                setState(() => dragPosition = 0.0);
              }
            },
            child: Container(
              height: 7.h,
              width: 7.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: confirmed
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.arrow_forward, color: Colors.deepOrange),
            ),
          ),
        ),
      ],
    );
  }
}
