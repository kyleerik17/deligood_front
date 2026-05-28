import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/restaurant/screens/create_menu_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class RestaurantSellPage extends StatelessWidget {
  const RestaurantSellPage({super.key});

  void _openCreateMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateMenuPage(userRole: 'restaurant'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                3.h,
                AppSpacing.page,
                4.h,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                        'Bonjour, Chef !',
                        style: AppText.h2(color: AppColors.primary),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06, end: 0),
                  SizedBox(height: 0.8.h),
                  Text(
                    'Pret a partager vos delices avec votre quartier ?',
                    style: AppText.body(),
                  ),
                  SizedBox(height: 3.h),
                  _PrimaryActionCard(onTap: () => _openCreateMenu(context)),
                  SizedBox(height: 2.h),
                  const _StatsCard(),
                  SizedBox(height: 5.h),
                  _SectionHeader(
                    title: 'Mes ventes',
                    action: 'Tout voir',
                    onTap: () {},
                  ),
                  SizedBox(height: 1.6.h),
                  const _SaleTile(
                    imageAsset: 'assets/images/n.png',
                    title: 'Salade de Saison',
                    subtitle: '3 commandes en cours',
                    price: '45,00€',
                    status: 'En preparation',
                    active: true,
                  ),
                  SizedBox(height: 1.6.h),
                  const _SaleTile(
                    imageAsset: 'assets/images/onboarding_burger.png',
                    title: 'Burger Artisanal',
                    subtitle: 'Derniere vente il y a 2h',
                    price: '12,50€',
                    status: 'Termine',
                    active: false,
                  ),
                  SizedBox(height: 5.h),
                  const _HowItWorksCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
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
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: AppSpacing.smRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/deligood_mascot_logo.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          SizedBox(width: 3.w),
          Text('DeliGood', style: AppText.h3(color: AppColors.primary)),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            color: AppColors.primary,
          ),
          Container(
            width: 9.w,
            height: 9.w,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'JD',
              style: AppText.bodySm(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 18.h,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: AppSpacing.lgRadius,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.white,
                  size: 44,
                ),
                const Spacer(),
                Container(
                  width: 11.w,
                  height: 11.w,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un produit',
                  style: AppText.h2(color: AppColors.white),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  'Publiez une nouvelle recette ou un produit frais',
                  style: AppText.label(color: AppColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
          height: 18.h,
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withOpacity(0.58),
            borderRadius: AppSpacing.lgRadius,
            border: Border.all(color: AppColors.outline.withOpacity(0.46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppColors.primary),
                  const Spacer(),
                  Text(
                    '+12% cette semaine',
                    style: AppText.bodySm(
                      color: AppColors.greenDark,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '482€',
                    style: AppText.display(color: AppColors.primary),
                  ),
                  Text(
                    'Statistiques',
                    style: AppText.h2(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: 80.ms)
        .slideY(begin: 0.05, end: 0);
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
    return Row(
      children: [
        Text(title, style: AppText.h2()),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: AppText.bodySm(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String price;
  final String status;
  final bool active;

  const _SaleTile({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = active
        ? AppColors.greenDark
        : AppColors.textSecondary.withOpacity(0.55);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.lgRadius,
        border: Border.all(color: AppColors.outline.withOpacity(0.62)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppSpacing.smRadius,
            child: Image.asset(
              imageAsset,
              width: 16.w,
              height: 16.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label().copyWith(fontSize: 12.5.sp)),
                SizedBox(height: 0.4.h),
                Text(subtitle, style: AppText.bodySm()),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: AppText.h3(color: priceColor)),
              SizedBox(height: 0.8.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.w,
                  vertical: 0.35.h,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.green.withOpacity(0.34)
                      : Colors.transparent,
                  borderRadius: AppSpacing.pillRadius,
                ),
                child: Text(
                  status,
                  style: AppText.bodySm(
                    color: active
                        ? AppColors.greenDark
                        : AppColors.textSecondary,
                  ).copyWith(fontSize: 8.5.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: AppSpacing.xlRadius,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -11.w,
            bottom: -5.h,
            child: Opacity(
              opacity: 0.16,
              child: Transform.rotate(
                angle: -0.2,
                child: Image.asset(
                  'assets/images/deligood_mascot_logo.png',
                  width: 50.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vendre sur DeliGood,\ncomment ca marche ?',
                style: AppText.h2(color: AppColors.textPrimary),
              ),
              SizedBox(height: 2.4.h),
              const _StepLine(
                number: '1',
                title: 'Cuisinez & Photographiez',
                body:
                    'Preparez vos meilleurs plats et prenez une photo lumineuse pour donner envie.',
              ),
              const _StepLine(
                number: '2',
                title: 'Fixez votre prix',
                body:
                    'Vous gardez le controle total sur vos marges. DeliGood ne prend qu\'une petite commission fixe.',
              ),
              const _StepLine(
                number: '3',
                title: 'Livraison ou Retrait',
                body:
                    'Choisissez vos options preferees : retrait sur place ou via nos coursiers.',
              ),
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B2800),
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 1.7.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.pillRadius,
                  ),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(
                  'En savoir plus',
                  style: AppText.label(color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}

class _StepLine extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _StepLine({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number, style: AppText.label()),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label()),
                SizedBox(height: 0.45.h),
                Text(
                  body,
                  style: AppText.body(
                    color: AppColors.textPrimary.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
