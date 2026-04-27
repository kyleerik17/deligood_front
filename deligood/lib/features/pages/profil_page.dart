import 'dart:convert';
import 'dart:typed_data';

import 'package:deligood/core/api/profile_api.dart';
import 'package:deligood/core/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:deligood/features/pages/wallet_page.dart';
import 'package:deligood/features/pages/info_perso.dart';
import 'package:deligood/features/auth/widgets/logout.dart';

const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kError = Color(0xFFFF5A5F);

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
  String email = '';
  String initials = '?';

  Uint8List? avatarBytes;
  bool isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _init();
  }

  Future<void> _init() async {
    await _loadUser();
    await _fetchProfile();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ================= DATA =================

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint('📦 SharedPrefs keys: ${prefs.getKeys()}');
      debugPrint('first_name   => ${prefs.getString('first_name')}');
      debugPrint('last_name    => ${prefs.getString('last_name')}');
      debugPrint('phone_number => ${prefs.getString('phone_number')}');
      debugPrint('email        => ${prefs.getString('email')}');
      debugPrint('user_type    => ${prefs.getString('user_type')}');

      final f = prefs.getString('first_name') ?? '';
      final l = prefs.getString('last_name') ?? '';

      if (!mounted) return;
      setState(() {
        firstName   = f;
        lastName    = l;
        phoneNumber = prefs.getString('phone_number') ?? '';
        email       = prefs.getString('email') ?? '';
        userType    = prefs.getString('user_type') ?? '';
        initials    = _buildInitials(f, l);

        final avatarBase64 = prefs.getString('avatar_base64');
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          try {
            avatarBytes = base64Decode(avatarBase64);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('❌ _loadUser error: $e');
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ProfileApi.fetchProfile();

      if (data.isEmpty) {
        debugPrint('⚠️ API vide, on garde le cache local');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      // Mise à jour SharedPreferences avec les données fraîches
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_name',   data['first_name']   ?? firstName);
      await prefs.setString('last_name',    data['last_name']    ?? lastName);
      await prefs.setString('phone_number', data['phone_number'] ?? phoneNumber);
      await prefs.setString('email',        data['email']        ?? email);
      await prefs.setString('user_type',    data['user_type']    ?? userType);

      final f = data['first_name'] ?? firstName;
      final l = data['last_name']  ?? lastName;

      if (!mounted) return;
      setState(() {
        firstName   = f;
        lastName    = l;
        phoneNumber = data['phone_number'] ?? phoneNumber;
        email       = data['email']        ?? email;
        userType    = data['user_type']    ?? userType;
        initials    = _buildInitials(f, l);
        avatarBytes = ImageUtils.decodeBase64Image(data['avatar_base64']) ?? avatarBytes;
        isLoading   = false;
      });
    } catch (e) {
      debugPrint('❌ _fetchProfile error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _buildInitials(String f, String l) {
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  bool get showWallet => userType != 'client';

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final fullName = "$firstName $lastName".trim();

    return Scaffold(
      backgroundColor: kBg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _header(fullName),
                  SliverToBoxAdapter(child: _content()),
                ],
              ),
            ),
    );
  }

  // ================= HEADER =================
  Widget _header(String fullName) {
    return SliverAppBar(
      expandedHeight: 32.h,
      pinned: true,
      backgroundColor: kBg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF3EC), Color(0xFFF7F3EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: avatarBytes == null
                            ? const LinearGradient(
                                colors: [kOrange, Color(0xFFFF8A50)],
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: kOrange.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: avatarBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                avatarBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: kWhite,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: kOrange, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 14, color: kOrange),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                Text(
                  fullName.isEmpty ? "Utilisateur" : fullName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),

                if (phoneNumber.isNotEmpty)
                  Text(
                    phoneNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: kTextSecondary,
                    ),
                  ),

                SizedBox(height: 3.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= CONTENT =================
  Widget _content() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Row(
            children: [
              if (showWallet)
                Expanded(
                  child: _quickCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: "Wallet",
                    color: kTeal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletPage()),
                      );
                    },
                  ),
                ),
              SizedBox(width: 3.w),
              Expanded(
                child: _quickCard(
                  icon: Icons.person_rounded,
                  label: "Profil",
                  color: kOrange,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InfoPersoPage()),
                    );
                    _init();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          _menuCard([
            _menuItem(Icons.notifications, "Notifications"),
            _menuItem(Icons.language, "Langue", trailing: "Français"),
          ]),

          SizedBox(height: 2.h),

          _menuCard([
            _menuItem(Icons.help_outline, "Support"),
            _menuItem(Icons.chat, "Contact"),
          ]),

          SizedBox(height: 2.h),

          _menuCard([
            _menuItem(Icons.description, "Conditions"),
            _menuItem(Icons.privacy_tip, "Confidentialité"),
          ]),

          SizedBox(height: 4.h),

          _logoutButton(),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================
  Widget _quickCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 1.h),
            Text(label, style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(IconData icon, String title, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: kTextSecondary),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: GoogleFonts.poppins(color: kTextSecondary)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: kError.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "Se déconnecter",
            style: GoogleFonts.poppins(
              color: kError,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              final orderId = prefs.getInt('last_order_id');
              await LogoutService.performLogout(context, orderId: orderId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kError),
            child: const Text("Oui"),
          ),
        ],
      ),
    );
  }
}