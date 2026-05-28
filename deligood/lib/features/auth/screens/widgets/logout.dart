import 'package:deligood/core/network/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';

class LogoutService {
  static final String logoutUrl = '${Api.baseUrl}/api/users/logout/';

  static Future<void> performLogout(
    BuildContext context, {
    int? orderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token'); // <-- uniformisé

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse(logoutUrl),
          headers: {
            'Authorization': Api.authHeaderValue(token),
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          debugPrint("Logout réussi");
        } else {
          debugPrint("Erreur logout: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Erreur réseau logout: $e");
      }
    }

    // Supprime toutes les données locales
    await prefs.clear();

    // Redirection vers LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginPage(onLoginSuccess: (String type) {}, orderId: orderId),
      ),
    );
  }
}
