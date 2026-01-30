import 'dart:convert';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class LoginPage extends StatefulWidget {
  final int? orderId; // Nullable
  final void Function(String type) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess, this.orderId});

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
    final restaurantId = prefs.getInt('restaurant_id') ?? 0;

    print("Auto-login check -> token: $token, userType: $userType, restaurantId: $restaurantId");

    if (token != null && userType != null && mounted) {
      Navigator.pushReplacement(context, _createRoute(userType));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    print(
      "Tentative de login avec téléphone: ${phoneController.text}, PIN: ${pinController.text}",
    );

    // ⚠️ Remplace 127.0.0.1 par l’IP de ton PC sur le réseau ou ton URL en prod
    final url = Uri.parse('http://127.0.0.1:8000/api/users/login/');
    final phone = phoneController.text.trim();
    final pin = pinController.text.trim();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'pin': pin}),
      );

      print("Réponse serveur status: ${response.statusCode}");
      print("Réponse serveur body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserData(data);
        print("Login réussi, utilisateur sauvegardé.");

        if (!mounted) return;

        widget.onLoginSuccess(data['user']['user_type'] ?? '');
        Navigator.pushReplacement(
          context,
          _createRoute(data['user']['user_type'] ?? ''),
        );
      } else {
        _showError(data['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      _showError('Serveur inaccessible ou erreur réseau');
      print("Exception lors du login: $e");
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
    await prefs.setString('locality', user['locality'] ?? '');

    // ⚡ Ajout du restaurant_id si l'utilisateur est un restaurant
    if (user['user_type'] == 'restaurant') {
      await prefs.setInt('restaurant_id', user['restaurant_id'] ?? 0);
    } else {
      await prefs.setInt('restaurant_id', 0);
    }

    print("UserType: ${user['user_type']}, RestaurantId: ${prefs.getInt('restaurant_id')}");
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    print("SnackBar erreur: $message");
  }

  Route _createRoute(String userType) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          CustomBottomNavBar(userRole: userType, orderId: widget.orderId ?? 0),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delivery_dining,
                size: 20.w,
                color: Colors.deepOrangeAccent,
              ),
              SizedBox(height: 2.h),
              Text(
                'DeliGood',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent,
                ),
              ),
              SizedBox(height: 4.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(phoneController, 'Téléphone', false),
                    SizedBox(height: 2.h),
                    _buildTextField(pinController, 'PIN', true),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgetPasswordPage(),
                      ),
                    ),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscure,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure && controller == pinController ? obscurePin : false,
      maxLength: obscure ? 4 : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.deepOrangeAccent,
            width: 2,
          ),
        ),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  obscurePin ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => obscurePin = !obscurePin),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label requis';
        if (obscure && v.length != 4) return 'PIN invalide';
        return null;
      },
    );
  }
}
