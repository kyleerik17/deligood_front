import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'commande_resto_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood (Crème)
// ─────────────────────────────────────────────
const kOrange = Color(0xFFFF6B35);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess = Color(0xFF4CAF50);
const kError = Color(0xFFFF5A5F);
const kTeal = Color(0xFF00CCBC);
const kBlue = Color(0xFF185FA5);

// ── Statut helpers ────────────────────────────
Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'pending':
    case 'en attente':
      return Colors.orange;
    case 'accepted':
    case 'preparing':
    case 'en préparation':
      return kTeal;
    case 'ready':
    case 'prête':
      return kBlue;
    case 'delivered':
    case 'livrée':
      return kSuccess;
    case 'cancelled':
    case 'annulée':
      return kError;
    default:
      return kTextSecondary;
  }
}

String _statusLabel(String s) {
  switch (s.toLowerCase()) {
    case 'pending':
      return 'En attente';
    case 'accepted':
      return 'Acceptée';
    case 'preparing':
      return 'En préparation';
    case 'ready':
      return 'Prête';
    case 'delivered':
      return 'Livrée';
    case 'cancelled':
      return 'Annulée';
    default:
      return s;
  }
}

IconData _statusIcon(String s) {
  switch (s.toLowerCase()) {
    case 'pending':
    case 'en attente':
      return Icons.hourglass_top_rounded;
    case 'accepted':
      return Icons.thumb_up_alt_rounded;
    case 'preparing':
      return Icons.restaurant_rounded;
    case 'ready':
      return Icons.done_all_rounded;
    case 'delivered':
    case 'livrée':
      return Icons.check_circle_rounded;
    case 'cancelled':
    case 'annulée':
      return Icons.cancel_rounded;
    default:
      return Icons.info_rounded;
  }
}

// ═════════════════════════════════════════════
class CommandeDetailPage extends StatefulWidget {
  final CommandeResto commande;
  const CommandeDetailPage({super.key, required this.commande});

  @override
  State<CommandeDetailPage> createState() => _CommandeDetailPageState();
}

class _CommandeDetailPageState extends State<CommandeDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;

  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────
  Future<void> _accepterCommande() async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      setState(() => _isProcessing = false);
      _showError('Token manquant. Veuillez vous reconnecter.');
      return;
    }

    final url =
        'https://deligood-backend.onrender.com/api/orders/restaurant/${widget.commande.id}/status/';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith('ey')
              ? 'Bearer $token'
              : 'Token $token',
        },
        body: jsonEncode({'status': 'accepted'}),
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        HapticFeedback.heavyImpact();

        // ✅ Persister l'orderId — la commande reste jusqu'à livraison
        await prefs.setInt('active_order_id', widget.commande.id);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeRestaurant(orderId: widget.commande.id),
            ),
          );
        }
      } else {
        _showError('Erreur serveur : ${response.statusCode}');
      }
    } catch (_) {
      setState(() => _isProcessing = false);
      _showError('Erreur réseau. Vérifiez votre connexion.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Erreur',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: kTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: kOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirmer',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        content: Text(
          'Voulez-vous accepter cette commande ?',
          style: GoogleFonts.poppins(color: kTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _accepterCommande();
            },
            child: Text(
              'Accepter',
              style: GoogleFonts.poppins(
                color: kOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final commande = widget.commande;
    final isPending =
        commande.status.toLowerCase() == 'pending' ||
        commande.status.toLowerCase() == 'en attente';
    final sColor = _statusColor(commande.status);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kTextPrimary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          'Commande #${commande.id}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
      ),

      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 4.h),
            children: [
              _StatusBanner(status: commande.status, color: sColor),
              SizedBox(height: 2.5.h),
              _SectionLabel(label: 'Client'),
              SizedBox(height: 1.h),
              _ClientCard(commande: commande),
              SizedBox(height: 2.5.h),
              _SectionLabel(
                label: 'Articles',
                badge: '${commande.items.length}',
              ),
              SizedBox(height: 1.h),
              ...commande.items.asMap().entries.map(
                (e) => _ArticleRow(item: e.value, index: e.key),
              ),
              SizedBox(height: 2.5.h),
              _TotalCard(commande: commande),
              if (isPending) ...[
                SizedBox(height: 3.h),
                _AcceptButton(
                  isProcessing: _isProcessing,
                  onTap: _showConfirmDialog,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// WIDGETS COMPOSANTS
// ═══════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBanner({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.5.h, horizontal: 5.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color, size: 30),
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statut de la commande',
                style: GoogleFonts.poppins(
                  color: color.withOpacity(0.65),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                _statusLabel(status),
                style: GoogleFonts.playfairDisplay(
                  color: color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? badge;
  const _SectionLabel({required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: kTextSecondary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        if (badge != null) ...[
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.poppins(
                color: kOrange,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  final CommandeResto commande;
  const _ClientCard({required this.commande});

  @override
  Widget build(BuildContext context) {
    final initial = commande.clientName.isNotEmpty
        ? commande.clientName[0].toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kOrange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: kOrange,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  commande.clientName,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Divider(color: Colors.grey.shade100, height: 1),
          SizedBox(height: 1.5.h),
          _InfoRow(
            icon: Icons.phone_rounded,
            text: commande.phone.isNotEmpty ? commande.phone : '—',
            iconColor: kTeal,
          ),
          SizedBox(height: 1.h),
          _InfoRow(
            icon: Icons.location_on_rounded,
            text: commande.address.isNotEmpty ? commande.address : '—',
            iconColor: kOrange,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9.w,
          height: 9.w,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12.sp, color: kTextSecondary),
          ),
        ),
      ],
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final CommandeItem item;
  final int index;
  const _ArticleRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.unitPrice * item.quantity;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.2.h),
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 9.w,
              height: 9.w,
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: kOrange,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${lineTotal.toStringAsFixed(0)} F',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: kOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final CommandeResto commande;
  const _TotalCard({required this.commande});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.poppins(
                  color: kTextSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 0.2.h),
              Text(
                'Commande',
                style: GoogleFonts.poppins(
                  color: kTextPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${commande.total.toStringAsFixed(0)} FCFA',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: kOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTap;
  const _AcceptButton({required this.isProcessing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 6.5.h,
        decoration: BoxDecoration(
          color: isProcessing ? Colors.grey.shade200 : kOrange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isProcessing
              ? []
              : [
                  BoxShadow(
                    color: kOrange.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: kOrange,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: kWhite, size: 20),
                    SizedBox(width: 2.w),
                    Text(
                      'Accepter la commande',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: kWhite,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}