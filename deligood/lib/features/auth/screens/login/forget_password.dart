import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:deligood/features/auth/screens/login/confirm_password.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool isLoading = false;

  // ================= API VERIFICATION IDENTITÉ =================
  Future<void> _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final phone = phoneController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    final url = Uri.parse('${ApiConfig.baseUrl}pin/reset/identity/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phone,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['reset_allowed'] == true) {
        // SnackBar facultatif
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Identité confirmée')));

        // 🔹 NAVIGATION VERS CONFIRM_PASSWORD
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmPasswordPage(phoneNumber: phone),
          ),
        );
      } else {
        _showError('Informations incorrectes');
      }
    } catch (e) {
      _showError('Erreur réseau ou serveur inaccessible');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 5.h),
                    Text(
                      'Vérifiez votre identité',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // ===== NUMÉRO =====
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'Numéro de téléphone',
                        icon: Icons.phone,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le numéro est obligatoire';
                        }
                        if (value.length < 8) return 'Numéro invalide';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // ===== PRÉNOM =====
                    TextFormField(
                      controller: firstNameController,
                      decoration: _inputDecoration(
                        label: 'Prénom',
                        icon: Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prénom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // ===== NOM =====
                    TextFormField(
                      controller: lastNameController,
                      decoration: _inputDecoration(
                        label: 'Nom',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 4.h),

                    // ===== BOUTON VALIDER =====
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isLoading ? null : _verifyIdentity,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Valider',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
