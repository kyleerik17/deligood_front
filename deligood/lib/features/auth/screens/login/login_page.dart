

import 'package:deligood/core/session/auth_service.dart';
import 'package:deligood/features/auth/screens/login/forget_password.dart';
import 'package:deligood/features/auth/screens/register/register_page.dart';

import 'package:deligood/widgets/CustomBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sizer/sizer.dart';

// ================= DESIGN =================
const kOrange = Color(0xFFFF6B35);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kError = Color(0xFFFF5A5F);

// ================= SCREEN =================
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

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  bool obscure = true;
  bool loading = false;
  String? error;

  final AuthService _authService = AuthService();

  Future<void> _login() async {
    final phone = phoneController.text.trim();
    final pin = pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => error = "Veuillez remplir tous les champs");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final success = await _authService.login(
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;

    if (success) {
      widget.onLoginSuccess("user");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomBottomNavBar(
            userRole: "user",
            orderId: widget.orderId ?? 0,
          ),
        ),
      );
    } else {
      setState(() => error = "Identifiants incorrects");
    }

    setState(() => loading = false);

    // Après avoir reçu la réponse de l'API login

  }
  

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TITLE
                Text(
                  "Bon retour 👋",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),

                SizedBox(height: 0.5.h),

                Text(
                  "Connectez-vous pour continuer",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: kTextSecondary,
                  ),
                ),

                SizedBox(height: 5.h),

                // CARD
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      if (error != null) ...[
                        Text(error!, style: const TextStyle(color: kError)),
                        SizedBox(height: 2.h),
                      ],

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Téléphone",
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      TextField(
                        controller: pinController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: "PIN",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 1.5.h),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgetPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Mot de passe oublié ?",
                            style: TextStyle(color: kOrange),
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Se connecter"),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                // REGISTER
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Créer un compte",
                    style: TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}