import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumTopBar(
              eyebrow: 'DeliGood Control',
              title: 'Dashboard admin',
              subtitle:
                  'Vue globale temps réel des clients, restaurants et livreurs.',
              actionIcon: Icons.admin_panel_settings_rounded,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              2.4.h,
              AppSpacing.page,
              3.h,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: const [
                    Expanded(
                      child: _AdminMetric(
                        label: 'GMV',
                        value: '2.4M',
                        icon: Icons.payments_rounded,
                        color: AppColors.orange,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AdminMetric(
                        label: 'Commandes',
                        value: '1 248',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: .05, end: 0),
                SizedBox(height: 1.4.h),
                Row(
                  children: const [
                    Expanded(
                      child: _AdminMetric(
                        label: 'Restaurants',
                        value: '186',
                        icon: Icons.storefront_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AdminMetric(
                        label: 'Livreurs',
                        value: '92',
                        icon: Icons.delivery_dining_rounded,
                        color: Color(0xFF3563FF),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 80.ms).slideY(begin: .05, end: 0),
                SizedBox(height: 2.4.h),
                Text('Opérations live', style: AppText.h3()),
                SizedBox(height: 1.2.h),
                const _OpsCard(),
                SizedBox(height: 2.4.h),
                Text('Actions rapides', style: AppText.h3()),
                SizedBox(height: 1.2.h),
                const _ActionGrid(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 1.6.h),
          Text(value, style: AppText.h2()),
          SizedBox(height: .3.h),
          Text(label, style: AppText.bodySm()),
        ],
      ),
    );
  }
}

class _OpsCard extends StatelessWidget {
  const _OpsCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.all(4.5.w),
      child: Column(
        children: const [
          _OpsRow(
            label: 'Commandes en préparation',
            value: '38',
            color: AppColors.orange,
          ),
          _OpsRow(
            label: 'Livraisons en cours',
            value: '24',
            color: AppColors.greenDark,
          ),
          _OpsRow(
            label: 'Tickets support ouverts',
            value: '7',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _OpsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OpsRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 3.w),
          Expanded(child: Text(label, style: AppText.bodyLg())),
          Text(value, style: AppText.h3(color: color)),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Valider resto', Icons.verified_rounded),
      ('Assigner livreur', Icons.route_rounded),
      ('Promotions', Icons.campaign_rounded),
      ('Analytics', Icons.insights_rounded),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 1.5.h,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) => PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(items[i].$2, color: AppColors.orange),
            SizedBox(height: 1.h),
            Text(items[i].$1, style: AppText.label()),
          ],
        ),
      ),
    );
  }
}
