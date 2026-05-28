import 'dart:convert';
import 'dart:typed_data';

import 'package:deligood/core/api/profile_api.dart';
import 'package:deligood/features/orders/screens/history_page.dart';
import 'package:deligood/features/profile/screens/wallet_page.dart';
import 'package:deligood/features/profile/screens/info_perso_page.dart';
import 'package:deligood/features/auth/widgets/logout.dart';
import 'package:deligood/features/notifications/screens/notifications_page.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────
// DESIGN TOKENS — CREAM THEME
// ─────────────────────────────
const kCreamBg = Color(0xFFF5EFE6); // page background
const kCreamSurface = Color(0xFFEDE0CE); // hero background / body bg
const kCreamCard = Color(0xFFFAF5EE); // card / menu background
const kCreamBorder = Color(0xFFD4C0A8); // dividers & borders

const kTerra = Color(0xFFD4895A); // primary accent – terracotta
const kTerraLight = Color(0xFFF5E6D8); // terra icon bg
const kSage = Color(0xFF5A8A52); // wallet accent
const kSageLight = Color(0xFFE2EDE0); // sage icon bg

const kTextDark = Color(0xFF2C1A0E); // headings
const kTextMid = Color(0xFF7A5C44); // secondary
const kTextMuted = Color(0xFF9E826A); // hints / labels
const kError = Color(0xFFC0402A); // destructive

// ─────────────────────────────
// PROFILE PAGE
// ─────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String userType = '';
  String initials = '?';

  Uint8List? avatarBytes;
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _init();
  }

  Future<void> _init() async {
    await _loadLocal();
    await _fetchProfile();
    if (mounted) _controller.forward();
  }

  // ─── LOCAL CACHE ────────────────────────────────────────────────────────────
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString('first_name') ?? '';
    final l = prefs.getString('last_name') ?? '';
    setState(() {
      firstName = f;
      lastName = l;
      phoneNumber = prefs.getString('phone_number') ?? '';
      userType = prefs.getString('user_type') ?? '';
      initials = _buildInitials(f, l);
      final av = prefs.getString('avatar_base64');
      if (av != null && av.isNotEmpty) {
        try {
          avatarBytes = base64Decode(av);
        } catch (_) {}
      }
    });
  }

  // ─── API ────────────────────────────────────────────────────────────────────
  Future<void> _fetchProfile() async {
    try {
      final res = await ProfileApi.fetchProfile();
      final data = res['data'];
      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_name', data['first_name'] ?? '');
      await prefs.setString('last_name', data['last_name'] ?? '');
      await prefs.setString('phone_number', data['phone_number'] ?? '');
      await prefs.setString('user_type', data['user_type'] ?? '');

      setState(() {
        firstName = data['first_name'] ?? firstName;
        lastName = data['last_name'] ?? lastName;
        phoneNumber = data['phone_number'] ?? phoneNumber;
        userType = data['user_type'] ?? userType;
        initials = _buildInitials(firstName, lastName);
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  String _buildInitials(String f, String l) {
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  bool get showWallet => userType != 'client';

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fullName = '$firstName $lastName'.trim();

    return Scaffold(
      backgroundColor: kCreamBg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kTerra))
          : FadeTransition(
              opacity: _fade,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHero(fullName),
                  SliverToBoxAdapter(child: _buildBody()),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────
  // HERO SLIVER
  // ─────────────────────────────
  Widget _buildHero(String name) {
    return SliverAppBar(
      expandedHeight: 32.h,
      pinned: true,
      elevation: 0,
      backgroundColor: kCreamSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDE0CE), Color(0xFFF5EFE6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mon profil',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      _iconBtn(Icons.notifications_none_rounded, () {}),
                    ],
                  ),
                ),

                // ── Avatar + name ─────────────────────────────────────────────
                CircleAvatar(
                  radius: 40,
                  backgroundColor: kTerra,
                  backgroundImage: avatarBytes != null
                      ? MemoryImage(avatarBytes!)
                      : null,
                  child: avatarBytes == null
                      ? Text(
                          initials,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: 1.2.h),
                Text(
                  name.isEmpty ? 'Utilisateur' : name,
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                Text(
                  phoneNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: kTextMuted,
                  ),
                ),

                // ── Stats row ─────────────────────────────────────────────────
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Row(
                    children: [
                      _statChip('24', 'Commandes'),
                      SizedBox(width: 2.w),
                      _statChip('8', 'En cours'),
                      SizedBox(width: 2.w),
                      _statChip('4.9 ★', 'Note', starColor: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          shape: BoxShape.circle,
          border: Border.all(color: kCreamBorder.withOpacity(0.5), width: 0.5),
        ),
        child: Icon(icon, color: kTextDark, size: 20),
      ),
    );
  }

  Widget _statChip(String value, String label, {bool starColor = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCreamBorder.withOpacity(0.35), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: starColor ? kTerra : kTextDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 9.sp, color: kTextMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // WAVE SEPARATOR
  // ─────────────────────────────
  Widget _wave() {
    return CustomPaint(
      size: Size(double.infinity, 24),
      painter: _WavePainter(),
    );
  }

  // ─────────────────────────────
  // BODY
  // ─────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wave(),
        Container(
          color: kCreamSurface,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Action cards ─────────────────────────────────────────────────
              SizedBox(height: 2.h),
              Row(
                children: [
                  if (showWallet) ...[
                    Expanded(
                      child: _actionCard(
                        title: 'Wallet',
                        subtitle: 'Solde disponible',
                        icon: Icons.wallet_rounded,
                        iconBg: kSageLight,
                        iconColor: kSage,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletPage()),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                  ],
                  Expanded(
                    child: _actionCard(
                      title: 'Modifier profil',
                      subtitle: 'Infos personnelles',
                      icon: Icons.person_outline_rounded,
                      iconBg: kTerraLight,
                      iconColor: kTerra,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InfoPersoPage(),
                          ),
                        );
                        _init();
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // ── Section: Activité ─────────────────────────────────────────────
              _sectionLabel('Activité'),
              SizedBox(height: 1.h),
              _menuGroup([
                _MenuItem(
                  icon: Icons.history_rounded,
                  iconBg: kSageLight,
                  iconColor: kSage,
                  title: 'Historique',
                  subtitle: 'Vos commandes passées',
                  onTap: () {
                    final mode = switch (userType) {
                      'restaurant' => HistoryMode.restaurant,
                      'livreur' => HistoryMode.livreur,
                      _ => HistoryMode.client,
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(mode: mode),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  iconBg: kTerraLight,
                  iconColor: kTerra,
                  title: 'Notifications',
                  subtitle: 'Gérer vos alertes',
                  badge: '3',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ),
                ),
              ]),

              SizedBox(height: 2.h),

              // ── Section: Préférences ──────────────────────────────────────────
              _sectionLabel('Préférences'),
              SizedBox(height: 1.h),
              _menuGroup([
                _MenuItem(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFFE8E2F5),
                  iconColor: const Color(0xFF7A5CC0),
                  title: 'Langue',
                  subtitle: 'Choisir la langue',
                  trailing: 'Français',
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  iconBg: const Color(0xFFE0EDF5),
                  iconColor: const Color(0xFF3A7AAA),
                  title: 'Confidentialité',
                  subtitle: 'Données & sécurité',
                ),
              ]),

              SizedBox(height: 2.h),

              // ── Section: Aide ─────────────────────────────────────────────────
              _sectionLabel('Aide'),
              SizedBox(height: 1.h),
              _menuGroup([
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  iconBg: kTerraLight,
                  iconColor: kTerra,
                  title: 'Support',
                  subtitle: "Contacter l'assistance",
                ),
              ]),

              SizedBox(height: 4.h),

              // ── Logout ────────────────────────────────────────────────────────
              _logoutButton(),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────
  // ACTION CARD
  // ─────────────────────────────
  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: kCreamCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kCreamBorder.withOpacity(0.4), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(height: 1.2.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 10.sp, color: kTextMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // MENU GROUP
  // ─────────────────────────────
  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: kCreamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCreamBorder.withOpacity(0.35), width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return _buildMenuItem(e.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, {required bool isLast}) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(18))
          : BorderRadius.zero,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: kCreamBorder.withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            SizedBox(width: 3.w),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: kTextDark,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Badge / trailing tag
            if (item.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kTerra.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.badge} nouvelles',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    color: kTerra,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
            ],
            if (item.trailing != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kCreamSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.trailing!,
                  style: GoogleFonts.poppins(fontSize: 10.sp, color: kTextMid),
                ),
              ),
              SizedBox(width: 2.w),
            ],
            Icon(Icons.chevron_right_rounded, color: kCreamBorder, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // SECTION LABEL
  // ─────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
        color: kTextMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  // ─────────────────────────────
  // LOGOUT BUTTON
  // ─────────────────────────────
  Widget _logoutButton() {
    return GestureDetector(
      onTap: _showLogout,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          color: kCreamCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kError.withOpacity(0.25), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: kError, size: 20),
            SizedBox(width: 2.w),
            Text(
              'Se déconnecter',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: kError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // LOGOUT BOTTOM SHEET
  // ─────────────────────────────
  void _showLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kCreamCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kCreamBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.5.h),
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout_rounded, color: kError, size: 28),
            ),
            SizedBox(height: 2.h),
            Text(
              'Déconnexion',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              'Vous allez être déconnecté de votre\ncompte. Voulez-vous continuer ?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.sp, color: kTextMuted),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      decoration: BoxDecoration(
                        color: kCreamSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: kTextMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      final orderId = prefs.getInt('last_order_id');
                      await LogoutService.performLogout(
                        context,
                        orderId: orderId,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      decoration: BoxDecoration(
                        color: kError,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Oui, quitter',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ─────────────────────────────
// WAVE PAINTER
// ─────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kCreamSurface;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

// ─────────────────────────────
// DATA CLASS: MENU ITEM
// ─────────────────────────────
class _MenuItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
  });
}
