import 'package:deligood/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RestaurantOrderDetailPage extends StatelessWidget {
  const RestaurantOrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande\n#DG-9284', style: AppText.h2()),
            Text('25 Oct 2024, 14:45', style: AppText.bodySm()),
          ],
        ),
        toolbarHeight: 86,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            color: AppColors.primary,
          ),
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
        padding: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 3.h),
        children: [
          _StatusCard(),
          SizedBox(height: AppSpacing.md),
          _RestaurantCard(),
          SizedBox(height: AppSpacing.xl),
          Text(
            'ARTICLES COMMANDES',
            style: AppText.label(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.md),
          const _ItemsCard(),
          SizedBox(height: AppSpacing.xl),
          const _PaymentCard(),
          SizedBox(height: AppSpacing.xl),
          const _AddressCard(),
          SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.menu),
            label: const Text('Commander a nouveau'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: Size.fromHeight(6.8.h),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.mdRadius),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            label: const Text('Telecharger la facture'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              foregroundColor: AppColors.textSecondary,
              minimumSize: Size.fromHeight(6.8.h),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.mdRadius),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: AppSpacing.pillRadius,
            ),
            child: Text(
              '✓ Livre',
              style: AppText.label(color: AppColors.greenDark),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Votre commande a ete livree avec succes\na votre porte.',
            textAlign: TextAlign.center,
            style: AppText.body(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.lgRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.mdRadius,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The Golden Grain\nBakery', style: AppText.h2()),
                Text(
                  '☆ 4.8 (120+ avis) • Boulangerie & Cafe',
                  style: AppText.body(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.lgRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: const Column(
        children: [
          _OrderItem(
            qty: '2×',
            title: 'Croissant au Beurre',
            subtitle: '2.25€ par unite',
            price: '4.50€',
          ),
          Divider(height: 1),
          _OrderItem(
            qty: '1×',
            title: 'Baguette Tradition',
            subtitle: 'Farine Label Rouge',
            price: '1.20€',
          ),
          Divider(height: 1),
          _OrderItem(
            qty: '1×',
            title: 'Cafe Latte',
            subtitle: 'Lait d avoine, Grand format',
            price: '3.80€',
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String qty;
  final String title;
  final String subtitle;
  final String price;

  const _OrderItem({
    required this.qty,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: AppSpacing.smRadius,
            ),
            child: Center(
              child: Text(qty, style: AppText.label(color: AppColors.primary)),
            ),
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyLg()),
                Text(subtitle, style: AppText.bodySm()),
              ],
            ),
          ),
          Text(price, style: AppText.h3()),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'RESUME DU PAIEMENT',
      children: [
        _MoneyRow(label: 'Sous-total', value: '14.00€'),
        _MoneyRow(label: 'Frais de livraison', value: '2.50€'),
        const Divider(),
        _MoneyRow(label: 'Total', value: '16.50€', total: true),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: AppSpacing.smRadius,
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card_outlined),
              const SizedBox(width: 12),
              Text('Visa ending in 4242', style: AppText.label()),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool total;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.total = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.7.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: total
                ? AppText.h3(color: AppColors.primary)
                : AppText.body(),
          ),
          Text(
            value,
            style: total
                ? AppText.h2(color: AppColors.primary)
                : AppText.body(),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ADRESSE DE LIVRAISON',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.orangeSoft,
              child: Icon(Icons.location_on_outlined, color: AppColors.primary),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('123 Rue de la Paix', style: AppText.bodyLg()),
                  Text('75002 Paris, France', style: AppText.body()),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Container(
          height: 15.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppSpacing.mdRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.infinite, painter: _MapLinesPainter()),
              Icon(Icons.location_on, size: 40, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.label(color: AppColors.textSecondary)),
          SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final minor = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-20, size.height * .2),
      Offset(size.width + 10, size.height * .8),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .25, -10),
      Offset(size.width * .65, size.height + 10),
      minor,
    );
    canvas.drawLine(
      Offset(0, size.height * .72),
      Offset(size.width, size.height * .3),
      minor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
