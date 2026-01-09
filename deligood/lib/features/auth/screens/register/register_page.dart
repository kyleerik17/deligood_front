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

    print('📤 REGISTER BODY: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📥 STATUS: ${response.statusCode}');
      print('📦 BODY: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // retour login
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 4.h),
                    Text(
                      'Inscription',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('Téléphone', Icons.phone),
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: obscurePin,
                      decoration: _decoration('PIN', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePin
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => obscurePin = !obscurePin),
                        ),
                      ),
                      validator: (v) =>
                          v!.length != 4 ? 'PIN à 4 chiffres' : null,
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: firstNameController,
                      decoration: _decoration('Prénom', Icons.person),
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: lastNameController,
                      decoration: _decoration('Nom', Icons.person_outline),
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: localityController,
                      decoration: _decoration('Localité', Icons.location_on),
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: 2.h),

                    DropdownButtonFormField<String>(
                      initialValue: userType,
                      decoration: _decoration('Type utilisateur', Icons.group),
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
                    SizedBox(height: 4.h),

                    SizedBox(
                      height: 6.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isLoading ? null : _register,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'S\'inscrire',
                                style: TextStyle(color: Colors.white),
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
      ),
    );
  }
}
