import 'package:deligood/features/client/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  final int orderId; // Id de la commande à suivre
  const SplashScreen({
    super.key, required this.orderId,
   
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showFirstImage = false;
  bool _showSecondImage = false;
  bool _isBlackBackground = false;
  bool _showText = false;

  

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    final connected = await isUserConnected();

    // 🎬 ANIMATION IDENTIQUE
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _showFirstImage = true);

   
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isBlackBackground = true);

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _showFirstImage = false;
      _showSecondImage = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showText = true);

    await Future.delayed(const Duration(seconds: 1));

    // 🧠 DÉCISION FINALE
    if (connected) {
      _navigateToHomePage();
    } else {
      _navigateToOnboardingPage();
    }
  }

  // ✅ VRAIE vérification de connexion
  Future<bool> isUserConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => OnboardingScreen(
           userRole: '', orderId: widget.orderId,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToOnboardingPage() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            OnboardingScreen(userRole: '', orderId: widget.orderId,),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        color: _isBlackBackground ? Colors.black : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_showFirstImage)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                     
                    
                    ),
                  AnimatedOpacity(
                    opacity: _showSecondImage ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                   
                  ),
                ],
              ),
              if (_showText)
                Animate(
                  effects: const [
                    MoveEffect(
                      begin: Offset(200, 0),
                      end: Offset(0, 0),
                      duration: Duration(milliseconds: 800),
                    ),
                  ],
                  child: Text(
                    'DeliGood',
                    style: TextStyle(
                      color: _isBlackBackground
                          ? Colors.white
                          : Colors.black,
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Hemi head',
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
