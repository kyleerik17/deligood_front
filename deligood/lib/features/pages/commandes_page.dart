import 'dart:convert';
import 'package:deligood/features/pages/widgets/product_detail_page.dart';
import 'package:deligood/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:deligood/widgets/CustomAppBar.dart';
import 'package:deligood/widgets/search.dart';

import '../../core/api.dart';

class CommandePage extends StatefulWidget {
  const CommandePage({super.key});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  late Future<List<MenuItem>> _futureItems;
  final TextEditingController searchController = TextEditingController();
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureItems = fetchMenuItems();
  }

  // ================= FETCH MENU ITEMS =================
Future<List<MenuItem>> fetchMenuItems({
  String? category,
  String? search,
}) async {
  final Map<String, String> queryParams = {};

  if (category != null && category.toLowerCase() != 'tous') {
    queryParams['category'] = category;
  }
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }

  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/api/menu/',
  ).replace(queryParameters: queryParams);

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => MenuItem.fromJson(e)).toList();
  } else {
    throw Exception('Erreur API ${response.statusCode}');
  }
}

  // ================= FILTRAGE =================
  void _applyFilters({String? category, String? search}) {
    final cat = category ?? _selectedCategory;
    final s = search ?? _searchQuery;

    setState(() {
      _selectedCategory = cat;
      _searchQuery = s;
      _futureItems = fetchMenuItems(
        category: cat.toLowerCase() == 'divers' ? 'Dessert' : cat,
        search: s,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            const CustomAppBar(),
            SizedBox(height: 1.h),

            // ===== Search =====
            SearchBarWidget(
              controller: searchController,
              onTapIcon: () => _applyFilters(search: searchController.text),
              onChanged: (value) => _applyFilters(search: value),
              placeholder: 'Rechercher',
            ),

            SizedBox(height: 1.h),

            // ===== Filters =====
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterButton(
                    label: "Tous",
                    onTap: () => _applyFilters(category: "Tous"),
                  ),
                  FilterButton(
                    label: "Plats",
                    onTap: () => _applyFilters(category: "Plats"),
                  ),
                  FilterButton(
                    label: "Boissons",
                    onTap: () => _applyFilters(category: "Boissons"),
                  ),
                  FilterButton(
                    label: "Divers",
                    onTap: () => _applyFilters(category: "Divers"),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // ===== Grid =====
            Expanded(
              child: FutureBuilder<List<MenuItem>>(
                future: _futureItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucun article disponible'),
                    );
                  }

                  final items = snapshot.data!;

                  return GridView.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2.w,
                      mainAxisSpacing: 2.w,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(item: item),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Image.network(
                                  item.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(Icons.broken_image, size: 8.h),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        '${item.price} FCFA',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
          ],
        ),
      ),
    );
  }
}

// ================= FILTER BUTTON =================
class FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FilterButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1.h)),
      ),
      child: Text(label, style: TextStyle(fontSize: 14.sp)),
    );
  }
}
