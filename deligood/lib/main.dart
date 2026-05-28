import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deligood/core/styles/app_theme.dart';
// Pages
import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Récupération sécurisée du orderId depuis SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final orderId = prefs.getInt('order_id') ?? 0;

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
          title: 'DeliGood',
          theme: AppTheme.light,
          home: AuthWrapper(orderId: orderId),
          routes: {
            '/login': (_) =>
                LoginPage(orderId: orderId, onLoginSuccess: (_) {}),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final int orderId;
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
    // ✅ Utiliser addPostFrameCallback pour éviter l'accès prématuré à window/MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final type = prefs.getString('user_type');

      // Petite pause pour le splash/chargement
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ Vérifier mounted avant setState (sécurité cycle de vie Web)
      if (!mounted) return;
      
      setState(() {
        if (token != null && type != null) {
          userRole = type.toLowerCase();
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ AuthWrapper error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onLoginSuccess(String type) {
    if (!mounted) return;
    setState(() {
      userRole = type.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // ✅ Écran de chargement simple, sans Sizer/MediaQuery dépendant
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    if (userRole != null) {
      return CustomBottomNavBar(userRole: userRole!, orderId: widget.orderId);
    } else {
      return LoginPage(
        orderId: widget.orderId,
        onLoginSuccess: _onLoginSuccess,
      );
    }
  }
}