import 'dart:convert';

import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class LoginPage extends StatefulWidget {
  final int? orderId;
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

  @override
  void dispose() {
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
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

    final url = Uri.parse('${Api.baseUrl}/api/users/login/');
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

        final userType = data['user']['user_type']?.toString() ?? 'client';
        widget.onLoginSuccess(userType);
        Navigator.pushReplacement(context, _createRoute(userType));
      } else {
        _showError(data['message']?.toString() ?? 'Erreur de connexion');
      }
    } catch (e) {
      _showError('Serveur inaccessible ou erreur reseau');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'];
    final user = data['user'];

    if (token == null || user == null) {
      throw Exception('Reponse invalide du serveur');
    }

    await prefs.setString('access_token', token.toString());
    await prefs.setString('user_type', user['user_type']?.toString() ?? '');
    await prefs.setString('first_name', user['first_name']?.toString() ?? '');
    await prefs.setString('last_name', user['last_name']?.toString() ?? '');
    await prefs.setString(
      'phone_number',
      user['phone_number']?.toString() ?? '',
    );
    await prefs.setString('locality', user['locality']?.toString() ?? '');
    final restaurantId = int.tryParse(user['restaurant_id']?.toString() ?? '');
    if (restaurantId != null) {
      await prefs.setInt('restaurant_id', restaurantId);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Route _createRoute(String userType) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => CustomBottomNavBar(
        userRole: userType.toLowerCase(),
        orderId: widget.orderId ?? 0,
      ),
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
    return PremiumScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            3.h,
            AppSpacing.page,
            3.h,
          ),
          child: Column(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.xlRadius,
                  boxShadow: AppShadows.card,
                ),
                child: Image.asset('assets/images/deligood_mascot_logo.png'),
              ),
              SizedBox(height: 2.h),
              Text('DeliGood', style: AppText.display()),
              SizedBox(height: .7.h),
              Text(
                'Connectez-vous pour commander, livrer ou gerer votre restaurant.',
                style: AppText.body(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              PremiumCard(
                padding: EdgeInsets.all(5.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        phoneController,
                        'Telephone',
                        Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 1.6.h),
                      _buildTextField(
                        pinController,
                        'PIN',
                        Icons.lock_rounded,
                        obscure: true,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 2.4.h),
                      SizedBox(
                        width: double.infinity,
                        height: 6.2.h,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _login,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            isLoading ? 'Connexion...' : 'Se connecter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 1.6.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgetPasswordPage(),
                        ),
                      ),
                      child: const Text('PIN oublie'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: const Text('Creer un compte'),
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
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure && controller == pinController ? obscurePin : false,
      maxLength: obscure ? 4 : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.orange),
        counterText: '',
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  obscurePin
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => obscurePin = !obscurePin),
              )
            : null,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label requis';
        if (obscure && v.length != 4) return 'PIN invalide';
        return null;
      },
    );
  }
}
