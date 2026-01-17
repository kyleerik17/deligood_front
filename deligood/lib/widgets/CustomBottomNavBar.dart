// ========================== CUSTOM BOTTOM NAV BAR ==========================
import 'package:deligood/features/livreur/screens/pages/RestaurantPage.dart';
import 'package:flutter/material.dart';

// ================= CLIENT =================
import 'package:deligood/features/client/screens/home_screen.dart';
import 'package:deligood/features/pages/commandes_page.dart';
import 'package:deligood/features/pages/panier_page.dart';
import 'package:deligood/features/pages/profil_page.dart';

// ================= LIVREUR =================
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:deligood/features/livreur/screens/pages/historique_liv.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';

// ================= RESTAURANT =================
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:deligood/features/restaurant/screens/commande_resto.dart';
import 'package:deligood/features/pages/cree_menu_page.dart';

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
          CreateMenuPage(userRole: widget.userRole, orderId: widget.orderId),
          const ProfilePage(),
        ];

      // ================= CLIENT =================
      default:
        return [
          const HomeScreen(),

          RestaurantPage(),

          const PanierPage(),
          const ProfilePage(),
        ];
    }
  }

  // ========================== ITEMS ==========================
  List<BottomNavigationBarItem> _buildItems() {
    if (widget.userRole == "livreur") {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bike),
          label: "Courses",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ];
    }

    if (widget.userRole == "restaurant") {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "Commandes",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: "Menu",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
      BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Commandes"),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Panier"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
    ];
  }

  // ========================== BUILD ==========================
  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white,
        items: _buildItems(),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
