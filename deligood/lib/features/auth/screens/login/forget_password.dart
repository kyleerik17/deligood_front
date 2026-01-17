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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Identité confirmée')));

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
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: Colors.deepPurple.shade700,
        letterSpacing: 0.5,
      ),
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.deepPurple.shade900, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================== BACKGROUND GRIFURES ==================
      body: Stack(
        children: [
          // Fond principal
          Container(color: const Color.fromARGB(255, 246, 241, 231)),

          // ================== CONTENU ==================
          SafeArea(
            child: Column(
              children: [
                // Bouton retour
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.deepPurple.shade700,
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
                              'VÉRIFICATION D\'IDENTITÉ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.deepPurple.shade800,
                                letterSpacing: 1.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 4.h),

                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                label: 'Numéro de téléphone',
                                icon: Icons.phone,
                              ).copyWith(hintText: '2250565838385'),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Le numéro est obligatoire';
                                if (value.length < 8) return 'Numéro invalide';
                                return null;
                              },
                            ),
                            SizedBox(height: 1.5.h),

                            TextFormField(
                              controller: firstNameController,
                              decoration: _inputDecoration(
                                label: 'Prénom',
                                icon: Icons.person,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Le prénom est obligatoire'
                                  : null,
                            ),
                            SizedBox(height: 1.5.h),

                            TextFormField(
                              controller: lastNameController,
                              decoration: _inputDecoration(
                                label: 'Nom',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Le nom est obligatoire'
                                  : null,
                            ),
                            SizedBox(height: 3.h),

                            SizedBox(
                              height: 6.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  shadowColor: Colors.deepPurpleAccent,
                                  elevation: 5,
                                ),
                                onPressed: isLoading ? null : _verifyIdentity,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'VALIDER',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                          fontFamily: 'Poppins',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
