import 'package:deligood/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class RestaurantDashboardPage extends StatelessWidget {
  const RestaurantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: const _DashboardHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                2.5.h,
                AppSpacing.page,
                4.h,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Bonjour, La Trattoria',
                    style: AppText.h2(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 0.6.h),
                  Text(
                    'Votre restaurant est ouvert et recoit des commandes.',
                    style: AppText.body(),
                  ),
                  SizedBox(height: 2.8.h),
                  const _RevenueCard(),
                  SizedBox(height: 2.h),
                  const _OrdersMetricCard(),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Text('Commandes actives', style: AppText.h3()),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w,
                          vertical: 0.45.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.5),
                          borderRadius: AppSpacing.pillRadius,
                        ),
                        child: Text(
                          '5 EN COURS',
                          style: AppText.bodySm(color: AppColors.greenDark)
                              .copyWith(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  const _ActiveOrderCard(
                    id: '#DG-8821',
                    client: 'Jean D.',
                    items: '2x Pizza Margherita, 1x Coca Zero',
                    time: 'Il y a 8 mins',
                    status: 'A PREPARER',
                    primaryAction: 'PRET',
                    accent: AppColors.orange,
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  SizedBox(height: 1.4.h),
                  const _ActiveOrderCard(
                    id: '#DG-8819',
                    client: 'Sarah L.',
                    items: '1x Risotto aux Truffes, 1x Tiramisu',
                    time: 'Il y a 14 mins',
                    status: 'CONFIRMEE',
                    primaryAction: 'VOIR',
                    accent: AppColors.greenDark,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  SizedBox(height: 2.4.h),
                  const _AlertsPanel(),
                  SizedBox(height: 2.4.h),
                  const _MenuManagementPanel(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppSpacing.lgRadius,
        border: Border.all(color: AppColors.outline.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DERNIERES ALERTES',
            style: AppText.label(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.md),
          const _AlertTile(
            icon: Icons.warning_amber_outlined,
            title: 'Rupture de stock',
            body: 'L article "Pesto Rosso" est epuise.',
          ),
          const SizedBox(height: 10),
          const _AlertTile(
            icon: Icons.star_border,
            title: 'Nouvel avis 5 etoiles',
            body: '"Toujours aussi delicieux !" - Marc',
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AlertTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.mdRadius,
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label()),
                Text(body, style: AppText.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuManagementPanel extends StatelessWidget {
  const _MenuManagementPanel();

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
        children: [
          Row(
            children: [
              Text('GESTION MENU', style: AppText.label()),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'VOIR TOUT',
                  style: AppText.label(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const _MenuRow(
            imageUrl:
                'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=200',
            title: 'Margherita Special',
            enabled: true,
          ),
          const _MenuRow(
            imageUrl:
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
            title: 'Salade Cesar',
            enabled: false,
          ),
          SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un plat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: Size.fromHeight(5.6.h),
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.35),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.smRadius),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool enabled;

  const _MenuRow({
    required this.imageUrl,
    required this.title,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Container(
            width: 11.w,
            height: 11.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: AppSpacing.smRadius),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceContainer,
                child: const Icon(Icons.restaurant, color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(child: Text(title, style: AppText.bodyLg())),
          Switch(
            value: enabled,
            onChanged: (_) {},
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.greenDark,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9.5.w,
            height: 9.5.w,
            decoration: const BoxDecoration(
              color: AppColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/deligood_mascot_logo.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          SizedBox(width: 2.6.w),
          Text('DeliGood', style: AppText.h3(color: AppColors.primary)),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.textSecondary,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withOpacity(0.38),
        borderRadius: AppSpacing.lgRadius,
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VENTES DU JOUR',
            style: AppText.bodySm().copyWith(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 1.h),
          Text('1248,50 €', style: AppText.display(color: AppColors.primary)),
          SizedBox(height: 1.2.h),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.greenDark,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                '+12%',
                style: AppText.bodySm(
                  color: AppColors.greenDark,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 2.w),
              Text('par rapport a hier', style: AppText.bodySm()),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0);
  }
}

class _OrdersMetricCard extends StatelessWidget {
  const _OrdersMetricCard();

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: const Color(0xFF332D28),
            borderRadius: AppSpacing.lgRadius,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMANDES',
                style: AppText.bodySm(
                  color: AppColors.white.withOpacity(0.66),
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 1.h),
              Text('42', style: AppText.display(color: AppColors.white)),
              SizedBox(height: 1.8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.1.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.11),
                  borderRadius: AppSpacing.smRadius,
                ),
                child: Row(
                  children: [
                    Text(
                      'Panier moyen',
                      style: AppText.bodySm(
                        color: AppColors.white.withOpacity(0.62),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '29,70 €',
                      style: AppText.label(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, delay: 80.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final String id;
  final String client;
  final String items;
  final String time;
  final String status;
  final String primaryAction;
  final Color accent;
  final IconData icon;

  const _ActiveOrderCard({
    required this.id,
    required this.client,
    required this.items,
    required this.time,
    required this.status,
    required this.primaryAction,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.72),
        borderRadius: AppSpacing.mdRadius,
        border: Border.all(color: AppColors.outline.withOpacity(0.38)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.11),
              borderRadius: AppSpacing.smRadius,
            ),
            child: Icon(icon, color: accent),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppText.label(),
                    children: [
                      TextSpan(text: '$id '),
                      TextSpan(
                        text: '• $client',
                        style: AppText.bodySm(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  items,
                  style: AppText.bodySm(color: AppColors.textPrimary),
                ),
                Text(time, style: AppText.bodySm()),
                SizedBox(height: 1.2.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.13),
                        borderRadius: AppSpacing.smRadius,
                      ),
                      child: Text(
                        status,
                        style: AppText.bodySm(color: accent).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5.sp,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 0.9.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.smRadius,
                        ),
                      ),
                      child: Text(
                        primaryAction,
                        style: AppText.bodySm(
                          color: AppColors.white,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
