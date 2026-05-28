import 'package:deligood/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PremiumScaffold extends StatelessWidget {
  final Widget child;
  final bool addSafeArea;
  final EdgeInsetsGeometry? padding;

  const PremiumScaffold({
    super.key,
    required this.child,
    this.addSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        const _PremiumBackground(),
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: addSafeArea ? SafeArea(child: content) : content,
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceWarm, AppColors.surface],
        ),
      ),
    );
  }
}

class PremiumTopBar extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const PremiumTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actionIcon = Icons.notifications_none_rounded,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, 1.4.h, AppSpacing.page, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppText.label(
                    color: AppColors.textSecondary.withValues(alpha: 0.78),
                  ),
                ),
                SizedBox(height: .4.h),
                Text(title, style: AppText.h1()),
                if (subtitle != null) ...[
                  SizedBox(height: .5.h),
                  Text(subtitle!, style: AppText.bodySm()),
                ],
              ],
            ),
          ),
          PremiumIconButton(icon: actionIcon, onTap: onAction),
        ],
      ),
    );
  }
}

class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const PremiumIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.9),
      borderRadius: AppSpacing.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.pillRadius,
        child: Container(
          width: 11.5.w,
          height: 11.5.w,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.pillRadius,
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.28),
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class PremiumSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const PremiumSearchField({
    super.key,
    required this.controller,
    this.hint = 'Rechercher plats, restos...',
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: EdgeInsets.symmetric(horizontal: 3.2.w, vertical: .6.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.xlRadius,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.22)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft.withValues(alpha: .65),
              borderRadius: AppSpacing.pillRadius,
            ),
            child: const Icon(Icons.search_rounded, color: AppColors.orange),
          ),
          SizedBox(width: 2.6.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.bodyLg(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppText.body(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (onFilterTap != null)
            InkWell(
              onTap: onFilterTap,
              borderRadius: AppSpacing.pillRadius,
              child: Container(
                padding: EdgeInsets.all(2.4.w),
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: selected ? AppColors.white : AppColors.textPrimary,
          ),
          SizedBox(width: 1.5.w),
        ],
        Text(
          label,
          style: AppText.label(
            color: selected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: 4.2.w, vertical: 1.15.h),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradientOrange : null,
          color: selected ? null : AppColors.white,
          borderRadius: AppSpacing.pillRadius,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.outline.withValues(alpha: 0.24),
          ),
          boxShadow: selected ? AppShadows.orange : AppShadows.subtle,
        ),
        child: content,
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.xlRadius;
    final card = Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.18)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: card),
    );
  }
}

class PremiumBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const PremiumBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.greenDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.6.w, vertical: .75.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: AppSpacing.pillRadius,
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            SizedBox(width: 1.w),
          ],
          Text(label, style: AppText.bodySm(color: color)),
        ],
      ),
    );
  }
}
