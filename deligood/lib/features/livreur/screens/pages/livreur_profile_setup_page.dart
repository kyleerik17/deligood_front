import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/core/session/logout_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LivreurProfileSetupPage extends StatefulWidget {
  const LivreurProfileSetupPage({super.key});

  @override
  State<LivreurProfileSetupPage> createState() =>
      _LivreurProfileSetupPageState();
}

class _LivreurProfileSetupPageState extends State<LivreurProfileSetupPage> {
  String _vehicle = 'Velo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.page,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.orangeSoft,
              child: const Icon(
                Icons.delivery_dining,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('DeliGood', style: AppText.h3(color: AppColors.primary)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
          IconButton(
            tooltip: 'Se deconnecter',
            onPressed: () => LogoutCoordinator.logout(context),
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          2.h,
          AppSpacing.page,
          3.h,
        ),
        children: [
          Container(
            height: 32.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: AppSpacing.lgRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=900',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3A241C), Color(0xFFFF7A1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.white,
                      size: 72,
                    ),
                  ),
                ),
                Container(color: Colors.black.withOpacity(0.24)),
                Positioned(
                  left: 5.w,
                  right: 5.w,
                  bottom: 3.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 0.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: AppSpacing.pillRadius,
                        ),
                        child: Text(
                          'Nouveau Livreur',
                          style: AppText.label(color: AppColors.greenDark),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bienvenue chez\nDeliGood',
                        style: AppText.h1(color: AppColors.white),
                      ),
                      Text(
                        'Completez votre profil pour commencer vos premieres livraisons aujourd hui.',
                        style: AppText.body(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(
                child: _BenefitCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Validation Rapide',
                  value: '24h ouvrees',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _BenefitCard(
                  icon: Icons.payments_outlined,
                  title: 'Paiements Hebdo',
                  value: 'Sans frais',
                  green: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppSpacing.lgRadius,
              boxShadow: AppShadows.subtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  index: '1.',
                  title: 'Identite',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: AppSpacing.md),
                _FieldLabel('Nom complet'),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Ex: Jean Dupont',
                    fillColor: Color(0xFFF1F0EF),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _FieldLabel('Numero de telephone'),
                const TextField(
                  decoration: InputDecoration(
                    hintText: '+33 6 00 00 00 00',
                    fillColor: Color(0xFFF1F0EF),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                const _SectionTitle(
                  index: '2.',
                  title: 'Moyen de transport',
                  icon: Icons.pedal_bike,
                  green: true,
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _VehicleCard(
                      label: 'Velo',
                      icon: Icons.pedal_bike,
                      selected: _vehicle == 'Velo',
                      onTap: () => setState(() => _vehicle = 'Velo'),
                    ),
                    SizedBox(width: 3.w),
                    _VehicleCard(
                      label: 'Scooter',
                      icon: Icons.moped_outlined,
                      selected: _vehicle == 'Scooter',
                      onTap: () => setState(() => _vehicle = 'Scooter'),
                    ),
                    SizedBox(width: 3.w),
                    _VehicleCard(
                      label: 'Voiture',
                      icon: Icons.directions_car_outlined,
                      selected: _vehicle == 'Voiture',
                      onTap: () => setState(() => _vehicle = 'Voiture'),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),
                const _SectionTitle(
                  index: '3.',
                  title: 'Documents officiels',
                  icon: Icons.description_outlined,
                  gold: true,
                ),
                SizedBox(height: AppSpacing.md),
                const _UploadTile(
                  title: 'Piece d identite',
                  subtitle: 'Recto / Verso (JPEG, PNG, PDF)',
                  icon: Icons.badge_outlined,
                ),
                const _UploadTile(
                  title: 'Permis de conduire',
                  subtitle: 'Obligatoire pour les vehicules motorises',
                  icon: Icons.credit_card_outlined,
                ),
                const _UploadTile(
                  title: 'Attestation d assurance',
                  subtitle: 'Assurance professionnelle active',
                  icon: Icons.analytics_outlined,
                ),
                Divider(height: 4.h),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    minimumSize: Size.fromHeight(6.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.mdRadius,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Finaliser mon profil'),
                      SizedBox(width: 10),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'En cliquant sur "Finaliser", vous acceptez nos Conditions Generales de Livraison.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool green;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.value,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green ? AppColors.greenDark : AppColors.primary),
          SizedBox(height: AppSpacing.md),
          Text(title, style: AppText.body()),
          Text(value, style: AppText.label()),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String index;
  final String title;
  final IconData icon;
  final bool green;
  final bool gold;

  const _SectionTitle({
    required this.index,
    required this.title,
    required this.icon,
    this.green = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = green
        ? AppColors.green
        : gold
        ? AppColors.gold
        : AppColors.orangeSoft;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.22),
            borderRadius: AppSpacing.smRadius,
          ),
          child: Icon(
            icon,
            color: green
                ? AppColors.greenDark
                : gold
                ? AppColors.gold
                : AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text('$index $title', style: AppText.h2()),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(label, style: AppText.bodySm(color: AppColors.textPrimary)),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.mdRadius,
        child: Container(
          height: 11.h,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.orangeSoft.withOpacity(0.18)
                : AppColors.white,
            borderRadius: AppSpacing.mdRadius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(label, style: AppText.label(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppSpacing.smRadius,
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label()),
                Text(subtitle, style: AppText.bodySm()),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Charger'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
