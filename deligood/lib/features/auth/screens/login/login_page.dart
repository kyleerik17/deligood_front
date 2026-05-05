import 'package:deligood/core/session/auth_service.dart';
import 'package:deligood/features/auth/auth_state.dart';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';
import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

const kOrange        = Color(0xFFFF6B35);
const kBg            = Color(0xFFF7F3EF);
const kWhite         = Colors.white;
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF9E9E9E);
const kError         = Color(0xFFFF5A5F);

class LoginScreen extends StatefulWidget {
  final void Function(String type) onLoginSuccess;
  final int? orderId;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.orderId,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final phoneController = TextEditingController();
  final pinController   = TextEditingController();
  bool    obscure = true;
  bool    loading = false;
  String? error;

  // 👋 Wave avatar
  late AnimationController _waveController;
  late Animation<double>   _waveAnim;

  // 🎬 Fade page
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // 🔴 Shake erreur
  late AnimationController _shakeController;
  late Animation<double>   _shakeAnim;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _waveAnim = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _waveController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _waveController.stop();
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = phoneController.text.trim();
    final pin   = pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => error = "Remplis tous les champs pour continuer");
      _shakeController.forward(from: 0);
      return;
    }

    setState(() { loading = true; error = null; });

    final success = await _authService.login(phone: phone, pin: pin);
    if (!mounted) return;

    if (success) {
      final role = AuthState.instance.userRole;
      widget.onLoginSuccess(role);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomBottomNavBar(
            userRole: role,
            orderId: widget.orderId ?? 0,
          ),
        ),
      );
    } else {
      setState(() => error = "Numéro ou PIN incorrect");
      _shakeController.forward(from: 0);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 🌈 Fond dégradé subtil comme la maquette
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kOrange.withOpacity(0.08),
              const Color(0xFFF0EDE8),
              kOrange.withOpacity(0.04),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      SizedBox(height: 7.h),

                      // 👨‍🍳 Avatar animé
                      AnimatedBuilder(
                        animation: _waveAnim,
                        builder: (_, __) => Transform.rotate(
                          angle: _waveAnim.value,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 18.w,
                            height: 18.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kOrange.withOpacity(0.12),
                            ),
                            child: Center(
                              child: Text(
                                "🧑‍🍳",
                                style: TextStyle(fontSize: 9.w),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // 🔤 Titre soft premium
                      Text(
                        "Bon retour 👋",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),

                      SizedBox(height: 0.8.h),

                      Text(
                        "Connecte-toi pour commander",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: kTextSecondary,
                        ),
                      ),

                      SizedBox(height: 5.h),

                      // ❌ Erreur shake
                      if (error != null) ...[
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) {
                            final offset = _shakeAnim.value *
                                10 *
                                (0.5 - (_shakeAnim.value - 0.5).abs());
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: kError.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kError.withOpacity(0.18)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: kError, size: 16),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: GoogleFonts.syne(
                                      color: kError,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // 📱 Téléphone
                      _inputCard(
                        controller: phoneController,
                        hint: "Numéro de téléphone",
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),

                      SizedBox(height: 2.h),

                      // 🔒 PIN
                      _pinCard(),

                      // PIN oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgetPasswordPage(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "PIN oublié ?",
                            style: GoogleFonts.syne(
                              color: kOrange,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 3.5.h),

                      // 🔥 Bouton Se connecter
                      SizedBox(
                        width: double.infinity,
                        height: 6.8.h,
                        child: ElevatedButton(
                          onPressed: loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            disabledBackgroundColor: kOrange.withOpacity(0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Se connecter",
                                  style: GoogleFonts.syne(
                                    color: kWhite,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // ─── Séparateur "ou continuer avec" ───
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: kTextSecondary.withOpacity(0.25),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Text(
                              "ou continuer avec",
                              style: GoogleFonts.syne(
                                color: kTextSecondary,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: kTextSecondary.withOpacity(0.25),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 2.5.h),

                      // 📲 Boutons sociaux (décoratifs)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialBtn("G", const Color(0xFFEA4335)),
                          SizedBox(width: 4.w),
                          _socialBtn("", Colors.black, isApple: true),
                          SizedBox(width: 4.w),
                          _socialBtn("f", const Color(0xFF1877F2)),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // S'inscrire
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.syne(
                              fontSize: 11.sp,
                              color: kTextSecondary,
                            ),
                            children: [
                              const TextSpan(text: "Pas encore de compte ? "),
                              TextSpan(
                                text: "S'inscrire",
                                style: GoogleFonts.syne(
                                  color: kOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 4.h),
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

  // 📦 Champ carte ombre douce
  Widget _inputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: GoogleFonts.syne(
          fontSize: 12.sp,
          color: kTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.syne(
            color: kTextSecondary.withOpacity(0.6),
            fontSize: 12.sp,
          ),
          prefixIcon: Icon(icon, color: kOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 2.h,
            horizontal: 4.w,
          ),
        ),
      ),
    );
  }

  // 🔢 PIN carte
  Widget _pinCard() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: pinController,
        obscureText: obscure,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: GoogleFonts.syne(
          fontSize: 18.sp,
          color: kTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: obscure ? 8 : 3,
        ),
        decoration: InputDecoration(
          hintText: "Code PIN",
          hintStyle: GoogleFonts.syne(
            color: kTextSecondary.withOpacity(0.6),
            fontSize: 12.sp,
            letterSpacing: 0,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.lock_rounded, color: kOrange, size: 20),
          suffixIcon: IconButton(
            onPressed: () => setState(() => obscure = !obscure),
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: kTextSecondary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 2.h,
            horizontal: 4.w,
          ),
        ),
      ),
    );
  }

  // 🌐 Bouton social
  Widget _socialBtn(String label, Color color, {bool isApple = false}) {
    return Container(
      width: 15.w,
      height: 15.w,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: isApple
            ? Icon(Icons.apple, color: Colors.black, size: 6.w)
            : Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 5.w,
                ),
              ),
      ),
    );
  }
}