import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pages
import 'package:deligood/widgets/CustomBottomNavBar.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DeliGood',
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? userRole;
  int orderId = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // 🔥 CHARGE TOUT UNE SEULE FOIS PROPREMENT
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    final type = prefs.getString('user_type');
    final storedOrderId = prefs.getInt('order_id') ?? 0;

    if (!mounted) return;

    setState(() {
      orderId = storedOrderId;

      if (token != null &&
          token.isNotEmpty &&
          type != null &&
          type.isNotEmpty) {
        userRole = type.toLowerCase().trim();
      } else {
        userRole = null;
      }

      isLoading = false;
    });
  }

  // 🔥 APPELÉ APRÈS LOGIN
  Future<void> onLoginSuccess(String type) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_type', type.toLowerCase().trim());

    if (!mounted) return;

    setState(() {
      userRole = type.toLowerCase().trim();
    });
  }

  // 🔥 LOGOUT CLEAN
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('user_type');

    if (!mounted) return;

    setState(() {
      userRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final loggedIn = userRole != null;

    return loggedIn
        ? CustomBottomNavBar(
            userRole: userRole!,
            orderId: orderId,
          )
        : LoginScreen(
            orderId: orderId,
            onLoginSuccess: onLoginSuccess,
          );
  }
}