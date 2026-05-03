
import 'package:deligood/core/session/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

  final AuthService _authService = AuthService(); // ✅ IMPORTANT

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (pinController.text != confirmPinController.text) {
      setState(() => errorMessage = "Les PIN ne correspondent pas");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService.resetPin(
        phoneNumber: widget.phoneNumber,
        newPin: pinController.text,
        confirmPin: confirmPinController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN réinitialisé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = "Erreur lors de la réinitialisation";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                const Text(
                  "Nouveau PIN",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),

                const SizedBox(height: 30),

                if (errorMessage != null)
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),

                TextFormField(
                  controller: pinController,
                  obscureText: obscurePin,
                  decoration: InputDecoration(
                    labelText: "PIN",
                    suffixIcon: IconButton(
                      icon: Icon(obscurePin
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscurePin = !obscurePin),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: confirmPinController,
                  obscureText: obscureConfirmPin,
                  decoration: InputDecoration(
                    labelText: "Confirmer PIN",
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPin
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => obscureConfirmPin = !obscureConfirmPin),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Valider"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}