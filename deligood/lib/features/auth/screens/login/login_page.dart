import 'dart:convert';
import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class LoginPage extends StatefulWidget {
  final int? orderId; // Nullable
  final void Function(String type) onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    this.orderId, // Nullable// ✅ requis
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  bool obscurePin = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userType = prefs.getString('user_type');

    if (token != null && userType != null && mounted) {
      Navigator.pushReplacement(context, _createRoute(userType));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = Uri.parse('http://127.0.0.1:8000/api/users/login/');
    final phone = phoneController.text.trim();
    final pin = pinController.text.trim();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'pin': pin}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserData(data);

        if (!mounted) return;

        widget.onLoginSuccess(data['user']['user_type']);

        Navigator.pushReplacement(
          context,
          _createRoute(data['user']['user_type']),
        );
      } else {
        _showError(data['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      _showError('Serveur inaccessible ou erreur réseau');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'];
    final user = data['user'];

    if (token == null || user == null) {
      throw Exception('Réponse invalide du serveur');
    }

    await prefs.setString('access_token', token);
    await prefs.setString('user_type', user['user_type'] ?? '');
    await prefs.setString('first_name', user['first_name'] ?? '');
    await prefs.setString('last_name', user['last_name'] ?? '');
    await prefs.setString('phone_number', user['phone_number'] ?? '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Route _createRoute(String userType) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          HomeScreen(orderId: widget.orderId ?? 0), // ✅ passe orderId
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Numéro requis' : null,
                ),
                TextFormField(
                  controller: pinController,
                  obscureText: obscurePin,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePin ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscurePin = !obscurePin),
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.length == 4 ? null : 'PIN invalide',
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
