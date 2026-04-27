import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:deligood/features/client/screens/RestaurantPage.dart';
import 'package:deligood/features/restaurant/screens/commande_resto_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deligood/features/pages/panier_page.dart';
import 'package:deligood/features/pages/profil_page.dart';
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:deligood/features/livreur/screens/pages/historique_liv.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';
import 'package:deligood/features/pages/cree_menu_page.dart';

// ================== DESIGN SYSTEM ==================
const kOrange     = Color(0xFFFF6B35);
const kOrangeDark = Color(0xFFFF5722);
const kTeal       = Color(0xFF00CCBC);
const kBg         = Color(0xFFF7F3EF);
const kCard       = Colors.white;
const kText       = Color(0xFF1A1A1A);
const kSubText    = Color(0xFF757575);

// ================== NAV ITEM MODEL ==================
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ================== WIDGET ==================
class CustomBottomNavBar extends StatefulWidget {
  final String userRole;
  final int orderId;

  const CustomBottomNavBar({
    super.key,
    required this.userRole,
    required this.orderId,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {

  int _currentIndex = 0;

  // Pages construites une seule fois et gardées en mémoire
  late final List<Widget> _pages;
  late final List<_NavItem> _navItems;

  late AnimationController _indicatorCtrl;

  @override
  void initState() {
    super.initState();

    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // ✅ FIX PRINCIPAL : on construit les pages UNE SEULE FOIS
    // selon le rôle exact, sans jamais les recréer
    _buildPagesForRole();
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  // ================== BUILD PAGES PAR RÔLE ==================
  void _buildPagesForRole() {
    switch (widget.userRole) {
      case 'livreur':
        _pages = const [
          HomeLivreur(),
          CoursePage(),
          HistoryLivPage(),
          ProfilePage(),
        ];
        _navItems = const [
          _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,         label: "Accueil"),
          _NavItem(icon: Icons.delivery_dining_outlined, activeIcon: Icons.delivery_dining,   label: "Courses"),
          _NavItem(icon: Icons.history_outlined,     activeIcon: Icons.history,               label: "Historique"),
          _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,        label: "Profil"),
        ];
        break;

      case 'restaurant':
        _pages = [
          HomeRestaurant(orderId: widget.orderId),
          const CommandeRestoPage(),
          CreateMenuPage(userRole: 'restaurant', orderId: 0),
          const ProfilePage(),
        ];
        _navItems = const [
          _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,          label: "Accueil"),
          _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,         label: "Commandes"),
          _NavItem(icon: Icons.menu_book_outlined,   activeIcon: Icons.menu_book,             label: "Menu"),
          _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,        label: "Profil"),
        ];
        break;

      // 'user' / 'client' ou tout autre rôle → client par défaut
      default:
        _pages = [
          HomeScreen(orderId: widget.orderId),
          RestaurantPage(),
          PanierPage(),
          ProfilePage(),
        ];
        _navItems = const [
          _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,          label: "Accueil"),
          _NavItem(icon: Icons.restaurant_outlined,  activeIcon: Icons.restaurant,            label: "Restaurants"),
          _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: "Panier"),
          _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,        label: "Profil"),
        ];
    }
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _indicatorCtrl.forward(from: 0);
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Pas de ValueKey ici — on ne veut pas reconstruire le Scaffold
      body: IndexedStack(
        // IndexedStack garde toutes les pages en mémoire
        // et n'affiche que celle à _currentIndex
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ================== NAV BAR CUSTOM ==================
  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (i) => _buildNavItem(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item      = _navItems[index];
    final isActive  = _currentIndex == index;

    // Couleur selon rôle
    final activeColor = widget.userRole == 'livreur'
        ? kTeal
        : widget.userRole == 'restaurant'
            ? kOrangeDark
            : kOrange;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : kSubText,
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activeColor,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}