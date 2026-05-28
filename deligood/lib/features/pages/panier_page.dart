import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/pages/confirm_order_page.dart';

class CartItem {
  final int id;
  final int menuItemId;
  final String name;
  final String image;
  final int quantity;
  final double price;
  final int restaurantId;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    required this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      menuItemId: json['menu_item_id'] ?? json['menu_item'],
      name: json['menu_item_name'],
      image: json['menu_item_image'] ?? '',
      quantity: json['quantity'],
      price: (json['menu_item_price'] as num).toDouble(),
      restaurantId: json['restaurant_id'],
    );
  }
}

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  late Future<List<CartItem>> _futureCart;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    _futureCart = LivreurApi.fetchCart().then(
      (data) => data.map((e) => CartItem.fromJson(e)).toList(),
    );
  }

  Future<void> removeItem(int id) async {
    await LivreurApi.removeCartItem(id);
    setState(_loadCart);
  }

  double calcTotal(List<CartItem> items) {
    return items.fold(0, (s, e) => s + e.price * e.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<CartItem>>(
            future: _futureCart,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snap.data!;
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    "Panier vide",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final total = calcTotal(items);

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        const Text(
                          "Mon panier",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];

                        return Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item.image,
                                  width: 18.w,
                                  height: 18.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 4.w),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      "${item.quantity} x ${item.price} FCFA",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                onPressed: () => removeItem(item.id),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$total FCFA",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmOrderPage(
                                  items: items,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 6.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Commander",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}