import 'dart:convert';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class LoginPage extends StatefulWidget {
  final int? orderId;
  final void Function(String type) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess, this.orderId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  bool obscurePin = true;
  bool isLoading = false;
  String? errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    _autoLogin();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userType = prefs.getString('user_type');
    final restaurantId = prefs.getInt('restaurant_id') ?? 0;

    debugPrint(
      "Auto-login check -> token: $token, userType: $userType, restaurantId: $restaurantId",
    );

    if (token != null && userType != null && mounted) {
      Navigator.pushReplacement(context, _createRoute(userType));
    }
  }

  Future<void> _login() async {
    // Reset error
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _playShakeAnimation();
      return;
    }

    setState(() => isLoading = true);
    debugPrint(
      "Tentative de login avec téléphone: ${phoneController.text}, PIN: ${pinController.text}",
    );

    final url = Uri.parse('http://127.0.0.1:8000/api/users/login/');
    final phone = phoneController.text.trim();
    final pin = pinController.text.trim();

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': phone, 'pin': pin}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'La connexion a expiré. Vérifiez votre connexion internet.',
              );
            },
          );

      debugPrint("Réponse serveur status: ${response.statusCode}");
      debugPrint("Réponse serveur body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserData(data);
        debugPrint("Login réussi, utilisateur sauvegardé.");

        if (!mounted) return;

        // Success animation
        _showSuccessDialog();

        await Future.delayed(const Duration(seconds: 2));

        widget.onLoginSuccess(data['user']['user_type'] ?? '');
        Navigator.pushReplacement(
          context,
          _createRoute(data['user']['user_type'] ?? ''),
        );
      } else {
        _handleError(data['message'] ?? 'Identifiants incorrects');
      }
    } on http.ClientException catch (e) {
      _handleError(
        'Impossible de se connecter au serveur. Vérifiez votre connexion.',
      );
      debugPrint("ClientException: $e");
    } on FormatException catch (e) {
      _handleError('Erreur de format de réponse du serveur');
      debugPrint("FormatException: $e");
    } catch (e) {
      _handleError('Une erreur inattendue s\'est produite. Réessayez.');
      debugPrint("Exception lors du login: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleError(String message) {
    setState(() => errorMessage = message);
    _playShakeAnimation();

    // Vibration visuelle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 60,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Connexion réussie !',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Bienvenue sur DeliGood',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
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

    if (user['user_type'] == 'restaurant') {
      await prefs.setInt('restaurant_id', user['restaurant_id'] ?? 0);
    } else {
      await prefs.setInt('restaurant_id', 0);
    }

    debugPrint(
      "UserType: ${user['user_type']}, RestaurantId: ${prefs.getInt('restaurant_id')}",
    );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42), Color(0xFFFFA458)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      _buildLogo(),

                      SizedBox(height: 6.h),

                      // Login Card
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue !',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3142),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Connectez-vous pour continuer',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            SizedBox(height: 4.h),

                            // Error message
                            if (errorMessage != null) ...[
                              _buildErrorBanner(),
                              SizedBox(height: 2.h),
                            ],

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildModernTextField(
                                    controller: phoneController,
                                    label: 'Numéro de téléphone',
                                    icon: Icons.phone,
                                    obscure: false,
                                  ),
                                  SizedBox(height: 2.h),
                                  _buildModernTextField(
                                    controller: pinController,
                                    label: 'Code PIN',
                                    icon: Icons.lock,
                                    obscure: true,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 3.h),

                            // Login button
                            _buildLoginButton(),

                            SizedBox(height: 2.h),

                            // Forgot password
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgetPasswordPage(),
                                  ),
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFFFF6B35),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Register section
                      _buildRegisterSection(),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.delivery_dining,
            size: 18.w,
            color: const Color(0xFFFF6B35),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'DeliGood',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Livraison rapide et fiable',
          style: TextStyle(
            fontSize: 4.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = _shakeController.value * 10;
        return Transform.translate(
          offset: Offset(offset * (1 - _shakeController.value * 2).sign, 0),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 24),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure && controller == pinController ? obscurePin : false,
      maxLength: obscure ? 4 : null,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2D3142),
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  obscurePin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => obscurePin = !obscurePin),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label requis';
        if (obscure && v.length != 4) return 'Le PIN doit contenir 4 chiffres';
        if (!obscure && v.length < 8) return 'Numéro de téléphone invalide';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pas encore de compte ?',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 1.w),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
            ),
            child: Text(
              'S\'inscrire',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
