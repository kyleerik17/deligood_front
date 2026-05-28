import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final localityController = TextEditingController();

  String userType = 'client';
  bool isLoading = false;
  bool obscurePin = true;

  @override
  void dispose() {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte cree avec succes'),
          backgroundColor: AppColors.greenDark,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          1.4.h,
          AppSpacing.page,
          3.h,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 2.4.h),
              Text('Creer un compte', style: AppText.h1()),
              SizedBox(height: .7.h),
              Text(
                'Un seul compte pour commander, livrer ou vendre sur DeliGood.',
                style: AppText.body(),
              ),
              SizedBox(height: 2.6.h),
              PremiumCard(
                padding: EdgeInsets.all(5.w),
                child: Column(
                  children: [
                    _field(
                      phoneController,
                      'Telephone',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || !RegExp(r'^\d{8,12}$').hasMatch(v)
                          ? 'Numero invalide'
                          : null,
                    ),
                    SizedBox(height: 1.4.h),
                    _field(
                      pinController,
                      'PIN',
                      Icons.lock_rounded,
                      keyboardType: TextInputType.number,
                      obscure: true,
                      maxLength: 4,
                      validator: (v) => v == null || v.length != 4
                          ? 'PIN a 4 chiffres'
                          : null,
                    ),
                    SizedBox(height: 1.4.h),
                    _field(firstNameController, 'Prenom', Icons.person_rounded),
                    SizedBox(height: 1.4.h),
                    _field(lastNameController, 'Nom', Icons.badge_rounded),
                    SizedBox(height: 1.4.h),
                    _field(
                      localityController,
                      'Localite',
                      Icons.location_on_rounded,
                    ),
                    SizedBox(height: 1.4.h),
                    DropdownButtonFormField<String>(
                      initialValue: userType,
                      decoration: const InputDecoration(
                        labelText: 'Profil',
                        prefixIcon: Icon(
                          Icons.group_rounded,
                          color: AppColors.orange,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'client',
                          child: Text('Client'),
                        ),
                        DropdownMenuItem(
                          value: 'livreur',
                          child: Text('Livreur'),
                        ),
                        DropdownMenuItem(
                          value: 'restaurant',
                          child: Text('Restaurant'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => userType = v ?? 'client'),
                    ),
                    SizedBox(height: 2.4.h),
                    SizedBox(
                      width: double.infinity,
                      height: 6.2.h,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _register,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_rounded),
                        label: Text(
                          isLoading ? 'Creation...' : 'Creer le compte',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure ? obscurePin : false,
      maxLength: maxLength,
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
      validator:
          validator ??
          (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
    );
  }
}
