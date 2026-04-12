import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

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
  String email = '';
  String initials = '?';
  Uint8List? avatarBytes;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchProfileFromApi();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarBase64 = prefs.getString('avatar_base64');

    setState(() {
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
      phoneNumber = prefs.getString('phone_number') ?? '';
      email = prefs.getString('email') ?? '';
      userType = prefs.getString('user_type') ?? '';
      initials = _buildInitials(firstName, lastName);

      // Charger la photo depuis les prefs
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
          print("DEBUG Profile: Photo chargée depuis prefs");
        } catch (e) {
          print("DEBUG Profile: Erreur décodage photo: $e");
          avatarBytes = null;
        }
      }

      isLoading = false;
    });
  }

  Future<void> _fetchProfileFromApi() async {
    try {
      final data = await ProfileApi.fetchProfile();

      setState(() {
        firstName = data['first_name'] ?? '';
        lastName = data['last_name'] ?? '';
        phoneNumber = data['phone_number'] ?? '';
        email = data['email'] ?? '';
        userType = data['user_type'] ?? '';
        initials = _buildInitials(firstName, lastName);

        // Charger l'avatar si disponible
        if (data['avatar_base64'] != null) {
          avatarBytes = ProfileApi.decodeAvatar(data['avatar_base64']);
          print("DEBUG Profile: Photo chargée depuis API");
        }

        isLoading = false;
      });
    } catch (e) {
      print("DEBUG Profile: Erreur API: $e");
      setState(() => isLoading = false);
    }
  }

  String _buildInitials(String f, String l) {
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  bool get showWallet => userType != 'client';

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A5F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Color(0xFFFF5A5F),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Se déconnecter ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous devrez vous reconnecter pour accéder à votre compte',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final prefs = await SharedPreferences.getInstance();
                        final orderId = prefs.getInt('last_order_id');
                        await LogoutService.performLogout(
                          context,
                          orderId: orderId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFFF5A5F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${firstName.isEmpty ? '' : firstName} ${lastName.isEmpty ? '' : lastName}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header moderne avec photo
                SliverAppBar(
                  expandedHeight: 30.h,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00CCBC).withOpacity(0.1),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InfoPersoPage(),
                                    ),
                                  );
                                  // Recharger le profil après modification
                                  await _loadUser();
                                  await _fetchProfileFromApi();
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: avatarBytes == null
                                            ? LinearGradient(
                                                colors: [
                                                  const Color(0xFF00CCBC),
                                                  const Color(
                                                    0xFF00CCBC,
                                                  ).withOpacity(0.7),
                                                ],
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00CCBC,
                                            ).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: avatarBytes != null
                                          ? ClipOval(
                                              child: Image.memory(
                                                avatarBytes!,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF00CCBC),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Color(0xFF00CCBC),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                fullName.isEmpty ? 'Utilisateur' : fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (phoneNumber.isNotEmpty)
                                Text(
                                  phoneNumber,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Actions rapides
                        Row(
                          children: [
                            if (showWallet)
                              Expanded(
                                child: _buildQuickAction(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: 'Portefeuille',
                                  color: const Color(0xFF00CCBC),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WalletPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (showWallet) const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.edit_rounded,
                                label: 'Modifier profil',
                                color: const Color(0xFF4A90E2),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InfoPersoPage(),
                                    ),
                                  );
                                  await _loadUser();
                                  await _fetchProfileFromApi();
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Menu items
                        _buildMenuCard(
                          title: 'Préférences',
                          items: [
                            _buildMenuItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.language_rounded,
                              title: 'Langue',
                              trailing: 'Français',
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          title: 'Support',
                          items: [
                            _buildMenuItem(
                              icon: Icons.help_outline_rounded,
                              title: "Centre d'aide",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Nous contacter',
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          title: 'Informations',
                          items: [
                            _buildMenuItem(
                              icon: Icons.description_outlined,
                              title: "Conditions d'utilisation",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Confidentialité',
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bouton déconnexion
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _showLogoutDialog,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFFF5A5F),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Se déconnecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF5A5F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[300],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
