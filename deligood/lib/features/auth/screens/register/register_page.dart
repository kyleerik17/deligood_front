import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.deepOrange.shade700,
        letterSpacing: 0.5,
        fontFamily: 'Poppins',
      ),
      prefixIcon: Icon(icon, color: Colors.deepOrange.shade400),
      filled: true,
      fillColor: Colors.orange.shade50,
      contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: Colors.deepOrange.shade700, width: 1.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: Colors.deepOrange.shade900, width: 2),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = Uri.parse('${ApiConfig.baseUrl}register/');
    final body = {
      'phone_number': phoneController.text.trim(),
      'pin': pinController.text.trim(),
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'locality': localityController.text.trim(),
      'user_type': userType,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        _showError(data.toString());
      }
    } catch (e) {
      _showError('Erreur réseau ou serveur inaccessible');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ======= Bouton Retour =======
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.deepOrange.shade700,
                      size: 4.h,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 2.h),
                        Text(
                          'CRÉER UN COMPTE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepOrange.shade800,
                            letterSpacing: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Téléphone
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _decoration(
                            'Téléphone',
                            Icons.phone,
                          ).copyWith(hintText: '2250565838385'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (!RegExp(r'^\d{8,12}$').hasMatch(v))
                              return 'Numéro invalide';
                            return null;
                          },
                        ),
                        SizedBox(height: 1.5.h),

                        // PIN
                        TextFormField(
                          controller: pinController,
                          obscureText: obscurePin,
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          decoration: _decoration('PIN', Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePin
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.deepOrange.shade700,
                              ),
                              onPressed: () =>
                                  setState(() => obscurePin = !obscurePin),
                            ),
                          ),
                          validator: (v) =>
                              v!.length != 4 ? 'PIN à 4 chiffres' : null,
                        ),
                        SizedBox(height: 1.5.h),

                        // Prénom
                        TextFormField(
                          controller: firstNameController,
                          decoration: _decoration('Prénom', Icons.person),
                          validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 1.5.h),

                        // Nom
                        TextFormField(
                          controller: lastNameController,
                          decoration: _decoration('Nom', Icons.person_outline),
                          validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 1.5.h),

                        // Localité
                        TextFormField(
                          controller: localityController,
                          decoration: _decoration(
                            'Localité',
                            Icons.location_on,
                          ),
                          validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 1.5.h),

                        // Type utilisateur
                        DropdownButtonFormField<String>(
                          value: userType,
                          decoration: _decoration(
                            'Type utilisateur',
                            Icons.group,
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
                          onChanged: (v) => setState(() => userType = v!),
                        ),
                        SizedBox(height: 3.h),

                        // Bouton S'inscrire
                        SizedBox(
                          height: 6.5.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              shadowColor: Colors.deepOrangeAccent,
                              elevation: 5,
                            ),
                            onPressed: isLoading ? null : _register,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    'S\'INSCRIRE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontFamily: 'Poppins',
                                    ),
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
          ],
        ),
      ),
    );
  }
}
