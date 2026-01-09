import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class ConfirmPasswordPage extends StatefulWidget {
  final String phoneNumber; // On récupère le numéro depuis forget_password

  const ConfirmPasswordPage({super.key, required this.phoneNumber});

  @override
  State<ConfirmPasswordPage> createState() => _ConfirmPasswordPageState();
}

class _ConfirmPasswordPageState extends State<ConfirmPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();

  bool obscurePin = true;
  bool obscureConfirmPin = true;
  bool isLoading = false;

  // ================= API RESET PIN =================
  Future<void> _resetPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final newPin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (newPin != confirmPin) {
      _showError("Les PIN ne correspondent pas");
      setState(() => isLoading = false);
      return;
    }

    // Utilise ton baseUrl déjà défini ailleurs
    final url = Uri.parse('${ApiConfig.baseUrl}/pin/reset/confirm/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': widget.phoneNumber,
          'new_pin': newPin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN réinitialisé avec succès')),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showError(data['message'] ?? 'Erreur lors de la réinitialisation');
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
      appBar: AppBar(title: const Text('Nouveau PIN')),
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
                      'Choisissez un nouveau PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // ===== NOUVEAU PIN =====
                    TextFormField(
                      controller: pinController,
                      obscureText: obscurePin,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration:
                          _inputDecoration(label: 'Nouveau PIN', icon: Icons.lock)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePin ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => obscurePin = !obscurePin),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Le PIN est obligatoire';
                        if (value.length != 4) return 'PIN à 4 chiffres';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // ===== CONFIRMER PIN =====
                    TextFormField(
                      controller: confirmPinController,
                      obscureText: obscureConfirmPin,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: _inputDecoration(
                        label: 'Confirmer PIN',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPin
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => obscureConfirmPin = !obscureConfirmPin),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Confirmation obligatoire';
                        if (value.length != 4) return 'PIN à 4 chiffres';
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
                        onPressed: isLoading ? null : _resetPin,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Réinitialiser le PIN',
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
