import 'dart:ui' as ui show Path;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:sizer/sizer.dart';


// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange        = Color(0xFFFF6B35);
const kOrangeDark    = Color(0xFFE85520);
const kTeal          = Color(0xFF00CCBC);
const kBg            = Color(0xFFF7F3EF);
const kWhite         = Colors.white;
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess       = Color(0xFF4CAF50);

// Couleurs spécifiques carte
const kMarkerRestaurant = kOrange;
const kMarkerClient     = kTeal;
const kMarkerDriver     = kSuccess;

class HomeScreen extends StatefulWidget {
  final int orderId;
  const HomeScreen({super.key, required this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;

  bool isLoading    = true;
  String? errorMessage;
  String orderStatus = "En attente";

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _mockData();
  }

  void _mockData() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        restaurantPos = const LatLng(5.348, -4.008);
        clientPos     = const LatLng(5.320, -4.020);
        deliveryPos   = null;
        isLoading     = false;
        orderStatus   = "En préparation";
      });
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Carte ──
          _buildMap(),

          // ── Top bar ──
          _buildTopBar(),

          // ── Empty state ──
          if (restaurantPos == null && clientPos == null && !isLoading)
            _buildEmptyState(),

          // ── Loading overlay ──
          if (isLoading) _buildLoadingOverlay(),

          // ── Bottom sheet ──
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // MAP
  // ════════════════════════════════════════════
  Widget _buildMap() {
    final center = clientPos ?? const LatLng(5.3290, -4.0080);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 13.5),
      children: [
        // Tuiles claires pour cohérence fond crème
        TileLayer(
          urlTemplate:
              'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'app.deligood',
        ),

        // Ligne de route
        if (restaurantPos != null && clientPos != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [restaurantPos!, clientPos!],
                strokeWidth: 4.0,
                color: kOrange.withOpacity(0.85),
                borderColor: kOrange.withOpacity(0.2),
                borderStrokeWidth: 8,
              ),
            ],
          ),

        // Marqueurs
        MarkerLayer(
          markers: [
            if (restaurantPos != null)
              _buildMarker(
                pos: restaurantPos!,
                icon: Icons.storefront_rounded,
                color: kMarkerRestaurant,
                label: 'Restaurant',
              ),
            if (clientPos != null)
              _buildMarker(
                pos: clientPos!,
                icon: Icons.home_rounded,
                color: kMarkerClient,
                label: 'Vous',
              ),
            if (deliveryPos != null)
              _buildMarker(
                pos: deliveryPos!,
                icon: Icons.delivery_dining_rounded,
                color: kMarkerDriver,
                label: 'Livreur',
              ),
          ],
        ),
      ],
    );
  }

  // ── Marqueur professionnel ────────────────────────────
  Marker _buildMarker({
    required LatLng pos,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Marker(
      width: 80,
      height: 90,
      point: pos,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.08).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Badge icône ──
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            // ── Pointe du pin ──
            CustomPaint(
              size: const Size(14, 8),
              painter: _PinTailPainter(color),
            ),

            // ── Label ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: kWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // TOP BAR
  // ════════════════════════════════════════════
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _topBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            // Titre centré
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orderStatus == 'En attente' ? Colors.orange : kSuccess,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suivi commande',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _topBarButton(
              icon: Icons.refresh_rounded,
              onTap: () {
                setState(() => isLoading = true);
                _mockData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: kTextPrimary, size: 20),
      ),
    );
  }

  // ════════════════════════════════════════════
  // EMPTY STATE
  // ════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded,
                  color: kOrange, size: 48),
            ),
            SizedBox(height: 2.h),
            Text(
              'Aucune commande active',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              'La carte reste active pour le suivi de vos prochaines commandes.',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // LOADING
  // ════════════════════════════════════════════
  Widget _buildLoadingOverlay() {
    return Container(
      color: kBg.withOpacity(0.6),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: kOrange, strokeWidth: 2.5),
              SizedBox(height: 2.h),
              Text(
                'Chargement de la carte…',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // BOTTOM SHEET
  // ════════════════════════════════════════════
  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Container(
                width: 12.w, height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              SizedBox(height: 2.h),

              // ── Titre statut ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: kOrange, size: 22),
                  ),
                  SizedBox(width: 3.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #${widget.orderId}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: kTextSecondary,
                        ),
                      ),
                      Text(
                        orderStatus,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge statut
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 0.6.h),
                    decoration: BoxDecoration(
                      color: orderStatus == 'En attente'
                          ? Colors.orange.withOpacity(0.12)
                          : kSuccess.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      orderStatus == 'En attente' ? '⏳ Attente' : '✅ Actif',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: orderStatus == 'En attente'
                            ? Colors.orange
                            : kSuccess,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // ── Séparateur ──
              Divider(color: Colors.grey.shade200, height: 1),

              SizedBox(height: 2.h),

              // ── Infos restaurant / livreur ──
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.storefront_rounded,
                      color: kOrange,
                      title: 'Restaurant',
                      value: restaurantPos != null ? 'Connecté' : 'Inconnu',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.delivery_dining_rounded,
                      color: kTeal,
                      title: 'Livreur',
                      value: deliveryPos == null ? 'En attente' : 'En route',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.home_rounded,
                      color: kSuccess,
                      title: 'Livraison',
                      value: clientPos != null ? 'Confirmée' : '—',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.5.h),

              // ── Bouton suivi ──
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed_rounded,
                          color: kWhite, size: 20),
                      SizedBox(width: 2.w),
                      Text(
                        'Suivi en temps réel',
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

  // ── Card info ─────────────────────────────────────────
  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: kTextSecondary,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Painter pour la pointe du marqueur ───────────────────
class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final ui.Path path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}