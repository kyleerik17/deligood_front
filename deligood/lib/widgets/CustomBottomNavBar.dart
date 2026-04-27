import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:deligood/features/client/screens/RestaurantPage.dart';
import 'package:deligood/features/restaurant/screens/commande_resto_page.dart';
import 'package:flutter/material.dart';
import 'package:deligood/features/pages/panier_page.dart';
import 'package:deligood/features/pages/profil_page.dart';
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:deligood/features/livreur/screens/pages/historique_liv.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:deligood/features/pages/cree_menu_page.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String userRole; // "client" | "restaurant" | "livreur"
  final int orderId;     // ID de la commande en cours (pour restaurant)

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

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      _currentIndex = 0;
    }
  }

  /// ================= PAGES =================
  List<Widget> _buildPages() {
    switch (widget.userRole) {
      // ================= LIVREUR =================
      case "livreur":
        return const [
          HomeLivreur(),
          CoursePage(),
          HistoryLivPage(),
          ProfilePage(),
        ];

      // ================= RESTAURANT =================
      case "restaurant":
        return [
          HomeRestaurant(orderId: widget.orderId),
          const CommandeRestoPage(),
          CreateMenuPage(
            userRole: widget.userRole,
            orderId: widget.orderId,
          ),
          const ProfilePage(),
        ];

      // ================= CLIENT =================
      default:
        return  [
          HomeScreen(orderId: widget.orderId),
          RestaurantPage(),
          PanierPage(),
          ProfilePage(),
        ];
    }
  }

  /// ================= BOTTOM NAV ITEMS =================
  List<BottomNavigationBarItem> _buildItems() {
    switch (widget.userRole) {
      case "livreur":
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: "Courses"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ];

      case "restaurant":
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Commandes"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ];

      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Restaurants"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Panier"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ];
    }
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      key: ValueKey(widget.userRole), // empêche mélange d'état entre rôles
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: _buildItems(),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}