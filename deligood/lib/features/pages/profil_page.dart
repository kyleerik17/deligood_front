import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

import 'package:deligood/core/network/api.dart';

import 'package:deligood/features/pages/wallet_page.dart';
import 'package:deligood/features/pages/info_perso.dart';
import 'package:deligood/features/auth/widgets/logout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String userType = '';
  String initials = '?';
  Uint8List? avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchProfileFromApi();
  }

  // =====================
  // LOAD USER LOCALE
  // =====================
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarBase64 = prefs.getString('avatar_base64');

    setState(() {
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
      phoneNumber = prefs.getString('phone_number') ?? '';
      userType = prefs.getString('user_type') ?? '';
      initials = _buildInitials(firstName, lastName);
      if (avatarBase64 != null) {
        avatarBytes = base64Decode(avatarBase64);
      }
    });
  }

  // =====================
  // FETCH PROFILE API
  // =====================
  Future<void> _fetchProfileFromApi() async {
    try {
      print("Fetching profile from API...");
      final data = await ProfileApi.fetchProfile();
      print("Profile data: $data");

      setState(() {
        firstName = data['first_name'] ?? '';
        lastName = data['last_name'] ?? '';
        phoneNumber = data['phone_number'] ?? '';
        userType = data['user_type'] ?? '';
        initials = _buildInitials(firstName, lastName);
        if (data['avatar_base64'] != null) {
          avatarBytes = ProfileApi.decodeAvatar(data['avatar_base64']);
        }
      });
    } catch (e) {
      print("Erreur fetch profile: $e");
    }
  }

  String _buildInitials(String f, String l) {
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
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
                    height: 23.h,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5F2EEA), Color(0xFF7B61FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 5.w,
                  top: 5.h,
                  child: Text(
                    'Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
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
                    elevation: 10,
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
                                fontSize: 22.sp,
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
                    ),
                  ),
                  Gap(0.4.h),
                  Text(
                    phoneNumber.isEmpty ? '—' : phoneNumber,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey.shade700,
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
                      title: 'Modifier profil',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InfoPersoPage(),
                          ),
                        );
                        await _fetchProfileFromApi(); // refresh après modif
                      },
                    ),

                    if (showWallet)
                      OptionCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Mon solde',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletPage(),
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
                      title: 'Politique de confidentialité',
                      onTap: () {},
                    ),

                    OptionCard(
                      icon: Icons.support_agent,
                      title: 'Nous contacter',
                      onTap: () {},
                    ),

                    OptionCard(
                      icon: Icons.logout,
                      title: 'Déconnexion',
                      color: Colors.red.shade600,
                      iconColor: Colors.white,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final orderId = prefs.getInt('last_order_id');
                        await LogoutService.performLogout(
                          context,
                          orderId: orderId,
                        );
                      },
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.symmetric(vertical: 0.8.h),
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: widget.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  const BoxShadow(
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
                  color: widget.color != null ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: widget.color != null ? Colors.white : Colors.grey.shade400,
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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
