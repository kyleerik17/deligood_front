import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:deligood/features/client/screens/onboarding_screen.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange      = Color(0xFFFF6B35);
const kOrangeSoft  = Color(0xFFFFD4C2);
const kBg          = Color(0xFFF7F3EF);
const kBgWarm      = Color(0xFFF0EAE2);
const kTextPrimary = Color(0xFF1A1A1A);

class SplashScreen extends StatefulWidget {
  final int orderId;
  const SplashScreen({super.key, required this.orderId});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _ringController;
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  bool _showText = false;

  final int particleCount = 40;
  final Random random = Random();
  late List<Offset>  particlePositions;
  late List<double>  particleSizes;
  late List<double>  particleOpacities;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();

    _ringController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    particlePositions = List.generate(
        particleCount, (_) => Offset(random.nextDouble(), random.nextDouble()));
    particleSizes =
        List.generate(particleCount, (_) => random.nextDouble() * 4 + 2);
    particleOpacities =
        List.generate(particleCount, (_) => random.nextDouble() * 0.22 + 0.05);

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    await _isUserConnected();

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showText = true);

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _navigateToOnboarding();
  }

  Future<bool> _isUserConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            OnboardingScreen(userRole: '', orderId: widget.orderId),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _ringController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ── Dégradé radial chaud ──
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFFFFF8F4), // blanc cassé au centre
                    kBg,
                    kBgWarm,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Particules organiques ──
            AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                painter: OrganicParticlePainter(
                  particlePositions,
                  particleSizes,
                  particleOpacities,
                  _particleController.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Anneaux concentriques pulsants ──
            Center(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (_, __) => CustomPaint(
                  painter: RingPainter(_ringController.value),
                  child: SizedBox(width: 70.w, height: 70.w),
                ),
              ),
            ),

            // ── Logo + texte ──
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo card blanche avec glow orange
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, child) {
                      final scale =
                          1 + 0.06 * sin(2 * pi * _logoController.value);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: kOrange.withOpacity(0.18),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: kOrangeSoft.withOpacity(0.30),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.delivery_dining_rounded,
                              size: 16.w, color: kOrange.withOpacity(0.15)),
                          Icon(Icons.delivery_dining_rounded,
                              size: 13.w, color: kOrange),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Nom app
                  if (_showText) ...[
                    Text(
                      'DeliGood',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        letterSpacing: 1.0,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: 0.25, end: 0),

                    SizedBox(height: 0.8.h),

                    Text(
                      'Livraison rapide & fiable',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: kTextPrimary.withOpacity(0.38),
                        letterSpacing: 0.8,
                      ),
                    ).animate().fadeIn(duration: 900.ms, delay: 200.ms),
                  ],

                  SizedBox(height: 6.h),

                  // Loader
                  SizedBox(
                    width: 8.w,
                    height: 8.w,
                    child: CircularProgressIndicator(
                      color: kOrange,
                      strokeWidth: 2,
                      backgroundColor: kOrange.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),

            // ── Label pays en bas ──
            Positioned(
              bottom: 4.h,
              left: 0, right: 0,
              child: Center(
                child: Text(
                  'Côte d\'Ivoire 🇨🇮',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: kTextPrimary.withOpacity(0.22),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Particules organiques (mouvement sinusoïdal) ──────────
class OrganicParticlePainter extends CustomPainter {
  final List<Offset>  positions;
  final List<double>  sizes;
  final List<double>  opacities;
  final double        progress;

  OrganicParticlePainter(this.positions, this.sizes, this.opacities, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      final dx = sin(progress * 2 * pi + i * 0.8) * 18;
      final dy = cos(progress * 2 * pi + i * 0.6) * 14;
      final x  = (positions[i].dx * size.width  + dx).clamp(0.0, size.width).toDouble();
      final y  = (positions[i].dy * size.height + dy).clamp(0.0, size.height).toDouble();

      final paint = Paint()
        ..color = kOrange.withOpacity(opacities[i])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrganicParticlePainter old) => true;
}

// ── Anneaux concentriques qui s'expandent doucement ───────
class RingPainter extends CustomPainter {
  final double progress;
  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2;

    for (int r = 0; r < 3; r++) {
      final phase   = (progress + r / 3) % 1.0;
      final radius  = maxR * phase;
      final opacity = (1 - phase) * 0.10;

      final paint = Paint()
        ..color       = kOrange.withOpacity(opacity)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter old) => true;
}