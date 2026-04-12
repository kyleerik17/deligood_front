import 'dart:convert';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? attemptsRemaining;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _autoLogin();
  }

  void _initializeAnimations() {
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

  // =====================================================
  // AUTO-LOGIN
  // =====================================================
  Future<void> _autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userType = prefs.getString('user_type');

      debugPrint(
        "Auto-login check -> token: ${token != null ? 'present' : 'null'}, userType: $userType",
      );

      if (token != null && userType != null && mounted) {
        Navigator.pushReplacement(context, _createRoute(userType));
      }
    } catch (e) {
      debugPrint("Erreur lors de l'auto-login: $e");
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================
  Future<void> _login() async {
    // Reset error and attempts
    setState(() {
      errorMessage = null;
      attemptsRemaining = null;
    });

    if (!_formKey.currentState!.validate()) {
      _playShakeAnimation();
      return;
    }

    setState(() => isLoading = true);

    final phone = _normalizePhoneNumber(phoneController.text);
    final pin = pinController.text.trim();

    debugPrint("Tentative de login avec téléphone: $phone");

    final url = Uri.parse('http://127.0.0.1:8000/api/users/login/');

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
              throw TimeoutException(
                'La connexion a expiré. Vérifiez votre connexion internet.',
              );
            },
          );

      debugPrint("Réponse serveur status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(response.body);
      } else {
        await _handleFailedLogin(response.body, response.statusCode);
      }
    } on http.ClientException {
      _handleError(
        'Impossible de se connecter au serveur. Vérifiez votre connexion.',
      );
    } on FormatException {
      _handleError('Erreur de format de réponse du serveur');
    } on TimeoutException catch (e) {
      _handleError(e.message ?? 'Timeout de connexion');
    } catch (e) {
      _handleError('Une erreur inattendue s\'est produite. Réessayez.');
      debugPrint("Exception lors du login: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // HANDLE SUCCESSFUL LOGIN
  // =====================================================
  Future<void> _handleSuccessfulLogin(String responseBody) async {
    try {
      final data = jsonDecode(responseBody);
         debugPrint("✅ Réponse login complète: $data"); 
      await _saveUserData(data);
      debugPrint("Login réussi, utilisateur sauvegardé.");

      if (!mounted) return;

      _showSuccessDialog();
      await Future.delayed(const Duration(seconds: 2));

      final userType = data['user']['user_type'] ?? '';
      widget.onLoginSuccess(userType);

      if (mounted) {
        Navigator.pushReplacement(context, _createRoute(userType));
      }
    } catch (e) {
      _handleError('Erreur lors de la sauvegarde des données');
      debugPrint("Erreur handleSuccessfulLogin: $e");
    }
  }

  // =====================================================
  // HANDLE FAILED LOGIN
  // =====================================================
  Future<void> _handleFailedLogin(String responseBody, int statusCode) async {
    try {
      final data = jsonDecode(responseBody);

      // Extraire le message d'erreur
      String message = 'Identifiants incorrects';
      
      if (data is Map) {
        // Gérer les erreurs de validation (format DRF)
        if (data.containsKey('non_field_errors')) {
          message = data['non_field_errors'] is List
              ? data['non_field_errors'][0]
              : data['non_field_errors'].toString();
        } else if (data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data.containsKey('message')) {
          message = data['message'].toString();
        }

        // Extraire le nombre de tentatives restantes si disponible
        if (message.contains('tentative')) {
          final regex = RegExp(r'(\d+)\s+tentative');
          final match = regex.firstMatch(message);
          if (match != null) {
            attemptsRemaining = int.tryParse(match.group(1) ?? '');
          }
        }
      }

      _handleError(message);
    } catch (e) {
      debugPrint("Erreur parsing réponse: $e");
      _handleError('Identifiants incorrects');
    }
  }

  // =====================================================
  // HANDLE ERROR
  // =====================================================
  void _handleError(String message) {
    setState(() => errorMessage = message);
    _playShakeAnimation();

    // Vibration haptique
    HapticFeedback.mediumImpact();

    // Snackbar avec design amélioré
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (attemptsRemaining != null && attemptsRemaining! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$attemptsRemaining tentative(s) restante(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
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
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // =====================================================
  // SUCCESS DIALOG
  // =====================================================
  void _showSuccessDialog() {
    // Vibration haptique de succès
    HapticFeedback.lightImpact();

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

  // =====================================================
  // SHAKE ANIMATION
  // =====================================================
  void _playShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  // =====================================================
  // SAVE USER DATA
  // =====================================================
  Future<void> _saveUserData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();

  // Supporte les deux formats possibles
  final token = data['token'] ?? data['access'] ?? data['access_token'];
  final user = data['user'] ?? data;

  debugPrint("🔑 Token extrait: $token");
  debugPrint("👤 User extrait: $user");

  if (token == null) {
    throw Exception('Token manquant dans la réponse');
  }

  await Future.wait([
    prefs.setString('access_token', token.toString()),
    prefs.setString('user_type', (user['user_type'] ?? '').toString()),
    prefs.setString('first_name', (user['first_name'] ?? '').toString()),
    prefs.setString('last_name', (user['last_name'] ?? '').toString()),
    prefs.setString('phone_number', (user['phone_number'] ?? '').toString()),
    prefs.setString('locality', (user['locality'] ?? '').toString()),
    prefs.setInt('user_id', user['id'] ?? 0),
  ]);

  if (user['user_type'] == 'restaurant') {
    await prefs.setInt('restaurant_id', user['restaurant_id'] ?? 0);
  } else {
    await prefs.remove('restaurant_id');
  }

  debugPrint("✅ Token sauvegardé: ${prefs.getString('access_token')}");
}
  // =====================================================
  // NORMALIZE PHONE NUMBER
  // =====================================================
  String _normalizePhoneNumber(String phone) {
    return phone
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  // =====================================================
  // CREATE ROUTE
  // =====================================================
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
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // =====================================================
  // BUILD UI
  // =====================================================
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
                      _buildLogo(),
                      SizedBox(height: 6.h),
                      _buildLoginCard(),
                      SizedBox(height: 3.h),
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

  // =====================================================
  // LOGO
  // =====================================================
  Widget _buildLogo() {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
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
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // LOGIN CARD
  // =====================================================
  Widget _buildLoginCard() {
    return Container(
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

          // Error banner
          if (errorMessage != null) ...[
            _buildErrorBanner(),
            SizedBox(height: 2.h),
          ],

          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPhoneField(),
                SizedBox(height: 2.h),
                _buildPinField(),
              ],
            ),
          ),

          SizedBox(height: 3.h),
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
                'Code PIN oublié ?',
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
    );
  }

  // =====================================================
  // ERROR BANNER
  // =====================================================
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (attemptsRemaining != null && attemptsRemaining! > 0) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      '$attemptsRemaining tentative(s) restante(s)',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFFE53935),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PHONE FIELD
  // =====================================================
  Widget _buildPhoneField() {
    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2D3142),
      ),
      inputFormatters: [
        // Limiter les caractères autorisés
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
      ],
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        hintText: '+225 XX XX XX XX XX',
        prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF6B35)),
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
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
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Numéro de téléphone requis';
        }
        final normalized = _normalizePhoneNumber(v);
        if (normalized.length < 8) {
          return 'Numéro de téléphone invalide';
        }
        return null;
      },
    );
  }

  // =====================================================
  // PIN FIELD
  // =====================================================
  Widget _buildPinField() {
    return TextFormField(
      controller: pinController,
      obscureText: obscurePin,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2D3142),
        letterSpacing: 8,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Code PIN',
        hintText: '••••',
        counterText: '',
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF6B35)),
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
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
        suffixIcon: IconButton(
          icon: Icon(
            obscurePin ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => obscurePin = !obscurePin),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Code PIN requis';
        }
        if (v.length < 4 || v.length > 6) {
          return 'Le PIN doit contenir 4 à 6 chiffres';
        }
        return null;
      },
    );
  }

  // =====================================================
  // LOGIN BUTTON
  // =====================================================
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

  // =====================================================
  // REGISTER SECTION
  // =====================================================
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

// =====================================================
// CUSTOM EXCEPTIONS
// =====================================================
class TimeoutException implements Exception {
  final String? message;
  TimeoutException(this.message);
}