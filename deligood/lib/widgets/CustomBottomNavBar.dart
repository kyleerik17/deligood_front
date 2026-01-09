import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:deligood/features/livreur/screens/pages/historique_liv.dart';
import 'package:deligood/features/pages/commandes_page.dart';
import 'package:flutter/material.dart';
import 'package:deligood/features/client/screens/home_screen.dart';
import 'package:deligood/features/pages/course_page.dart';
import 'package:deligood/features/pages/profil_page.dart';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:deligood/features/restaurant/screens/commande_resto.dart';
import 'package:deligood/features/pages/panier_page.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String userRole; // "client", "restaurant", "livreur"
   final int _currentIndex = 0;
  CourseModel? selectedCourse; // 🔹 course sélectionnée
  final int orderId;

  CustomBottomNavBar({super.key, required this.userRole, required this.orderId, this.selectedCourse});
  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}
class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _currentIndex = 0;
  CourseModel? selectedCourse; // 🔹 stocke la course sélectionnée ici

  List<Widget> getPages() {
    switch (widget.userRole) {
      case "livreur":
        return [
          HomeLivreurWrapper(), // reçoit la course sélectionnée
          CoursePage(
            onCourseSelected: (course) {
              setState(() {
                selectedCourse = course; // 🔹 met à jour ici
                _currentIndex = 0; // aller automatiquement à HomeLivreur
              });
            },
          ),
          HistoryPage(),
          ProfilePage(),
        ];
      case "restaurant":
        return [
          HomeRestaurant(orderId: widget.orderId),
          CommandeRestoPage(),
          PanierPage(),
          ProfilePage(),
        ];
      default:
        return [
          HomeScreen(),
          CommandePage(),
          PanierPage(),
          ProfilePage(),
        ];
    }
  }

  List<BottomNavigationBarItem> getItems() {
    if (widget.userRole == "livreur") {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: "Course"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Commande R"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = getPages();
    final items = getItems();

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white,
        items: items,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
