import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pages
import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';

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
          home: AuthWrapper(orderId: orderId),
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

  // Vérifie si l'utilisateur est déjà connecté
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final type = prefs.getString('user_type');

    // Petite pause pour le splash/chargement
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      // Si token et type existent, l'utilisateur est connecté
      if (token != null && type != null) {
        userRole = type.toLowerCase();
      }
      isLoading = false;
    });
  }

  // Callback après login réussi
  void _onLoginSuccess(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token'); // déjà stocké par LoginPage

    setState(() {
      userRole = type.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userRole != null) {
      // Utilisateur connecté → affiche la barre de navigation
      return CustomBottomNavBar(
        userRole: userRole!,
        orderId: widget.orderId,
      );
    } else {
      // Non connecté → affiche la page de login
      return LoginPage(
        orderId: widget.orderId,
        onLoginSuccess: _onLoginSuccess,
      );
    }
  }
}
