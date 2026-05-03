import 'package:deligood/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 DESIGN SYSTEM
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Colors.grey;

// ================== MODEL ==================
class CartItem {
  final int id;
  final String name;
  final String image;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['menu_item_name'],
      image: json['menu_item_image'] ?? '',
      quantity: json['quantity'],
      price: (json['menu_item_price'] ?? 0).toDouble(),
    );
  }

  double get subtotal => price * quantity;
}

// ================== PAGE ==================
class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CartItem>> _futureCart;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadCart();
  }

  void _loadCart() {
    _futureCart = PanierApi.fetchCart().then((data) {
      _anim.forward(from: 0);
      return data.map((e) => CartItem.fromJson(e)).toList();
    });

    setState(() {});
  }

  double _total(List<CartItem> items) =>
      items.fold(0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),

            Expanded(
              child: FutureBuilder<List<CartItem>>(
                future: _futureCart,
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: kOrange),
                    );
                  }

                  final items = snap.data!;

                  if (items.isEmpty) {
                    return _empty();
                  }

                  return Column(
                    children: [
                      Expanded(child: _list(items)),
                      _bottom(items),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== HEADER ==================
  Widget _header() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Row(
        children: [
          _circle(Icons.arrow_back_ios_new, () => Navigator.pop(context)),

          const Spacer(),

          Column(
            children: [
              Text(
                "Mon panier",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              Text(
                "Vos plats sélectionnés",
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          _circle(Icons.refresh_rounded, _loadCart),
        ],
      ),
    );
  }

  // ================== LIST ==================
  Widget _list(List<CartItem> items) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _anim,
              curve: Interval(i / items.length, 1, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: kBg,
                    child: item.image.isNotEmpty
                        ? Image.network(item.image, fit: BoxFit.cover)
                        : const Icon(Icons.fastfood),
                  ),
                ),

                SizedBox(width: 3.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        "${item.price} FCFA",
                        style: GoogleFonts.poppins(color: kTextSecondary),
                      ),
                    ],
                  ),
                ),

                Text(
                  "${item.quantity}x",
                  style: GoogleFonts.poppins(
                    color: kOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================== EMPTY ==================
  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 50, color: kOrange),
          ),
          SizedBox(height: 2.h),
          Text(
            "Panier vide",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            "Ajoute des plats pour commencer",
            style: GoogleFonts.poppins(color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  // ================== BOTTOM ==================
  Widget _bottom(List<CartItem> items) {
    final total = _total(items);

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total",
                  style: GoogleFonts.poppins(color: kTextSecondary)),

              Text(
                "${total.toStringAsFixed(0)} FCFA",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Commander",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== ICON CIRCLE ==================
  Widget _circle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: kWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Icon(icon, size: 18, color: kTextPrimary),
      ),
    );
  }
}