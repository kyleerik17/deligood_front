import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:deligood/core/styles/app_theme.dart' as design;
import 'package:deligood/features/payments/services/payment_api.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────

class PaymentColors {
  PaymentColors._();

  static const cream = design.AppColors.surface;
  static const creamDark = design.AppColors.surfaceWarm;
  static const creamDeep = design.AppColors.outline;
  static const brown = design.AppColors.primary;
  static const text = design.AppColors.textPrimary;
  static const textLight = design.AppColors.textSecondary;
  static const white = design.AppColors.white;

  static const shadow = Color(0x22000000);

  static const wave = Color(0xFF0090D8);
  static const waveLight = Color(0xFFE0F4FE);

  static const orange = design.AppColors.orange;
  static const orangeLight = design.AppColors.orangeSoft;

  static const moov = Color(0xFF0066CC);
  static const moovLight = Color(0xFFE0EEFF);

  static const mtn = Color(0xFFFFCC00);
  static const mtnLight = Color(0xFFFFF8D6);
}

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class PaymentMethod {
  final String id;
  final String name;
  final String subtitle;
  final String logo;
  final Color brandColor;
  final Color brandLight;
  final String prefix;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.logo,
    required this.brandColor,
    required this.brandLight,
    required this.prefix,
  });
}

final paymentMethods = <PaymentMethod>[
  PaymentMethod(
    id: 'wave',
    name: 'Wave',
    subtitle: 'Paiement instantané',
    logo: 'W',
    brandColor: PaymentColors.wave,
    brandLight: PaymentColors.waveLight,
    prefix: '+225',
  ),
  PaymentMethod(
    id: 'orange_money',
    name: 'Orange Money',
    subtitle: 'Mobile Money',
    logo: 'O',
    brandColor: PaymentColors.orange,
    brandLight: PaymentColors.orangeLight,
    prefix: '+225',
  ),
  PaymentMethod(
    id: 'mtn_money',
    name: 'MTN Money',
    subtitle: 'MoMo',
    logo: 'MT',
    brandColor: PaymentColors.mtn,
    brandLight: PaymentColors.mtnLight,
    prefix: '+225',
  ),
  PaymentMethod(
    id: 'moov_money',
    name: 'Moov Money',
    subtitle: 'Flooz',
    logo: 'M',
    brandColor: PaymentColors.moov,
    brandLight: PaymentColors.moovLight,
    prefix: '+225',
  ),
];

// ─────────────────────────────────────────────
// CART ITEM
// ─────────────────────────────────────────────

class CartSummaryItem {
  final String name;
  final int quantity;
  final double price;

  const CartSummaryItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;
}

// ─────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────

class PaymentPage extends StatefulWidget {
  final double orderTotal;
  final List<CartSummaryItem> orderItems;
  final int? orderId;

  final String? successUrl;
  final String? errorUrl;

  const PaymentPage({
    super.key,
    required this.orderTotal,
    required this.orderItems,
    this.orderId,
    this.successUrl,
    this.errorUrl,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _selected;
  final _phoneController = TextEditingController();
  bool _loading = false;

  void _select(PaymentMethod m) {
    setState(() {
      _selected = m;
      _phoneController.clear();
    });
  }

  Future<void> _pay() async {
    if (_selected == null || _phoneController.text.isEmpty) return;

    if (widget.orderId == null) return;

    setState(() => _loading = true);

    try {
      final phone = PaymentApi.normalizePhone(
        _phoneController.text,
        countryPrefix: _selected!.prefix,
      );

      final session = await PaymentApi.createPayment(
        orderId: widget.orderId!,
        paymentMethod: _selected!.id,
        amount: widget.orderTotal,
        phoneNumber: phone,
        successUrl: widget.successUrl,
        errorUrl: widget.errorUrl,
      );

      if (session.redirectUrl.isNotEmpty) {
        final uri = Uri.parse(session.redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (_) => _PendingSheet(
            method: _selected!,
            total: widget.orderTotal,
            orderId: widget.orderId,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaymentColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 20),
              _totalCard(),
              const SizedBox(height: 20),
              _methods(),
              if (_selected != null) _phone(),
              const SizedBox(height: 20),
              _payBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      const BackButton(),
      Text(
        "Paiement",
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _totalCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        "Total : ${widget.orderTotal.toStringAsFixed(0)} FCFA",
        style: GoogleFonts.poppins(fontSize: 20),
      ),
    ),
  );

  Widget _methods() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: paymentMethods.map((m) {
      final selected = _selected?.id == m.id;

      return GestureDetector(
        onTap: () => _select(m),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? m.brandLight : Colors.white,
            border: Border.all(
              color: selected ? m.brandColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(m.name),
        ),
      );
    }).toList(),
  );

  Widget _phone() => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(hintText: "Numéro téléphone"),
    ),
  );

  Widget _payBtn() => ElevatedButton(
    onPressed: _loading ? null : _pay,
    child: _loading ? const CircularProgressIndicator() : const Text("Payer"),
  );
}

// ─────────────────────────────────────────────
// SHEET
// ─────────────────────────────────────────────

class _PendingSheet extends StatelessWidget {
  final PaymentMethod method;
  final double total;
  final int? orderId;

  const _PendingSheet({
    required this.method,
    required this.total,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Confirme sur ${method.name}"),
          Text("Total: ${total.toStringAsFixed(0)} FCFA"),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text("J'ai payé"),
          ),
        ],
      ),
    );
  }
}
