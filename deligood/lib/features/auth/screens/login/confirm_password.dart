import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';

class ConfirmPasswordPage extends StatefulWidget {
  final String phoneNumber;

  const ConfirmPasswordPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ConfirmPasswordPage> createState() => _ConfirmPasswordPageState();
}

class _ConfirmPasswordPageState extends State<ConfirmPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  bool obscurePin = true;
  bool obscureConfirmPin = true;
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
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  // =====================================================
  // RESET PIN
  // =====================================================
  Future<void> _resetPin() async {
    // Reset error
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _playShakeAnimation();
      return;
    }

    final newPin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    // Vérification locale de correspondance
    if (newPin != confirmPin) {
      _handleError('Les codes PIN ne correspondent pas');
      return;
    }

    // Validation du PIN (pas de séquences, pas de répétitions)
    if (!_isValidPin(newPin)) {
      return;
    }

    setState(() => isLoading = true);

    try {
      await Api.post(
        '/pin/reset/confirm/',
        auth: false,
        body: {
          'phone_number': widget.phoneNumber,
          'new_pin': newPin,
          'new_pin_confirmation': confirmPin,
        },
      );

      if (!mounted) return;

      _showSuccessDialog();

      // Retourner à la page de connexion après 2 secondes
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _handleError(
        'Erreur lors de la réinitialisation du PIN. Réessayez.',
      );
      debugPrint("Erreur reset PIN: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // VALIDATE PIN
  // =====================================================
  bool _isValidPin(String pin) {
    // Vérifier si c'est uniquement des chiffres répétés
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      _handleError('Le PIN ne peut pas être composé du même chiffre répété');
      return false;
    }

    // Vérifier les séquences simples
    final sequences = ['0123', '1234', '2345', '3456', '4567', '5678', '6789', '9876', '8765', '7654', '6543', '5432', '4321', '3210'];
    if (sequences.contains(pin)) {
      _handleError('Le PIN ne peut pas être une séquence simple');
      return false;
    }

    return true;
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
  // SUCCESS DIALOG
  // =====================================================
  void _showSuccessDialog() {
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
                'PIN réinitialisé !',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Vous pouvez maintenant vous connecter',
                textAlign: TextAlign.center,
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
              Color(0xFF1976D2),
              Color(0xFF2196F3),
              Color(0xFF64B5F6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
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
          child: const Icon(
            Icons.lock_open,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Nouveau PIN',
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
          'Choisissez un code PIN sécurisé',
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouveau code PIN',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Créez un PIN de 4 à 6 chiffres',
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

            // Security tips
            _buildSecurityTips(),
            SizedBox(height: 3.h),

            // PIN field
            _buildPinField(),
            SizedBox(height: 2.h),

            // Confirm PIN field
            _buildConfirmPinField(),
            SizedBox(height: 4.h),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
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
  // SECURITY TIPS
  // =====================================================
  Widget _buildSecurityTips() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Conseils de sécurité :',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildTip('Évitez les séquences (1234, 4321)'),
          _buildTip('Évitez les chiffres répétés (1111, 2222)'),
          _buildTip('Utilisez un code difficile à deviner'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 14),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
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
        labelText: 'Nouveau PIN',
        hintText: '••••',
        counterText: '',
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF1976D2)),
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
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
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
          return 'Le PIN est obligatoire';
        }
        if (v.length < 4 || v.length > 6) {
          return 'Le PIN doit contenir 4 à 6 chiffres';
        }
        return null;
      },
    );
  }

  // =====================================================
  // CONFIRM PIN FIELD
  // =====================================================
  Widget _buildConfirmPinField() {
    return TextFormField(
      controller: confirmPinController,
      obscureText: obscureConfirmPin,
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
        labelText: 'Confirmer le PIN',
        hintText: '••••',
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
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
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
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
            obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => obscureConfirmPin = !obscureConfirmPin),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Confirmation obligatoire';
        }
        if (v.length < 4 || v.length > 6) {
          return 'Le PIN doit contenir 4 à 6 chiffres';
        }
        if (v != pinController.text) {
          return 'Les PINs ne correspondent pas';
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
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : _resetPin,
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
                    'Réinitialiser le PIN',
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