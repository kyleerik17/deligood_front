import 'package:deligood/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            2.h,
            AppSpacing.page,
            4.h,
          ),
          child: Column(
            children: [
              _Header(),
              SizedBox(height: 4.h),
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.34),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.28),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.greenDark,
                  size: 66,
                ),
              ).animate().scale(
                begin: const Offset(0.74, 0.74),
                duration: 420.ms,
                curve: Curves.easeOutBack,
              ),
              SizedBox(height: 4.h),
              Text(
                'Bienvenue dans la famille\nDeliGood !',
                textAlign: TextAlign.center,
                style: AppText.h2(),
              ),
              SizedBox(height: 2.h),
              Text(
                'Votre compte a ete cree avec succes. Vous pouvez maintenant commencer votre aventure.',
                textAlign: TextAlign.center,
                style: AppText.body(),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                height: 6.4.h,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text("C'est parti !", style: AppText.button()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.mdRadius,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: const [
                  Expanded(
                    child: _FeatureChip(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Restaurants',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _FeatureChip(
                      icon: Icons.delivery_dining_rounded,
                      title: 'Livraison Rapide',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.6.h),
              Row(
                children: const [
                  Expanded(
                    child: _FeatureChip(
                      icon: Icons.local_offer_outlined,
                      title: 'Bons Plans',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _FeatureChip(
                      icon: Icons.eco_outlined,
                      title: 'Eco-responsable',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: AppSpacing.lgRadius,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Image.asset(
                      'assets/images/onboarding_burger.png',
                      width: double.infinity,
                      height: 18.h,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.62),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        'Decouvrez les pepites de\nvotre quartier',
                        style: AppText.h3(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9.w,
          height: 9.w,
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
        SizedBox(width: 2.w),
        Text('DeliGood', style: AppText.h3(color: AppColors.primary)),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.shopping_cart_outlined),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureChip({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.78),
        borderRadius: AppSpacing.mdRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(height: 0.8.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.bodySm(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
