import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/auth/screens/login/confirm_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    phoneController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  // =====================================================
  // VERIFY IDENTITY
  // =====================================================
  Future<void> _verifyIdentity() async {
    // Reset error
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _playShakeAnimation();
      return;
    }

    setState(() => isLoading = true);

    final phone = _normalizePhoneNumber(phoneController.text);
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    try {
      final allowed = await AuthApi.verifyIdentity(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;

      if (allowed) {
        _showSuccess('Identité confirmée');
        
        // Petit délai pour voir le message de succès
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmPasswordPage(phoneNumber: phone),
          ),
        );
      } else {
        _handleError('Les informations fournies sont incorrectes');
      }
    } catch (e) {
      _handleError(
        'Impossible de vérifier votre identité. Vérifiez votre connexion.',
      );
      debugPrint("Erreur vérification identité: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // HANDLE ERROR
  // =====================================================
  void _handleError(String message) {
    setState(() => errorMessage = message);
    _playShakeAnimation();
    HapticFeedback.mediumImpact();

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
                  fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // =====================================================
  // SHOW SUCCESS
  // =====================================================
  void _showSuccess(String message) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 800),
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
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF8E24AA),
              Color(0xFFAB47BC),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  _buildBackButton(),
                  SizedBox(height: 4.h),
                  _buildHeader(),
                  SizedBox(height: 5.h),
                  _buildFormCard(),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BACK BUTTON
  // =====================================================
  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'PIN oublié ?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Vérifiez votre identité pour réinitialiser votre PIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // FORM CARD
  // =====================================================
  Widget _buildFormCard() {
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
            'Vérification d\'identité',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Entrez vos informations pour continuer',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 3.h),

          // Error banner
          if (errorMessage != null) ...[
            _buildErrorBanner(),
            SizedBox(height: 2.h),
          ],

          // Phone field
          _buildPhoneField(),
          SizedBox(height: 2.h),

          // First name field
          _buildFirstNameField(),
          SizedBox(height: 2.h),

          // Last name field
          _buildLastNameField(),
          SizedBox(height: 4.h),

          // Submit button
          _buildSubmitButton(),
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
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
      ],
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        hintText: '+225 XX XX XX XX XX',
        prefixIcon: const Icon(Icons.phone, color: Color(0xFF6A1B9A)),
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
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
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
  // FIRST NAME FIELD
  // =====================================================
  Widget _buildFirstNameField() {
    return TextFormField(
      controller: firstNameController,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2D3142),
      ),
      decoration: InputDecoration(
        labelText: 'Prénom',
        hintText: 'Votre prénom',
        prefixIcon: const Icon(Icons.person, color: Color(0xFF6A1B9A)),
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
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
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
          return 'Prénom requis';
        }
        if (v.trim().length < 2) {
          return 'Le prénom doit contenir au moins 2 caractères';
        }
        return null;
      },
    );
  }

  // =====================================================
  // LAST NAME FIELD
  // =====================================================
  Widget _buildLastNameField() {
    return TextFormField(
      controller: lastNameController,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2D3142),
      ),
      decoration: InputDecoration(
        labelText: 'Nom',
        hintText: 'Votre nom',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6A1B9A)),
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
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
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
          return 'Nom requis';
        }
        if (v.trim().length < 2) {
          return 'Le nom doit contenir au moins 2 caractères';
        }
        return null;
      },
    );
  }

  // =====================================================
  // SUBMIT BUTTON
  // =====================================================
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _verifyIdentity,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A1B9A),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
                    'Vérifier mon identité',
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
}