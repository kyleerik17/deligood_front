import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/core/session/logout_coordinator.dart';
import 'package:deligood/features/restaurant/screens/promotions_page.dart';
import 'package:deligood/features/restaurant/screens/restaurant_order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RestaurantProfilePage extends StatelessWidget {
  const RestaurantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.page,
        title: Row(
          children: [
            Image.asset('assets/images/deligood_mascot_logo.png', height: 30),
            const SizedBox(width: 8),
            Text('DeliGood', style: AppText.h3(color: AppColors.primary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            color: AppColors.primary,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          1.h,
          AppSpacing.page,
          3.h,
        ),
        children: [
          _ProfileHero(),
          SizedBox(height: AppSpacing.lg),
          const _StatsGrid(),
          SizedBox(height: AppSpacing.lg),
          _ManagementCard(),
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes recentes', style: AppText.h2()),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Tout voir',
                  style: AppText.label(color: AppColors.primary),
                ),
              ),
            ],
          ),
          _RecentOrderCard(
            icon: Icons.bakery_dining_outlined,
            title: 'Commande #DG-9284',
            subtitle: 'Aujourd hui, 14:45 • 3 articles',
            price: '42,50€',
            status: 'Livree',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RestaurantOrderDetailPage(),
              ),
            ),
          ),
          _RecentOrderCard(
            icon: Icons.restaurant_outlined,
            title: 'Commande #DG-9271',
            subtitle: 'Hier, 11:20 • 5 articles',
            price: '89,00€',
            status: 'Livree',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RestaurantOrderDetailPage(),
              ),
            ),
          ),
          _RecentOrderCard(
            icon: Icons.local_cafe_outlined,
            title: 'Commande #DG-9150',
            subtitle: '24 Oct, 09:15 • 1 article',
            price: '12,40€',
            status: 'Annulee',
            muted: true,
            onTap: () {},
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD4C5),
              borderRadius: AppSpacing.lgRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Optimisation boutique', style: AppText.h3()),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Votre etablissement est actuellement ferme. Activez les horaires automatiques pour ne manquer aucune commande matinale !',
                  style: AppText.body(),
                ),
                SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5B1705),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.pillRadius,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.4.h,
                    ),
                  ),
                  child: const Text('Configurer les horaires'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.2.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppSpacing.xlRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: AppShadows.card,
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: Color(0xFFD59A33),
                    child: Icon(Icons.grass_outlined, color: Color(0xFF173B20)),
                  ),
                ),
              ),
              Positioned(
                right: -1.w,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.greenDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'The Golden Grain\nBakery',
            textAlign: TextAlign.center,
            style: AppText.h1(),
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Artisanal Bakery & Patisserie', style: AppText.body()),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Tag('Pastries'),
              _Tag('Sourdough'),
              _Tag('Eco-Friendly'),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier le profil'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.pillRadius,
              ),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppSpacing.pillRadius,
      ),
      child: Text(label, style: AppText.bodySm(color: AppColors.textPrimary)),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 3.5.w,
      crossAxisSpacing: 3.5.w,
      childAspectRatio: 1.95,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _StatCard(label: 'TOTAL COMMANDES', value: '1,284'),
        _StatCard(label: 'NOTE MOYENNE', value: '4.9 ☆', dark: true),
        _StatCard(label: 'REPONSE', value: '12m', green: true),
        _StatCard(label: 'CROISSANCE', value: '+15%', green: true),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool green;
  final bool dark;

  const _StatCard({
    required this.label,
    required this.value,
    this.green = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.lgRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppText.bodySm(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.h3(
              color: green
                  ? AppColors.greenDark
                  : dark
                  ? AppColors.textPrimary
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppSpacing.lgRadius,
        border: Border.all(color: AppColors.outline.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GESTION',
                style: AppText.label(color: AppColors.textSecondary),
              ),
            ),
          ),
          _ManagementTile(
            icon: Icons.receipt_long_outlined,
            label: 'Historique Commandes',
            highlighted: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RestaurantOrderDetailPage(),
              ),
            ),
          ),
          _ManagementTile(
            icon: Icons.schedule_outlined,
            label: 'Horaires d ouverture',
            onTap: () {},
          ),
          _ManagementTile(
            icon: Icons.notifications_none_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _ManagementTile(
            icon: Icons.local_offer_outlined,
            label: 'Promotions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PromotionsPage()),
            ),
          ),
          _ManagementTile(
            icon: Icons.payments_outlined,
            label: 'Modes de paiement',
            onTap: () {},
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 2.w, 3.w, 3.w),
            child: FilledButton.icon(
              onPressed: () => LogoutCoordinator.logout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se deconnecter'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.error,
                minimumSize: Size.fromHeight(5.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.mdRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _ManagementTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: highlighted ? AppColors.green.withOpacity(0.9) : null,
      leading: Icon(
        icon,
        color: highlighted ? AppColors.greenDark : AppColors.textPrimary,
      ),
      title: Text(label, style: AppText.body(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String status;
  final VoidCallback onTap;
  final bool muted;

  const _RecentOrderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.lgRadius,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppSpacing.lgRadius,
            border: Border.all(color: AppColors.outline.withOpacity(0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppSpacing.mdRadius,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h4()),
                    Text(subtitle, style: AppText.bodySm()),
                    const SizedBox(height: 10),
                    Text(
                      price,
                      style: AppText.priceLg(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                decoration: BoxDecoration(
                  color: muted ? const Color(0xFFFFD8D8) : AppColors.green,
                  borderRadius: AppSpacing.pillRadius,
                ),
                child: Text(
                  status,
                  style: AppText.bodySm(
                    color: muted ? AppColors.error : AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
