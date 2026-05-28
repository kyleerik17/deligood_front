import 'package:deligood/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.page,
        title: Row(
          children: [
            Image.asset('assets/images/deligood_mascot_logo.png', height: 30),
            const SizedBox(width: 10),
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
          3.h,
          AppSpacing.page,
          4.h,
        ),
        children: [
          Text('Gestion des Promotions', style: AppText.h1()),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Optimisez vos ventes en creant des offres attractives pour vos clients.',
            style: AppText.bodyLg(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.textPrimary,
            ),
            label: Text(
              'Creer une nouvelle\npromotion',
              textAlign: TextAlign.center,
              style: AppText.h3(color: AppColors.textPrimary),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textPrimary,
              minimumSize: Size.fromHeight(13.h),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.lgRadius),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  color: AppColors.green,
                  icon: Icons.trending_up,
                  label: 'Promotions actives',
                  value: '04',
                  greenText: true,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: _MetricCard(
                  color: AppColors.surfaceContainer,
                  icon: Icons.groups_outlined,
                  label: 'Utilisations totales',
                  value: '1,284',
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VOS OFFRES EN COURS',
                style: AppText.label(color: AppColors.textSecondary),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
            ],
          ),
          const _PromotionCard(
            icon: Icons.percent,
            title: '-20% sur le dejeuner',
            subtitle: 'Menu Midi & Formules',
            type: 'Remise %',
            duration: 'Permanent',
            used: '842 fois',
            active: true,
          ),
          const _PromotionCard(
            icon: Icons.local_shipping_outlined,
            title: 'Livraison offerte',
            subtitle: 'Des 30€ d achat',
            type: 'Service',
            duration: 'Week-end',
            used: '315 fois',
            active: true,
            softGreen: true,
          ),
          const _PromotionCard(
            icon: Icons.celebration_outlined,
            title: 'Happy Hour -50%',
            subtitle: 'Sur toutes les boissons',
            type: 'Boissons',
            duration: 'Terminee',
            used: '127 fois',
            active: false,
          ),
          SizedBox(height: AppSpacing.xl),
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDFA5),
              borderRadius: AppSpacing.lgRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 8),
                    Text('Astuce Pro', style: AppText.h2()),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Les promotions de type "Livraison offerte" augmentent le panier moyen de 15% pendant le week-end.',
                  style: AppText.bodyLg(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final bool greenText;

  const _MetricCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.greenText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15.h,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: greenText ? AppColors.greenDark : AppColors.primary,
          ),
          Text(label, style: AppText.bodySm(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppText.h2(
              color: greenText ? AppColors.greenDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String type;
  final String duration;
  final String used;
  final bool active;
  final bool softGreen;

  const _PromotionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.duration,
    required this.used,
    required this.active,
    this.softGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = !active;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFE1DDDA) : AppColors.white,
        borderRadius: AppSpacing.lgRadius,
        boxShadow: muted ? null : AppShadows.subtle,
      ),
      child: Opacity(
        opacity: muted ? 0.62 : 1,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: softGreen
                        ? const Color(0xFFE5F3EC)
                        : AppColors.surfaceContainer,
                    borderRadius: AppSpacing.mdRadius,
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.h3()),
                      Text(subtitle, style: AppText.bodySm()),
                    ],
                  ),
                ),
                Switch(
                  value: active,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.greenDark,
                ),
              ],
            ),
            Divider(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PromoMeta(label: 'Type', value: type),
                _PromoMeta(label: 'Duree', value: duration),
                _PromoMeta(label: 'Utilisee', value: used),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoMeta extends StatelessWidget {
  final String label;
  final String value;

  const _PromoMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppText.bodySm()),
        Text(value, style: AppText.label()),
      ],
    );
  }
}
