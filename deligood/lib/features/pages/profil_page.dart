import 'dart:convert';
import 'dart:typed_data';

import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/auth/widgets/logout.dart';
import 'package:deligood/features/pages/info_perso.dart';
import 'package:deligood/features/pages/wallet_page.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

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

  Future<void> _fetchProfileFromApi() async {
    try {
      final data = await ProfileApi.fetchProfile();
      if (!mounted) return;

      setState(() {
        firstName = data['first_name']?.toString() ?? '';
        lastName = data['last_name']?.toString() ?? '';
        phoneNumber = data['phone_number']?.toString() ?? '';
        userType = data['user_type']?.toString() ?? '';
        initials = _buildInitials(firstName, lastName);
        if (data['avatar_base64'] != null) {
          avatarBytes = ProfileApi.decodeAvatar(data['avatar_base64']);
        }
      });
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }

  String _buildInitials(String f, String l) {
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  bool get showWallet => userType.toLowerCase() != 'client';

  @override
  Widget build(BuildContext context) {
    final fullName = '$firstName $lastName'.trim();
    final role = userType.isEmpty ? 'Compte DeliGood' : userType.toUpperCase();

    return PremiumScaffold(
      child: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: _fetchProfileFromApi,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            1.4.h,
            AppSpacing.page,
            13.h,
          ),
          children: [
            PremiumTopBar(
              eyebrow: 'Compte',
              title: 'Profil',
              subtitle: 'Vos informations et preferences DeliGood.',
              actionIcon: Icons.refresh_rounded,
              onAction: _fetchProfileFromApi,
            ),
            SizedBox(height: 2.h),
            PremiumCard(
              padding: EdgeInsets.all(5.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 9.w,
                    backgroundColor: AppColors.orangeSoft,
                    backgroundImage: avatarBytes != null
                        ? MemoryImage(avatarBytes!)
                        : null,
                    child: avatarBytes == null
                        ? Text(
                            initials,
                            style: AppText.h2(color: AppColors.orange),
                          )
                        : null,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Utilisateur DeliGood' : fullName,
                          style: AppText.h3(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: .6.h),
                        Text(
                          phoneNumber.isEmpty
                              ? 'Telephone non renseigne'
                              : phoneNumber,
                          style: AppText.bodySm(),
                        ),
                        SizedBox(height: 1.h),
                        PremiumBadge(
                          label: role,
                          icon: Icons.verified_user_rounded,
                          color: AppColors.greenDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            _ProfileAction(
              icon: Icons.person_rounded,
              title: 'Modifier le profil',
              subtitle: 'Nom, telephone, documents et photo',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoPersoPage()),
                );
                await _fetchProfileFromApi();
              },
            ),
            if (showWallet)
              _ProfileAction(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Mon solde',
                subtitle: 'Revenus, retraits et historique',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletPage()),
                  );
                },
              ),
            _ProfileAction(
              icon: Icons.policy_rounded,
              title: "Conditions d'utilisation",
              subtitle: 'Regles de service et responsabilites',
              onTap: () {},
            ),
            _ProfileAction(
              icon: Icons.privacy_tip_rounded,
              title: 'Confidentialite',
              subtitle: 'Donnees personnelles et securite',
              onTap: () {},
            ),
            _ProfileAction(
              icon: Icons.support_agent_rounded,
              title: 'Nous contacter',
              subtitle: 'Support client et assistance',
              onTap: () {},
            ),
            _ProfileAction(
              icon: Icons.logout_rounded,
              title: 'Deconnexion',
              subtitle: 'Fermer la session sur cet appareil',
              danger: true,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final orderId = prefs.getInt('last_order_id');
                await LogoutService.performLogout(context, orderId: orderId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.orange;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: PremiumCard(
        padding: EdgeInsets.all(4.w),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: AppSpacing.mdRadius,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 3.4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h4()),
                  SizedBox(height: .4.h),
                  Text(
                    subtitle,
                    style: AppText.bodySm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
