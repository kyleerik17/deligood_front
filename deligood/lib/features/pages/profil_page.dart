import 'dart:convert';
import 'dart:typed_data';
import 'package:deligood/features/pages/wallet_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';
import 'package:deligood/features/auth/widgets/logout.dart';
import 'package:deligood/features/pages/info_perso.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String initials = '?';
  String userType = '';
  Uint8List? avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fName = prefs.getString('first_name');
    final lName = prefs.getString('last_name');
    final phone = prefs.getString('phone_number');
    final type = prefs.getString('user_type') ?? '';
    final avatarBase64 = prefs.getString('avatar_base64');

    setState(() {
      firstName = fName ?? '';
      lastName = lName ?? '';
      phoneNumber = phone ?? '';
      userType = type;
      initials = _buildInitials(firstName, lastName);
      if (avatarBase64 != null) avatarBytes = base64Decode(avatarBase64);
    });
  }

  String _buildInitials(String fName, String lName) {
    if (fName.isNotEmpty && lName.isNotEmpty)
      return '${fName[0]}${lName[0]}'.toUpperCase();
    if (fName.isNotEmpty) return fName[0].toUpperCase();
    return '?';
  }

  bool get showWallet => userType != 'client';

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${firstName.isEmpty ? '' : firstName} ${lastName.isEmpty ? '' : lastName}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Stack(
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 22.h,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
                Positioned(
                  left: 5.w,
                  top: 5.h,
                  child: Text(
                    "Profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),

            // ================= AVATAR =================
            Transform.translate(
              offset: Offset(0, -6.h),
              child: Column(
                children: [
                  Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 12.w,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarBytes != null
                          ? MemoryImage(avatarBytes!)
                          : null,
                      child: avatarBytes == null
                          ? Text(
                              initials,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Gap(1.h),
                  Text(
                    fullName.isEmpty ? 'Utilisateur' : fullName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Gap(0.5.h),
                  Text(
                    phoneNumber.isEmpty ? '—' : phoneNumber,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),

            // ================= OPTIONS =================
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ListView(
                  children: [
                    Gap(2.h),
                    OptionCard(
                      icon: Icons.person,
                      title: "Modifier profil",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InfoPersoPage()),
                        ).then((_) => _loadUserFromPrefs());
                      },
                    ),

                    // 🔹 Carte Solde seulement pour livreur/resto
                    if (showWallet)
                      OptionCard(
                        icon: Icons.receipt_long,
                        title: "Solde",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletPage(),
                            ),
                          );
                        },
                      ),

                    OptionCard(
                      icon: Icons.policy,
                      title: "Conditions d'utilisation",
                      onTap: () {},
                    ),
                    OptionCard(
                      icon: Icons.privacy_tip,
                      title: "Politique de confidentialité",
                      onTap: () {},
                    ),
                    OptionCard(
                      icon: Icons.support_agent,
                      title: "Nous contacter",
                      onTap: () {},
                    ),
                    OptionCard(
                      icon: Icons.logout,
                      title: "Déconnexion",
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final orderId = prefs.getInt('last_order_id');
                        await LogoutService.performLogout(
                          context,
                          orderId: orderId,
                        );
                      },
                      color: Colors.red.shade600,
                      iconColor: Colors.white,
                    ),
                    Gap(4.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= OPTION CARD =================
class OptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;

  const OptionCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.symmetric(vertical: 0.8.h),
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: widget.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.iconColor ?? Colors.deepPurple),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                  color: widget.color != null ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: widget.color != null ? Colors.white : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HEADER CLIPPER =================
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
