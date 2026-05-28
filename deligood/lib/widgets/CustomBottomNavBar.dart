import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:flutter/material.dart';

// ================= CLIENT =================
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/client/screens/client_home_page.dart';
import 'package:deligood/features/client/screens/RestaurantPage.dart' as client;
import 'package:deligood/features/orders/screens/cart_page.dart' as orders;
import 'package:deligood/features/pages/profil_page.dart';

// ================= LIVREUR =================
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:deligood/features/livreur/screens/pages/historique_liv.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';

// ================= RESTAURANT =================
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:deligood/features/restaurant/screens/commande_resto.dart';
import 'package:deligood/features/restaurant/screens/create_menu_page.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String userRole; // client | restaurant | livreur
  final int orderId;

  const CustomBottomNavBar({
    super.key,
    required this.userRole,
    required this.orderId,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _currentIndex = 0;
  CourseModel? selectedCourse;

  // ========================== PAGES ==========================
  List<Widget> _buildPages() {
    switch (widget.userRole) {
      // ================= LIVREUR =================
      case "livreur":
        return [
          HomeLivreur(course: selectedCourse),

          CoursePage(
            onCourseTaken: (course) {
              setState(() {
                selectedCourse = course;
                _currentIndex = 0;
              });
            },
          ),

          const HistoryLivPage(),
          const ProfilePage(),
        ];

      // ================= RESTAURANT =================
      case "restaurant":
        return [
          HomeRestaurant(orderId: widget.orderId),
          const CommandeRestoPage(),
          CreateMenuPage(userRole: widget.userRole),
          const ProfilePage(),
        ];

      // ================= CLIENT =================
      default:
        return [
          HomeScreen(orderId: widget.orderId),
          const client.RestaurantPage(),
          const orders.PanierPage(),
          const ProfilePage(),
        ];
    }
  }

  // ========================== ITEMS ==========================
  List<BottomNavigationBarItem> _buildItems() {
    if (widget.userRole == "livreur") {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining_rounded),
          label: "Courses",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: "Historique",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: "Profil",
        ),
      ];
    }

    if (widget.userRole == "restaurant") {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: "Commandes",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_rounded),
          label: "Menu",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: "Profil",
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Accueil"),
      BottomNavigationBarItem(
        icon: Icon(Icons.storefront_rounded),
        label: "Restos",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_rounded),
        label: "Panier",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: "Profil",
      ),
    ];
  }

  // ========================== BUILD ==========================
  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.surface,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline.withValues(alpha: .45)),
            boxShadow: AppShadows.raised,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.orange,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: AppText.label(color: AppColors.orange),
              unselectedLabelStyle: AppText.bodySm(color: AppColors.textMuted),
              elevation: 0,
              items: _buildItems(),
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ),
      ),
    );
  }
}
