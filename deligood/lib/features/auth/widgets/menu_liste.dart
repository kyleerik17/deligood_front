import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

// ================= WIDGET HORIZONTAL MENU =================
class HorizontalMenuWidget extends StatefulWidget {
  const HorizontalMenuWidget({
    super.key,
    required this.title,
    required this.onSeeMore,
  });

  final VoidCallback onSeeMore;
  final String title; // Exemple: "Plats"

  @override
  State<HorizontalMenuWidget> createState() => _HorizontalMenuWidgetState();
}

class _HorizontalMenuWidgetState extends State<HorizontalMenuWidget> {
  late Future<List<MenuItem>> _futureItems;

  @override
  void initState() {
    super.initState();
    _futureItems = fetchMenuItems();
  }

  // ================= FETCH MENU ITEMS =================
  Future<List<MenuItem>> fetchMenuItems() async {
    final url = Uri.parse('http://deligood-production.up.railway.app');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Erreur API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER =====
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: widget.onSeeMore,
                child: Text(
                  'Voir plus',
                  style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),

        // ===== LIST HORIZONTALE AVEC FUTUREBUILDER =====
        SizedBox(
          height: 20.h,
          child: FutureBuilder<List<MenuItem>>(
            future: _futureItems,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucun article disponible'));
              }

              final items = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Container(
                    width: 60.w,
                    margin: EdgeInsets.only(right: 4.w),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.black26,
                      child: Row(
                        children: [
                          // ===== IMAGE =====
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(15),
                            ),
                            child: Image.network(
                              item.imageUrl.isNotEmpty
                                  ? item.imageUrl
                                  : 'assets/images.n.png',
                              width: 20.w,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 20.w,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                    ),
                                  ),
                            ),
                          ),

                          // ===== CONTENU =====
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 2.w,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 0.5.h),

                                  // Catégorie
                                  Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    item.restaurant,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),

                                  // Prix
                                  Text(
                                    '${item.price} FCFA',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),

                                  // Bouton Ajouter
                                ],
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
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}

// ================= MODEL MENU ITEM =================
class MenuItem {
  final String name;
  final String imageUrl;
  final String price;
  final String category;
  final String restaurant;

  MenuItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.restaurant,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] ?? 'Sans nom',
      imageUrl: json['image'] != null
          ? 'http://deligood-production.up.railway.app${json['assets/images/n.png']}'
          : '',
      price: json['price'].toString(),
      category: json['category_name'] ?? 'Non classé', // Utiliser category_name
      restaurant: (json['restaurant'] ?? 'Restaurant')
          .toString(), // Convertir en String
    );
  }
}
