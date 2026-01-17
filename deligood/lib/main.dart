import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pages
import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:deligood/features/client/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Récupération sécurisée du orderId depuis SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final orderId = prefs.getInt('order_id') ?? 0; // 0 si non trouvé

  runApp(MyApp(orderId: orderId));
}

class MyApp extends StatelessWidget {
  final int orderId;

  const MyApp({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DéliGood',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: SplashScreen(orderId: orderId),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final int orderId; // Id de la commande à suivre
  const AuthWrapper({super.key, required this.orderId});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final type = prefs.getString('user_type');

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      userRole = type;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userRole != null) {
      // Passe orderId à CustomBottomNavBar
      return CustomBottomNavBar(
        userRole: userRole!.toLowerCase(),
        orderId: widget.orderId,
      );
    } else {
      return LoginPage(
        orderId: widget.orderId, // ✅ Passe orderId à LoginPage
        onLoginSuccess: (String type) {
          setState(() {
            userRole = type;
          });
        },
      );
    }
  }
}
