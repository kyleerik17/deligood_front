import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:deligood/features/client/screens/RestaurantPage.dart';
import 'package:deligood/features/orders/screens/cart_page.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class ClientHomePage extends StatefulWidget {
  final int orderId;

  const ClientHomePage({super.key, required this.orderId});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final _search = TextEditingController();
  int _category = 0;

  final _categories = const [
    ('Populaire', Icons.auto_awesome_rounded),
    ('Burgers', Icons.lunch_dining_rounded),
    ('Africain', Icons.rice_bowl_rounded),
    ('Pizza', Icons.local_pizza_rounded),
    ('Healthy', Icons.eco_rounded),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openRestaurants() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RestaurantPage()));
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumTopBar(
                  eyebrow: 'Livraison premium',
                  title: 'Que voulez-vous\nmanger aujourd’hui ?',
                  subtitle:
                      'Restaurants sélectionnés, suivi clair, paiement sécurisé.',
                  actionIcon: Icons.notifications_none_rounded,
                ),
                SizedBox(height: 2.h),
                PremiumSearchField(
                  controller: _search,
                  hint: 'Rechercher un plat, un restaurant...',
                  onFilterTap: _openRestaurants,
                ),
                SizedBox(height: 2.4.h),
                _HeroOrderCard(
                  hasOrder: widget.orderId > 0,
                  onTrack: widget.orderId > 0
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(orderId: widget.orderId),
                          ),
                        )
                      : _openRestaurants,
                ),
                SizedBox(height: 2.8.h),
                _SectionHeader(
                  title: 'Catégories',
                  action: 'Voir tout',
                  onTap: _openRestaurants,
                ),
                SizedBox(height: 1.4.h),
                SizedBox(
                  height: 5.3.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) => PremiumChip(
                      label: _categories[i].$1,
                      icon: _categories[i].$2,
                      selected: i == _category,
                      onTap: () => setState(() => _category = i),
                    ),
                    separatorBuilder: (_, __) => SizedBox(width: 2.6.w),
                    itemCount: _categories.length,
                  ),
                ),
                SizedBox(height: 2.8.h),
                _SectionHeader(
                  title: 'Sélection du jour',
                  action: 'Restaurants',
                  onTap: _openRestaurants,
                ),
                SizedBox(height: 1.4.h),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverList.separated(
              itemBuilder: (context, index) =>
                  _FoodDealCard(
                        index: index,
                        onAdd: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PanierPage()),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 360.ms, delay: (80 * index).ms)
                      .slideY(
                        begin: .08,
                        end: 0,
                        duration: 360.ms,
                        curve: Curves.easeOutCubic,
                      ),
              separatorBuilder: (_, __) => SizedBox(height: 1.6.h),
              itemCount: 3,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 3.h)),
        ],
      ),
    );
  }
}

class _HeroOrderCard extends StatelessWidget {
  final bool hasOrder;
  final VoidCallback onTrack;

  const _HeroOrderCard({required this.hasOrder, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: AppColors.gradientDark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumBadge(
                  label: hasOrder ? 'Commande active' : 'Express 25 min',
                  icon: hasOrder ? Icons.bolt_rounded : Icons.timer_rounded,
                  color: AppColors.green,
                ),
                SizedBox(height: 1.5.h),
                Text(
                  hasOrder
                      ? 'Suivez votre livraison en temps réel'
                      : 'Les meilleurs restos autour de vous',
                  style: AppText.h2(color: AppColors.white),
                ),
                SizedBox(height: .8.h),
                Text(
                  hasOrder
                      ? 'Livreur, restaurant et ETA réunis dans une vue live.'
                      : 'Des cartes élégantes, des plats immersifs et un checkout fluide.',
                  style: AppText.bodySm(
                    color: AppColors.white.withValues(alpha: .72),
                  ),
                ),
                SizedBox(height: 1.7.h),
                ElevatedButton(
                  onPressed: onTrack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.2.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.pillRadius,
                    ),
                  ),
                  child: Text(hasOrder ? 'Voir le suivi' : 'Explorer'),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/images/onboarding_burger.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodDealCard extends StatelessWidget {
  final int index;
  final VoidCallback onAdd;

  const _FoodDealCard({required this.index, required this.onAdd});

  static const _data = [
    (
      'Signature Burger',
      'Pain brioche, cheddar affiné, sauce maison',
      '4 500 FCFA',
      '4.9',
      '18-25 min',
      'assets/images/onboarding_burger.png',
    ),
    (
      'Salade Green Luxe',
      'Avocat, poulet grillé, vinaigrette premium',
      '3 800 FCFA',
      '4.8',
      '15-22 min',
      'assets/images/n.png',
    ),
    (
      'Deli Bowl Ivoire',
      'Riz parfumé, légumes croquants, poulet braisé',
      '5 200 FCFA',
      '4.7',
      '20-30 min',
      'assets/images/onboarding_burger.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = _data[index % _data.length];
    return PremiumCard(
      padding: EdgeInsets.all(3.w),
      onTap: onAdd,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 25.w,
              height: 25.w,
              color: AppColors.surfaceWarm,
              child: Image.asset(item.$6, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: AppText.h3()),
                SizedBox(height: .5.h),
                Text(
                  item.$2,
                  style: AppText.bodySm(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    SizedBox(width: 1.w),
                    Text(item.$4, style: AppText.label()),
                    SizedBox(width: 3.w),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 1.w),
                    Text(item.$5, style: AppText.bodySm()),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Text(item.$3, style: AppText.priceLg()),
                    const Spacer(),
                    Container(
                      width: 9.5.w,
                      height: 9.5.w,
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradientOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Row(
        children: [
          Text(title, style: AppText.h3()),
          const Spacer(),
          TextButton(
            onPressed: onTap,
            child: Text(action, style: AppText.label(color: AppColors.orange)),
          ),
        ],
      ),
    );
  }
}
