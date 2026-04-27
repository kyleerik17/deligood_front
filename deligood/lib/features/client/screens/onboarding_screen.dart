import 'dart:math';
import 'package:deligood/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange        = Color(0xFFFF6B35);
const kBg            = Color(0xFFF7F3EF);
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);

class OnboardingScreen extends StatefulWidget {
  final int orderId;
  const OnboardingScreen({super.key, required String userRole, required this.orderId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int currentIndex = 0;

  late AnimationController _iconPulseController;
  late AnimationController _textSlideController;
  late AnimationController _lineController;
  late AnimationController _fadeInController;

  late Animation<double> _fadeInAnimation;

  // ── Contenu des slides ────────────────────────────────
  final List<Map<String, dynamic>> slides = [
    {
      'title':       'Bienvenue sur\nDeliGood',
      'description': 'Votre application de livraison de repas en Côte d\'Ivoire.',
      'icon':        Icons.delivery_dining_rounded,
    },
    {
      'title':       'Commandez\nfacilement',
      'description': 'Choisissez vos plats et passez votre commande en quelques clics.',
      'icon':        Icons.restaurant_menu_rounded,
    },
    {
      'title':       'Recevez\nrapidement',
      'description': 'Suivez vos commandes et profitez d\'un service rapide.',
      'icon':        Icons.access_time_filled_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();

    _iconPulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _textSlideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
          ..forward();

    _lineController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();

    _fadeInController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..forward();

    _fadeInAnimation = CurvedAnimation(parent: _fadeInController, curve: Curves.easeIn);
  }

  void _nextPage() {
    if (currentIndex < slides.length - 1) {
      setState(() {
        currentIndex++;
        _textSlideController.forward(from: 0);
      });
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => AuthWrapper(
           
         
          ),
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _textSlideController.dispose();
    _lineController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final slide = slides[currentIndex];

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── HUD grid animée (conservée du design original) ──
          AnimatedBuilder(
            animation: _lineController,
            builder: (_, __) => CustomPaint(
              painter: HudLinePainter(_lineController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Bulles décoratives (cohérence Login/Register) ──
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 80, right: 30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.06),
              ),
            ),
          ),

          // ── Contenu principal ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Column(
                  children: [
                    // ── Skip button ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: currentIndex < slides.length - 1
                          ? GestureDetector(
                              onTap: () => setState(() {
                                currentIndex = slides.length - 1;
                                _textSlideController.forward(from: 0);
                              }),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Passer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const Spacer(),

                    // ── Icône centrale avec halo pulse ──
                    AnimatedBuilder(
                      animation: _iconPulseController,
                      builder: (_, child) {
                        double scale = 1 + 0.05 * sin(2 * pi * _iconPulseController.value);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(7.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withOpacity(0.18),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(slide['icon'] as IconData,
                                size: 22.w, color: kOrange.withOpacity(0.25)),
                            Icon(slide['icon'] as IconData,
                                size: 18.w, color: kOrange),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 5.h),

                    // ── Titre animé — Playfair Display ──
                    SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: _textSlideController, curve: Curves.easeOut)),
                      child: FadeTransition(
                        opacity: _textSlideController,
                        child: Text(
                          slide['title'] as String,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // ── Description animée — Poppins ──
                    SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: _textSlideController, curve: Curves.easeOut)),
                      child: FadeTransition(
                        opacity: _textSlideController,
                        child: Text(
                          slide['description'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: kTextSecondary,
                            letterSpacing: 0.3,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Dots de progression ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                          width: currentIndex == index ? 6.w : 2.5.w,
                          height: 0.7.h,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? kOrange
                                : kOrange.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // ── Bouton Suivant / Commencer ──
                    SizedBox(
                      width: double.infinity,
                      height: 6.5.h,
                      child: ElevatedButton(
                        onPressed: _nextPage,
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
                            Text(
                              currentIndex == slides.length - 1
                                  ? 'Commencer'
                                  : 'Suivant',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              currentIndex == slides.length - 1
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HUD Grid Painter (conservé, deepOrange → kOrange) ──
class HudLinePainter extends CustomPainter {
  final double progress;
  HudLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOrange.withOpacity(0.08)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 20; i++) {
      double y = (i * size.height / 20 + progress * size.height / 20) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 0; i < 15; i++) {
      double x = (i * size.width / 15 + progress * size.width / 15) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HudLinePainter oldDelegate) => true;
}