import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:deligood/features/client/screens/onboarding_screen.dart';

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
  bool _showText = false;

  final int particleCount = 50;
  final Random random = Random();

  late List<Offset> particlePositions;
  late List<double> particleSizes;

  @override
  void initState() {
    super.initState();
    _logoController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    particlePositions = List.generate(
        particleCount,
        (_) => Offset(random.nextDouble(), random.nextDouble()));
    particleSizes =
        List.generate(particleCount, (_) => random.nextDouble() * 2 + 1);

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    final connected = await isUserConnected();

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _showText = true);

    await Future.delayed(const Duration(seconds: 3));

    if (connected) {
      _navigateToOnboardingPage();
    } else {
      _navigateToOnboardingPage();
    }
  }

  Future<bool> isUserConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  void _navigateToOnboardingPage() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            OnboardingScreen(userRole: '', orderId: widget.orderId),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------ PARTICULES ------------------
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return CustomPaint(
                painter: ParticlePainter(
                  particlePositions,
                  particleSizes,
                  _particleController.value,
                ),
                child: Container(),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------------- LOGO CENTRAL ----------------
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, child) {
                    double scale =
                        1 + 0.1 * sin(2 * pi * _logoController.value);
                    double rotate = 0.1 * sin(2 * pi * _logoController.value);
                    return Transform.rotate(
                      angle: rotate,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo glow
                      Icon(Icons.delivery_dining,
                          size: 24.w, color: Colors.deepOrange.withOpacity(0.2)),
                      Icon(Icons.delivery_dining,
                          size: 20.w, color: Colors.deepOrange),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ---------------- TEXTE ----------------
                if (_showText)
                  Text(
                    'DeliGood',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.deepOrangeAccent.withOpacity(0.6),
                          offset: const Offset(0, 0),
                        )
                      ],
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                // ---------------- MINI LOADER DIGITAL ----------------
                SizedBox(
                  width: 12.w,
                  height: 12.w,
                  child: CircularProgressIndicator(
                    color: Colors.deepOrangeAccent,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PARTICLE PAINTER ----------------
class ParticlePainter extends CustomPainter {
  final List<Offset> positions;
  final List<double> sizes;
  final double progress;

  ParticlePainter(this.positions, this.sizes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.deepOrange.withOpacity(0.2);
    for (int i = 0; i < positions.length; i++) {
      double x = (positions[i].dx * size.width + progress * 50) % size.width;
      double y = (positions[i].dy * size.height + progress * 50) % size.height;
      canvas.drawCircle(Offset(x, y), sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
