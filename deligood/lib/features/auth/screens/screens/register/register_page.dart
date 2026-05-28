import 'package:deligood/core/network/api.dart';

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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      prefixIcon: Icon(icon, color: Colors.deepOrange.shade400),
      filled: true,
      fillColor: Colors.orange.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
    );
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
          content: Text('Inscription réussie'),
          backgroundColor: Colors.green,
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
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              children: [
                SizedBox(height: 2.h),

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.deepOrange.shade700,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  'CRÉER UN COMPTE',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                    letterSpacing: 1.2,
                  ),
                ),

                SizedBox(height: 4.h),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration(
                    'Téléphone',
                    Icons.phone,
                  ).copyWith(hintText: '2250565838385'),
                  validator: (v) =>
                      v == null || !RegExp(r'^\d{8,12}$').hasMatch(v)
                      ? 'Numéro invalide'
                      : null,
                ),

                SizedBox(height: 1.5.h),

                TextFormField(
                  controller: pinController,
                  obscureText: obscurePin,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('PIN', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePin ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscurePin = !obscurePin),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length != 4 ? 'PIN à 4 chiffres' : null,
                ),

                SizedBox(height: 1.5.h),

                TextFormField(
                  controller: firstNameController,
                  decoration: _decoration('Prénom', Icons.person),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),

                SizedBox(height: 1.5.h),

                TextFormField(
                  controller: lastNameController,
                  decoration: _decoration('Nom', Icons.person_outline),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),

                SizedBox(height: 1.5.h),

                TextFormField(
                  controller: localityController,
                  decoration: _decoration('Localité', Icons.location_on),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),

                SizedBox(height: 1.5.h),

                DropdownButtonFormField<String>(
                  initialValue: userType,
                  decoration: _decoration('Type utilisateur', Icons.group),
                  items: const [
                    DropdownMenuItem(value: 'client', child: Text('Client')),
                    DropdownMenuItem(value: 'livreur', child: Text('Livreur')),
                    DropdownMenuItem(
                      value: 'restaurant',
                      child: Text('Restaurant'),
                    ),
                  ],
                  onChanged: (v) => userType = v!,
                ),

                SizedBox(height: 4.h),

                SizedBox(
                  height: 6.5.h,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('S\'INSCRIRE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
