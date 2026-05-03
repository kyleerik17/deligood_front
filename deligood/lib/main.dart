import 'package:deligood/core/session/session_manager.dart';
import 'package:deligood/features/auth/auth_state.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:deligood/features/client/screens/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:deligood/widgets/CustomBottomNavBar.dart';

// ── Logger silencieux en production ──
void _log(String msg) {
  if (kDebugMode) print(msg);
}

Map<String, dynamic> decodeJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return {};
  String payload = parts[1];
  switch (payload.length % 4) {
    case 2: payload += '=='; break;
    case 3: payload += '='; break;
  }
  final decoded = utf8.decode(base64Url.decode(payload));
  return jsonDecode(decoded) as Map<String, dynamic>;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionManager();
  await Future.wait([
    session.loadSession(),
    AuthState.instance.loadFromPrefs(),
  ]);
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
          home: const SplashScreen(orderId: 0,),
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

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Priorité 1 : token depuis AuthState (chargé dans main())
    String? token = AuthState.instance.token.isNotEmpty
        ? AuthState.instance.token
        : null;

    // ✅ Priorité 2 : SharedPreferences
    token ??= prefs.getString('access_token');

    final type = prefs.getString('user_type') ??
        AuthState.instance.userRole;

    final storedOrderId = prefs.getInt('order_id') ?? 0;

    _log('🔑 TOKEN (init) → ${token != null && token.isNotEmpty ? "OUI (${token.length} chars)" : "NON ❌"}');
    _log('👤 USER TYPE → $type');
    _log('🗝 TOUTES LES CLÉS → ${prefs.getKeys()}');

    if (!mounted) return;

    setState(() {
      orderId = storedOrderId;
      userRole = (token != null && token.isNotEmpty &&
                  type != null && type.isNotEmpty)
          ? type.toLowerCase().trim()
          : null;
      isLoading = false;
    });
  }

  Future<void> onLoginSuccess(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type.toLowerCase().trim());

    final token = prefs.getString('access_token');
    _log('✅ onLoginSuccess → type=$type | token=${token != null ? "OUI" : "NON ❌"}');
    _log('🗝 CLÉS APRÈS LOGIN → ${prefs.getKeys()}');

    if (!mounted) return;
    setState(() {
      userRole = type.toLowerCase().trim();
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_type');
    await prefs.remove('user_id');
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('phone_number');
    await prefs.remove('email');

    AuthState.instance.clear();
    _log('🚪 Logout effectué');

    if (!mounted) return;
    setState(() => userRole = null);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return userRole != null
        ? CustomBottomNavBar(userRole: userRole!, orderId: orderId)
        : LoginScreen(orderId: orderId, onLoginSuccess: onLoginSuccess);
  }
}