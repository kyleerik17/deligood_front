import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = const [
      _NotificationItem(
        icon: Icons.delivery_dining_rounded,
        title: 'Livreur assigné',
        message: 'Koffi récupère votre commande dans 6 minutes.',
        time: 'Maintenant',
        color: AppColors.greenDark,
      ),
      _NotificationItem(
        icon: Icons.local_offer_rounded,
        title: 'Offre premium',
        message: '-20% sur les restaurants tendance ce soir.',
        time: '12 min',
        color: AppColors.orange,
      ),
      _NotificationItem(
        icon: Icons.receipt_long_rounded,
        title: 'Paiement confirmé',
        message: 'Votre transaction Mobile Money est validée.',
        time: 'Hier',
        color: AppColors.gold,
      ),
    ];

    return PremiumScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumTopBar(
              eyebrow: 'Centre d’activité',
              title: 'Notifications',
              subtitle: 'Tout ce qui mérite votre attention, sans bruit.',
              actionIcon: Icons.done_all_rounded,
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              2.h,
              AppSpacing.page,
              3.h,
            ),
            sliver: SliverList.separated(
              itemBuilder: (_, i) => _NotificationCard(item: notifications[i])
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (70 * i).ms)
                  .slideX(begin: .05, end: 0),
              separatorBuilder: (_, __) => SizedBox(height: 1.3.h),
              itemCount: notifications.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.title, style: AppText.h3())),
                    Text(
                      item.time,
                      style: AppText.bodySm(color: AppColors.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: .5.h),
                Text(item.message, style: AppText.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
