import 'dart:convert';
import 'package:deligood/features/livreur/screens/pages/details_commande_page.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'panier_page.dart';

class ProduitDetailPage extends StatefulWidget {
  final MenuItem menuItem;
  final int restaurantId;
  final String restaurantName;
  final String image;

  const ProduitDetailPage({
    super.key,
    required this.menuItem,
    required this.restaurantId,
    required this.restaurantName,
    required this.image,
  });

  @override
  State<ProduitDetailPage> createState() => _ProduitDetailPageState();
}

class _ProduitDetailPageState extends State<ProduitDetailPage> {
  int quantity = 1;
  bool loading = false;

  Future<void> ajouterAuPanier() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('https://deligood-backend.onrender.com/api/orders/cart/add/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        "menu_item_id": widget.menuItem.id,
        "quantity": quantity,
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      // Afficher un message de succès sans redirection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$quantity x ${widget.menuItem.name} ajouté(s) au panier",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanierPage()),
              );
            },
          ),
        ),
      );

      // Réinitialiser la quantité (optionnel)
      setState(() => quantity = 1);
    } else {
      debugPrint(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur ajout panier"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.menuItem;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Image produit
          Container(
            height: 35.h,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(item.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom produit
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Prix
                  Text(
                    "${item.price} FCFA",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Quantité premium
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton -
                          InkWell(
                            onTap: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(1.5.h),
                              decoration: BoxDecoration(
                                color: quantity > 1
                                    ? Colors.deepOrange
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),

                          SizedBox(width: 4.w),

                          // Nombre
                          Text(
                            quantity.toString(),
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          // Bouton +
                          InkWell(
                            onTap: () => setState(() => quantity++),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(1.5.h),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.shade200
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bouton Ajouter au panier
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: loading ? null : ajouterAuPanier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Ajouter au panier",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
