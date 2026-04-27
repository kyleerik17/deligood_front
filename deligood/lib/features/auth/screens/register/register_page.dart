import 'package:deligood/core/network/api.dart';
import 'package:deligood/services/api_service.dart' as AuthApiReg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final localityController = TextEditingController();

  String userType = 'client';
  bool isLoading = false;
  bool obscurePin = true;
  final int _currentStep = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Types avec icônes et descriptions
  final List<Map<String, dynamic>> _userTypes = [
    {
      'value': 'client',
      'label': 'Client',
      'icon': Icons.person_rounded,
      'desc': 'Je commande des repas',
      'color': const Color(0xFF4CAF50),
    },
    {
      'value': 'livreur',
      'label': 'Livreur',
      'icon': Icons.delivery_dining,
      'desc': 'Je livre des commandes',
      'color': const Color(0xFF2196F3),
    },
    {
      'value': 'restaurant',
      'label': 'Restaurant',
      'icon': Icons.restaurant,
      'desc': 'Je propose des repas',
      'color': const Color(0xFFFF6B35),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    phoneController.dispose();
    pinController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    localityController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthApiReg.register(
        phone: phoneController.text.trim(),
        pin: pinController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        locality: localityController.text.trim(),
        userType: userType,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 60),
              ),
              SizedBox(height: 2.h),
              Text(
                'Compte créé !',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Bienvenue sur DeliGood 🎉',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // ferme dialog
                    Navigator.pop(context); // retour login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Se connecter',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? hint,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: formatters,
      style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12.sp,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: Stack(
        children: [
          // Background décoratif
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35).withOpacity(0.12),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2.h),

                        // Back + titre
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // Titre
                        Text(
                          'Créer un\ncompte',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 0.8.h),
                        Text(
                          'Rejoignez DeliGood et commandez en quelques secondes',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // ===== TYPE UTILISATEUR =====
                        Text(
                          'Je suis...',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 1.5.h),

                        Row(
                          children: _userTypes.map((type) {
                            final isSelected = userType == type['value'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => userType = type['value']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    right: type['value'] != 'restaurant' ? 2.w : 0,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (type['color'] as Color).withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? type['color'] as Color
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (type['color'] as Color)
                                                  .withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        type['icon'] as IconData,
                                        color: isSelected
                                            ? type['color'] as Color
                                            : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        type['label'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? type['color'] as Color
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 3.h),

                        // ===== SECTION INFOS PERSO =====
                        _buildSectionTitle('Informations personnelles', Icons.person_outline),
                        SizedBox(height: 1.5.h),

                        // Prénom + Nom
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: firstNameController,
                                label: 'Prénom',
                                icon: Icons.person_rounded,
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: _buildField(
                                controller: lastNameController,
                                label: 'Nom',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 1.5.h),

                        _buildField(
                          controller: localityController,
                          label: 'Localité / Quartier',
                          icon: Icons.location_on_rounded,
                          hint: 'Ex: Yopougon, Cocody...',
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),

                        SizedBox(height: 3.h),

                        // ===== SECTION CONNEXION =====
                        _buildSectionTitle('Identifiants', Icons.lock_outline),
                        SizedBox(height: 1.5.h),

                        _buildField(
                          controller: phoneController,
                          label: 'Numéro de téléphone',
                          icon: Icons.phone_rounded,
                          keyboard: TextInputType.phone,
                          hint: '0585113413',
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) =>
                              v == null || v.length < 8 ? 'Numéro invalide' : null,
                        ),

                        SizedBox(height: 1.5.h),

                        _buildField(
                          controller: pinController,
                          label: 'Code PIN (4 chiffres)',
                          icon: Icons.pin_rounded,
                          keyboard: TextInputType.number,
                          obscure: obscurePin,
                          maxLength: 4,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          suffix: IconButton(
                            icon: Icon(
                              obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(() => obscurePin = !obscurePin),
                          ),
                          validator: (v) =>
                              v == null || v.length != 4 ? 'PIN à 4 chiffres requis' : null,
                        ),

                        SizedBox(height: 4.h),

                        // ===== BOUTON S'INSCRIRE =====
                        SizedBox(
                          width: double.infinity,
                          height: 6.5.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              disabledBackgroundColor: Colors.grey.shade300,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                        'Créer mon compte',
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

                        SizedBox(height: 2.h),

                        // Déjà un compte
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Déjà un compte ? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Se connecter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6B35),
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                            ],
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B35), size: 16),
        ),
        SizedBox(width: 2.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}