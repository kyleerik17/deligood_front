import 'dart:convert';
import 'package:deligood/features/restaurant/widgets/commande_detail_page.dart';
import 'package:deligood/features/restaurant/widgets/commande_resto_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange = Color(0xFFFF6B35);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess = Color(0xFF4CAF50);
const kError = Color(0xFFFF5A5F);
const kTeal = Color(0xFF00CCBC);

class CommandeRestoPage extends StatefulWidget {
  const CommandeRestoPage({super.key});

  @override
  State<CommandeRestoPage> createState() => _CommandeRestoPageState();
}

class _CommandeRestoPageState extends State<CommandeRestoPage>
    with SingleTickerProviderStateMixin {
  List<CommandeResto> commandes = [];
  bool isLoading = true;
  String errorMessage = '';
  String accessToken = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    fetchCommandes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _baseUrl => 'https://deligood-backend.onrender.com';

  // ── API ───────────────────────────────────────────────
  Future<List<CommandeResto>> _fetchCommandesResto() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token introuvable. Veuillez vous reconnecter.');
    }
    accessToken = token;

    final isJwt = token.startsWith('ey');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': isJwt ? 'Bearer $token' : 'Token $token',
    };

    debugPrint('🌐 GET /api/orders/orders/restaurant/');
    debugPrint('🔑 Token type : ${isJwt ? "JWT Bearer" : "Token"}');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/orders/orders/restaurant/'),
      headers: headers,
    );

    debugPrint('📡 Status code : ${response.statusCode}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      debugPrint('📦 ${data.length} commande(s) reçue(s)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return data
          .map((e) => CommandeResto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      debugPrint('🚫 Token expiré — suppression locale');
      await prefs.remove('access_token');
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      debugPrint('❌ Erreur serveur : ${response.statusCode}');
      debugPrint('❌ Body : ${response.body}');
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  }

  Future<void> fetchCommandes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await _fetchCommandesResto();
      setState(() {
        commandes = data;
        isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      debugPrint('💥 fetchCommandes error : $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ── Couleur & label par statut ────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        return Colors.orange;
      case 'en préparation':
      case 'preparing':
        return kTeal;
      case 'prête':
      case 'ready':
        return Colors.blue;
      case 'livrée':
      case 'delivered':
        return kSuccess;
      case 'annulée':
      case 'cancelled':
        return kError;
      default:
        return kTextSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'en préparation':
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'prête':
      case 'ready':
        return Icons.done_all_rounded;
      case 'livrée':
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'annulée':
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Commandes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: GestureDetector(
              onTap: fetchCommandes,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: kTextPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoading()
            : errorMessage.isNotEmpty
            ? _buildError()
            : commandes.isEmpty
            ? _buildEmpty()
            : _buildList(),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kOrange, strokeWidth: 2.5),
            SizedBox(height: 2.h),
            Text(
              'Chargement des commandes…',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kError.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: kError,
                  size: 44,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Oups !',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                errorMessage.replaceAll('Exception: ', ''),
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: kTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.5.h),
              SizedBox(
                width: double.infinity,
                height: 5.5.h,
                child: ElevatedButton(
                  onPressed: fetchCommandes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: kWhite,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Réessayer',
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: kOrange,
              size: 52,
            ),
          ),
          SizedBox(height: 2.5.h),
          Text(
            'Aucune commande',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'Les nouvelles commandes\napparaîtront ici.',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: kTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Liste ─────────────────────────────────────────────
  Widget _buildList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: kOrange,
        backgroundColor: kWhite,
        onRefresh: fetchCommandes,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          itemCount: commandes.length,
          itemBuilder: (_, i) => _buildCard(commandes[i], i),
        ),
      ),
    );
  }

  // ── Card commande ─────────────────────────────────────
  Widget _buildCard(CommandeResto commande, int index) {
    final color = _statusColor(commande.status);
    final icon = _statusIcon(commande.status);
    final label = _statusLabel(commande.status);
    final initial = commande.clientName.isNotEmpty
        ? commande.clientName[0].toUpperCase()
        : '?';

    final totalDisplay = commande.total > 0
        ? '${commande.total.toStringAsFixed(0)} FCFA'
        : '— FCFA';

    // Résumé "TCHEP ×2, Attiéké ×1"
    final articlesResume = commande.items
        .map((e) => '${e.name} ×${e.quantity}')
        .join(', ');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommandeDetailPage(commande: commande),
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: 2.h),
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
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header : avatar + nom + chevron ──
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
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
                            commande.clientName,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            commande.items.isEmpty
                                ? 'Aucun article'
                                : articlesResume,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: kTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.5.h),
                Divider(color: Colors.grey.shade100, height: 1),
                SizedBox(height: 1.5.h),

                // ── Footer : badge statut + montant ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.7.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.7.h,
                      ),
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        totalDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: kOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
