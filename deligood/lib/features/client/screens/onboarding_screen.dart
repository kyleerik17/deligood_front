import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';

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

  final List<String> titles = [
    "Bienvenue sur DeliGood",
    "Commandez vos repas facilement",
    "Recevez-les rapidement",
  ];

  final List<String> descriptions = [
    "Votre application de livraison de repas en Côte d'Ivoire.",
    "Choisissez vos plats et passez votre commande en quelques clics.",
    "Suivez vos commandes et profitez d’un service rapide.",
  ];

  @override
  void initState() {
    super.initState();

    // Icône pulse animation
    _iconPulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    // Texte slide/fade
    _textSlideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
          ..forward();

    // Lignes digitales
    _lineController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  void nextPage() {
    if (currentIndex < titles.length - 1) {
      setState(() {
        currentIndex++;
        _textSlideController.forward(from: 0);
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onLoginSuccess: (String type) {},
            orderId: widget.orderId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _textSlideController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fond pur
      body: Stack(
        children: [
          // ------------------- LIGNES DIGITALES HUD -------------------
          AnimatedBuilder(
            animation: _lineController,
            builder: (_, __) {
              return CustomPaint(
                painter: HudLinePainter(_lineController.value),
                child: Container(),
              );
            },
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),

                // TITRE ANIMÉ
                SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: _textSlideController, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: _textSlideController,
                    child: Text(
                      titles[currentIndex],
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // ICONE CENTRALE DIGITAL PULSE
                AnimatedBuilder(
                  animation: _iconPulseController,
                  builder: (_, child) {
                    double scale = 1 + 0.05 * sin(2 * pi * _iconPulseController.value);
                    return Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.delivery_dining,
                              size: 24.w, color: Colors.deepOrange.withOpacity(0.3)),
                          Icon(Icons.delivery_dining,
                              size: 20.w, color: Colors.deepOrange),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 2.h),

                // DESCRIPTION ANIMÉE
                SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: _textSlideController, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: _textSlideController,
                    child: Text(
                      descriptions[currentIndex],
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black54,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                Spacer(),

                // PROGRESS BAR DIGITAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    titles.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: currentIndex == index ? 6.w : 3.w,
                      height: 0.7.h,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.deepOrange
                            : Colors.deepOrange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // BOUTON COMMENCER DIGITAL PULSE
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      currentIndex == titles.length - 1
                          ? "Commencer"
                          : "Suivant",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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

// ------------------- HUD DIGITAL LINES -------------------
class HudLinePainter extends CustomPainter {
  final double progress;
  HudLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange.withOpacity(0.15)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 20; i++) {
      double y = (i * 6 + progress * 6) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i < 15; i++) {
      double x = (i * 8 + progress * 8) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HudLinePainter oldDelegate) => true;
}
