import 'package:deligood/core/network/api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../session/session_manager.dart';

class AuthService {
  final session = SessionManager();

  // ===============================
  // NORMALISATION NUMÉRO
  // ===============================
  String normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('225') && digits.length > 10) {
      digits = digits.substring(3);
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  // ===============================
  // LOGIN
  // ===============================
  Future<bool> login({required String phone, required String pin}) async {
    final url = Uri.parse(
      'https://deligood-backend.onrender.com/api/users/login/',
    );

    final normalizedPhone = normalizePhone(phone);

    debugPrint("========== AUTH LOGIN DEBUG ==========");
    debugPrint("NORMALIZED PHONE => $normalizedPhone");

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': normalizedPhone, 'pin': pin}),
      );

      debugPrint("STATUS CODE   => ${res.statusCode}");
      debugPrint("RESPONSE BODY => ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ On extrait toutes les infos utilisateur dès le login
        final user = data['user'] as Map<String, dynamic>? ?? {};

        final token = data['token'] ?? data['access'] ?? '';

        await session.saveSession(
          token: token,
          userType: user['user_type'] ?? '',
          userId: user['id'] ?? 0,
          // 🔥 CORRECTIF : on sauvegarde les infos utilisateur ici
          firstName: user['first_name'],
          lastName: user['last_name'],
          phoneNumber: user['phone_number'],
          email: user['email'],
        );

        debugPrint("✅ Session sauvegardée:");
        debugPrint("   first_name   => ${user['first_name']}");
        debugPrint("   last_name    => ${user['last_name']}");
        debugPrint("   phone_number => ${user['phone_number']}");
        debugPrint("   email        => ${user['email']}");
        debugPrint("   user_type    => ${user['user_type']}");

        return true;
      }

      debugPrint("❌ LOGIN FAILED => ${res.body}");
      return false;
    } catch (e) {
      debugPrint("❌ LOGIN ERROR => $e");
      return false;
    }
  }

  // ===============================
  // LOGOUT
  // ===============================
  Future<void> logout() async {
    await session.clearSession();
  }

  // ===============================
  // RESET PIN
  // ===============================
  static Future<void> resetPin({
    required String phoneNumber,
    required String newPin,
    required String confirmPin,
  }) async {
    await ApiService.post(
      '/api/users/pin/reset/confirm/',
      auth: false,
      body: {
        'phone_number': phoneNumber,
        'new_pin': newPin,
        'new_pin_confirmation': confirmPin,
      },
    );
  }

  // ===============================
  // VERIFY IDENTITY
  // ===============================
  static Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final res = await ApiService.post(
      '/api/users/verify-identity/',
      auth: false,
      body: {
        'phone_number': phone,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
    return res != null;
  }
}