import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:deligood/features/client/screens/onboarding_screen.dart';

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

  // ── Controllers ──────────────────────────────────────────
  late AnimationController _masterFade;   // fade global entrée
  late AnimationController _logoScale;    // logo pop-in
  late AnimationController _lineDraw;     // ligne qui se dessine
  late AnimationController _shimmer;      // shimmer sur le nom
  late AnimationController _exitFade;     // fade out sortie

  late Animation<double> _masterFadeAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _lineAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _exitAnim;

  bool _showTagline  = false;
  bool _showLoader   = false;

  @override
  void initState() {
    super.initState();

    // Fade entrée global
    _masterFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _masterFadeAnim = CurvedAnimation(
      parent: _masterFade, curve: Curves.easeIn,
    );

    // Logo scale + opacity
    _logoScale = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _logoScaleAnim = CurvedAnimation(
      parent: _logoScale, curve: Curves.elasticOut,
    );
    _logoOpacityAnim = CurvedAnimation(
      parent: _logoScale, curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    // Ligne décorative
    _lineDraw = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _lineAnim = CurvedAnimation(parent: _lineDraw, curve: Curves.easeOut);

    // Shimmer sur le texte
    _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnim = _shimmer;

    // Fade sortie
    _exitFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _exitAnim = CurvedAnimation(parent: _exitFade, curve: Curves.easeIn);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Fade entrée fond
    _masterFade.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // 2. Logo pop-in
    _logoScale.forward();
    await Future.delayed(const Duration(milliseconds: 600));

    // 3. Ligne + tagline
    _lineDraw.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showTagline = true);

    await Future.delayed(const Duration(milliseconds: 700));

    // 4. Loader
    if (mounted) setState(() => _showLoader = true);

    // 5. Vérif token
    await _isUserConnected();
    await Future.delayed(const Duration(seconds: 2));

    // 6. Fade out + navigation
    if (!mounted) return;
    _exitFade.forward();
    await Future.delayed(const Duration(milliseconds: 600));

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
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) =>
            OnboardingScreen(userRole: '', orderId: widget.orderId),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _masterFade.dispose();
    _logoScale.dispose();
    _lineDraw.dispose();
    _shimmer.dispose();
    _exitFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return AnimatedBuilder(
      animation: _exitAnim,
      builder: (_, child) => Opacity(
        opacity: 1 - _exitAnim.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: FadeTransition(
          opacity: _masterFadeAnim,
          child: Stack(
            children: [
              // ── Fond dégradé ──────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF8F4),
                      kBg,
                      kBgWarm,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Cercle décoratif haut droite ──────────────
              Positioned(
                top: -12.h,
                right: -15.w,
                child: Container(
                  width: 55.w,
                  height: 55.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kOrange.withOpacity(0.08),
                        kOrange.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Cercle décoratif bas gauche ───────────────
              Positioned(
                bottom: -8.h,
                left: -10.w,
                child: Container(
                  width: 45.w,
                  height: 45.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kOrangeSoft.withOpacity(0.25),
                        kOrangeSoft.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Contenu centré ────────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Logo ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _logoScaleAnim,
                      builder: (_, child) => Opacity(
                        opacity: _logoOpacityAnim.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _logoScaleAnim.value.clamp(0.0, 1.15),
                          child: child,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo extérieur doux
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kOrange.withOpacity(0.06),
                            ),
                          ),
                          // Halo intermédiaire
                          Container(
                            width: 27.w,
                            height: 27.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kOrange.withOpacity(0.10),
                            ),
                          ),
                          // Cercle principal blanc
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: kOrange.withOpacity(0.22),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              size: 11.w,
                              color: kOrange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // ── Nom de l'app avec shimmer ─────────────
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            final shimmerProgress = _shimmerAnim.value;
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                kTextPrimary,
                                kOrange,
                                kTextPrimary,
                              ],
                              stops: [
                                (shimmerProgress - 0.3).clamp(0.0, 1.0),
                                shimmerProgress.clamp(0.0, 1.0),
                                (shimmerProgress + 0.3).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'DeliGood',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // masqué par ShaderMask
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      },
                    ).animate().fadeIn(duration: 600.ms, delay: 400.ms)
                     .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms),

                    SizedBox(height: 1.5.h),

                    // ── Ligne décorative animée ───────────────
                    AnimatedBuilder(
                      animation: _lineAnim,
                      builder: (_, __) {
                        return Align(
                          alignment: Alignment.center,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: _lineAnim.value,
                              child: Container(
                                width: 20.w,
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: const LinearGradient(
                                    colors: [kOrange, kOrangeSoft],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 1.5.h),

                    // ── Tagline ───────────────────────────────
                    if (_showTagline)
                      Text(
                        'Livraison rapide & fiable',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: kTextPrimary.withOpacity(0.40),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate()
                       .fadeIn(duration: 500.ms)
                       .slideY(begin: 0.3, end: 0, duration: 500.ms),

                    SizedBox(height: 7.h),

                    // ── Loader ────────────────────────────────
                    if (_showLoader)
                      _buildDotLoader()
                        .animate()
                        .fadeIn(duration: 400.ms),
                  ],
                ),
              ),

              // ── Badge pays en bas ─────────────────────────
              Positioned(
                bottom: 4.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 0.8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kOrange.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      'Côte d\'Ivoire 🇨🇮',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: kTextPrimary.withOpacity(0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3 points qui pulsent en décalé ───────────────────────
  Widget _buildDotLoader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w),
          child: _PulseDot(delay: Duration(milliseconds: i * 200)),
        );
      }),
    );
  }
}

// ── Dot pulsant individuel ────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Duration delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 2.5.w,
        height: 2.5.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kOrange.withOpacity(0.3 + _anim.value * 0.7),
        ),
        transform: Matrix4.identity()
          ..translate(0.0, -4.0 * _anim.value),
      ),
    );
  }
}