import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class OrderRatingPage extends StatefulWidget {
  final int orderId;

  const OrderRatingPage({super.key, required this.orderId});

  @override
  State<OrderRatingPage> createState() => _OrderRatingPageState();
}

class _OrderRatingPageState extends State<OrderRatingPage> {
  int _foodRating = 0;
  int _serviceRating = 0;
  bool _sending = false;
  final _noteCtrl = TextEditingController();
  final Set<String> _tags = {};

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_foodRating == 0 && _serviceRating == 0) return;
    setState(() => _sending = true);
    try {
      final average = ((_foodRating + _serviceRating) / 2).round().clamp(1, 5);
      final tagText = _tags.isEmpty ? '' : ' (${_tags.join(', ')})';
      await ApiService.submitReview(
        orderId: widget.orderId,
        rating: average,
        comment: '${_noteCtrl.text.trim()}$tagText'.trim(),
      );
      if (!mounted) return;
      Navigator.maybePop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d envoyer la note pour le moment.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close, color: AppColors.primary),
        ),
        title: Text('DeliGood', style: AppText.h2(color: AppColors.primary)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.page),
            child: CircleAvatar(
              backgroundColor: AppColors.orangeSoft,
              child: Image.asset(
                'assets/images/deligood_mascot_logo.png',
                height: 26,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          4.h,
          AppSpacing.page,
          3.h,
        ),
        children: [
          Text(
            'How was your delivery?',
            textAlign: TextAlign.center,
            style: AppText.h1(),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Your feedback helps us make DeliGood better for everyone.',
            textAlign: TextAlign.center,
            style: AppText.bodyLg(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),
          _RatingCard(
            image: Image.asset(
              'assets/images/onboarding_burger.png',
              fit: BoxFit.cover,
            ),
            title: 'The Burger Joint',
            subtitle: 'Classic Cheeseburger & Fries',
            prompt: 'Rate the Food',
            value: _foodRating,
            onChanged: (value) => setState(() => _foodRating = value),
          ),
          SizedBox(height: AppSpacing.lg),
          _RatingCard(
            image: const Icon(Icons.person, size: 34, color: AppColors.white),
            avatarColor: AppColors.green,
            title: 'Alex delivered your order',
            subtitle: 'Arrived 5 mins early',
            prompt: 'Rate the Service',
            value: _serviceRating,
            onChanged: (value) => setState(() => _serviceRating = value),
          ),
          SizedBox(height: AppSpacing.xl),
          Text('Add a note (Optional)', style: AppText.h3()),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteCtrl,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Tell us what you liked or what we can improve...',
              fillColor: Color(0xFFF0F0EF),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Fast Delivery',
                      'Great Packaging',
                      'Still Hot',
                      'Friendly Driver',
                    ]
                    .map(
                      (tag) => FilterChip(
                        label: Text(tag),
                        selected: _tags.contains(tag),
                        selectedColor: AppColors.orangeSoft,
                        checkmarkColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.outline,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.pillRadius,
                        ),
                        onSelected: (selected) {
                          setState(
                            () => selected ? _tags.add(tag) : _tags.remove(tag),
                          );
                        },
                      ),
                    )
                    .toList(),
          ),
          SizedBox(height: 6.h),
          FilledButton(
            onPressed: _sending ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              minimumSize: Size.fromHeight(7.h),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.mdRadius),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Feedback'),
          ),
          SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              text: 'By submitting, you agree to our ',
              children: [
                TextSpan(
                  text: 'Feedback Policy',
                  style: AppText.body(
                    color: AppColors.primary,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppText.body(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final Widget image;
  final Color? avatarColor;
  final String title;
  final String subtitle;
  final String prompt;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.value,
    required this.onChanged,
    this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.lgRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: avatarColor ?? AppColors.surfaceContainer,
                  shape: avatarColor == null
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius: avatarColor == null
                      ? AppSpacing.mdRadius
                      : null,
                  border: avatarColor == null
                      ? null
                      : Border.all(color: AppColors.green, width: 2),
                ),
                child: image,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h2()),
                    Text(
                      subtitle,
                      style: AppText.body(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Text(prompt, style: AppText.h3()),
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => onChanged(star),
                iconSize: 38,
                color: AppColors.gold,
                icon: Icon(star <= value ? Icons.star : Icons.star_border),
              );
            }),
          ),
        ],
      ),
    );
  }
}
