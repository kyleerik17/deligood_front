import 'package:deligood/core/network/api.dart';

import 'package:deligood/features/auth/screens/login/confirm_password.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final allowed = await AuthApi.verifyIdentity(
        phone: phoneController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );

      if (!mounted) return;

      if (allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identité confirmée')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmPasswordPage(
              phoneNumber: phoneController.text.trim(),
            ),
          ),
        );
      } else {
        _showError('Informations incorrectes');
      }
    } catch (_) {
      _showError('Erreur réseau ou serveur');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(message)),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade400),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF6F1E7),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 2.h),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Colors.deepPurple.shade700),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  Text(
                    'VÉRIFICATION D\'IDENTITÉ',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _decoration('Numéro de téléphone', Icons.phone),
                    validator: (v) =>
                        v == null || v.length < 8 ? 'Numéro invalide' : null,
                  ),

                  SizedBox(height: 1.5.h),

                  TextFormField(
                    controller: firstNameController,
                    decoration: _decoration('Prénom', Icons.person),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),

                  SizedBox(height: 1.5.h),

                  TextFormField(
                    controller: lastNameController,
                    decoration:
                        _decoration('Nom', Icons.person_outline),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),

                  SizedBox(height: 4.h),

                  SizedBox(
                    height: 6.h,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyIdentity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('VALIDER'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
