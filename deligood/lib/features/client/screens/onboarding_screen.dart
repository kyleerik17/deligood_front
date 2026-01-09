import 'package:flutter/material.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';

class OnboardingScreen extends StatefulWidget {
    final int orderId; // Id de la commande à suivre
  const OnboardingScreen({super.key, required String userRole, required this.orderId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;

  final List<String> titles = [
    "Bienvenue sur DeliGood",
    "Commandez vos repas facilement",
    "Recevez-les rapidement",
  ];

  final List<String> descriptions = [
    "Votre application de livraison de repas en Cote d'Ivoire.",
    "Choisissez vos plats et passez votre commande en quelques clics.",
    "Suivez vos commandes et profitez d’un service rapide.",
  ];

  void nextPage() {
    if (currentIndex < titles.length - 1) {
      setState(() => currentIndex++);
    } else {
      // ✅ Dernière page → LoginPage
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) =>  LoginPage(onLoginSuccess: (String type) {  }, orderId: widget.orderId,)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            Text(
              titles[currentIndex],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Text(
              descriptions[currentIndex],
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: nextPage,
                child: Text(
                  currentIndex == titles.length - 1 ? "Commencer" : "Suivant",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
