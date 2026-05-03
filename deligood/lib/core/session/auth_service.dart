
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/auth/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../session/session_manager.dart';

class AuthService {
  final session = SessionManager();

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
        final user = data['user'] as Map<String, dynamic>? ?? {};
        final token = data['token'] ?? data['access'] ?? '';
        final userType = user['user_type'] ?? '';

        await session.saveSession(
          token: token,
          userType: userType,
          userId: user['id'] ?? 0,
          firstName: user['first_name'],
          lastName: user['last_name'],
          phoneNumber: user['phone_number'],
          email: user['email'],
        );

        // ✅ On alimente AuthState ici — une seule fois, une seule source
        AuthState.instance.setAuth(
          token:    token,
          userRole: userType,
          orderId:  0, // mis à jour plus tard si nécessaire
        );

        debugPrint("✅ Session sauvegardée:");
        debugPrint("   first_name   => ${user['first_name']}");
        debugPrint("   last_name    => ${user['last_name']}");
        debugPrint("   phone_number => ${user['phone_number']}");
        debugPrint("   email        => ${user['email']}");
        debugPrint("   user_type    => $userType");
        debugPrint("   token        => $token");

        return true;
      }

      debugPrint("❌ LOGIN FAILED => ${res.body}");
      return false;
    } catch (e) {
      debugPrint("❌ LOGIN ERROR => $e");
      return false;
    }
  }

  Future<void> logout() async {
    AuthState.instance.clear(); // ✅ on vide AuthState au logout
    await session.clearSession();
  }

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