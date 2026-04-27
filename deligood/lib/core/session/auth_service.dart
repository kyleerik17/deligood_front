import 'package:deligood/core/network/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../session/session_manager.dart';

class AuthService {
  final session = SessionManager();

  // ===============================
  // NORMALISATION NUMÉRO (10 chiffres)
  // ===============================
  String normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // enlève 225 si présent
    if (digits.startsWith('225') && digits.length > 10) {
      digits = digits.substring(3);
    }

    // garde toujours 10 chiffres
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

  print("========== AUTH LOGIN DEBUG ==========");
  print("RAW PHONE        => $phone");
  print("NORMALIZED PHONE => $normalizedPhone");
  print("PIN              => $pin");

  final body = {
    'phone_number': normalizedPhone,
    'pin': pin,
  };

  print("REQUEST BODY => $body");

  try {
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print("STATUS CODE => ${res.statusCode}");
    print("RESPONSE BODY => ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      await session.saveSession(
        token: data['token'] ?? data['access'],
        userType: data['user']['user_type'],
        userId: data['user']['id'],
      );

      return true;
    }

    print("LOGIN FAILED => ${res.body}");
    return false;
  } catch (e) {
    print("LOGIN ERROR => $e");
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
