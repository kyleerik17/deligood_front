import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/session/auth_service.dart';
import 'package:deligood/features/auth/screens/login/confirm_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange        = Color(0xFFFF6B35);
const kBg            = Color(0xFFF7F3EF);
const kWhite         = Colors.white;
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kError         = Color(0xFFFF5A5F);

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage>
    with TickerProviderStateMixin {

  final _formKey           = GlobalKey<FormState>();
  final phoneController    = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController  = TextEditingController();

  bool isLoading      = false;
  String? errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnimation  = CurvedAnimation(parent: _fadeController,  curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    phoneController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  String _normalize(String v) =>
      v.trim().replaceAll(RegExp(r'[ \-\(\)]'), '');

  Future<void> _verifyIdentity() async {
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _shake();
      return;
    }

    setState(() => isLoading = true);

    final phone = _normalize(phoneController.text);
    final first = firstNameController.text.trim();
    final last  = lastNameController.text.trim();

    try {
      final ok = await AuthService.verifyIdentity(
        phone: phone,
        firstName: first,
        lastName: last,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Identité validée', style: GoogleFonts.poppins(fontSize: 13)),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(4.w),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 700));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmPasswordPage(phoneNumber: phone),
          ),
        );
      } else {
        _setError('Informations incorrectes');
      }
    } catch (e) {
      _setError('Erreur serveur / connexion');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _setError(String msg) {
    setState(() => errorMessage = msg);
    _shake();
    HapticFeedback.mediumImpact();
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Bulles décoratives ──
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 80, right: 30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withOpacity(0.06),
              ),
            ),
          ),

          // ── Contenu ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),

                      // ── Bouton retour ──
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: kTextPrimary,
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // ── Header ──
                      _buildHeader(),

                      SizedBox(height: 4.h),

                      // ── Formulaire ──
                      _buildForm(),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône dans container arrondi (même style que Register)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: kOrange, size: 36),
        ),
        SizedBox(height: 2.h),
        Text(
          'Récupération\nde PIN',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            height: 1.15,
          ),
        ),
        SizedBox(height: 0.8.h),
        Text(
          'Vérifiez votre identité pour continuer',
          style: GoogleFonts.poppins(fontSize: 12.sp, color: kTextSecondary),
        ),
      ],
    );
  }

  // ── Formulaire ────────────────────────────────────────
  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          _shakeController.value * 8 * (1 - _shakeController.value * 2).sign,
          0,
        ),
        child: child,
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Bannière erreur ──
              if (errorMessage != null) ...[
                _buildErrorBanner(),
                SizedBox(height: 2.h),
              ],

              // ── Section label ──
              _buildSectionTitle('Informations personnelles', Icons.person_outline_rounded),
              SizedBox(height: 1.5.h),

              _buildField(
                controller: firstNameController,
                label: 'Prénom',
                icon: Icons.person_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (v.trim().length < 2) return 'Trop court';
                  return null;
                },
              ),
              SizedBox(height: 1.5.h),
              _buildField(
                controller: lastNameController,
                label: 'Nom',
                icon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (v.trim().length < 2) return 'Trop court';
                  return null;
                },
              ),

              SizedBox(height: 3.h),

              _buildSectionTitle('Contact', Icons.phone_outlined),
              SizedBox(height: 1.5.h),

              _buildField(
                controller: phoneController,
                label: 'Numéro de téléphone',
                icon: Icons.phone_rounded,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (_normalize(v).length < 8) return 'Numéro invalide';
                  return null;
                },
              ),

              SizedBox(height: 3.h),

              // ── Bouton vérifier ──
              SizedBox(
                width: double.infinity,
                height: 6.5.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyIdentity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vérifier mon identité',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bannière erreur ───────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: kError.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kError.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: kError, size: 20),
        SizedBox(width: 2.5.w),
        Expanded(
          child: Text(
            errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 12.sp, color: kError, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ── Champ de saisie — style Design System ─────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13.sp, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kOrange, size: 22),
        labelStyle: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
        errorStyle: GoogleFonts.poppins(fontSize: 10.sp, color: kError),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kError, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
      ),
    );
  }

  // ── Label de section ──────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kOrange, size: 16),
      ),
      SizedBox(width: 2.w),
      Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.sp, fontWeight: FontWeight.w600, color: kTextPrimary),
      ),
    ]);
  }
}