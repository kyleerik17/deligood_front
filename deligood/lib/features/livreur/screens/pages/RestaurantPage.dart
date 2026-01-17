import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

// ==================== RESTAURANT PAGE ====================
class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  List<dynamic> restaurants = [];
  bool isLoading = true;

  final String baseUrl =
      'https://deligood-backend.onrender.com//api/menu/restaurants/';

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          restaurants = decoded;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Erreur fetch: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Restaurants",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF344955),
        centerTitle: true,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
          ? Center(
              child: Text(
                'Aucun restaurant trouvé',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GridView.builder(
                itemCount: restaurants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  final imageUrl = restaurant['photo'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          reverseTransitionDuration: const Duration(
                            milliseconds: 500,
                          ),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: CommandePage(
                                      restaurantId: restaurant['id'],
                                      restaurantName:
                                          restaurant['name'] ?? 'Sans nom',
                                      image: imageUrl ?? 'assets/images/n.png',
                                    ),
                                  ),
                                );
                              },
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: Hero(
                                tag: 'restaurantHero_${restaurant['id']}',
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/n.png',
                                                fit: BoxFit.cover,
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        'assets/images/n.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant['name'] ?? 'Sans nom',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF222831),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  restaurant['description'] ??
                                      'Pas de description',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF4E4E50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ==================== COMMANDE PAGE ====================
class CommandePage extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final String image;

  const CommandePage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.image,
  });

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  late Future<List<MenuItem>> _futureMenu;

  @override
  void initState() {
    super.initState();
    _futureMenu = fetchMenu();
  }

  Future<List<MenuItem>> fetchMenu() async {
    final response = await http.get(
      Uri.parse(
        'https://deligood-backend.onrender.com//api/menu/menu/restaurant/${widget.restaurantId}/',
      ),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception("Erreur chargement menu");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'restaurantHero_${widget.restaurantId}',
                child: Image.network(
                  widget.image,
                  width: double.infinity,
                  height: 28.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 28.h,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.store, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: 4.h,
                left: 4.w,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                bottom: 3.h,
                left: 4.w,
                child: Text(
                  widget.restaurantName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: FutureBuilder<List<MenuItem>>(
                future: _futureMenu,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const Center(child: Text("Aucun plat disponible"));
                  }

                  return GridView.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 3.w,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          // Ici tu peux naviguer vers le détail du plat
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.fastfood),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(2.w),
                                child: Column(
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      "${item.price} FCFA",
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}

// ==================== MENU ITEM MODEL ====================
class MenuItem {
  final int id;
  final String name;
  final String imageUrl;
  final int price;

  MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'] ?? '',
      price: json['price'],
    );
  }
}
