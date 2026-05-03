import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/auth/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../session/session_manager.dart';

// ── Logger silencieux en production ──
void _log(String msg) {
  if (kDebugMode) print(msg);
}

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
    _log('========== AUTH LOGIN ==========');
    _log('📱 PHONE → $normalizedPhone');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': normalizedPhone, 'pin': pin}),
      );

      _log('📡 STATUS → ${res.statusCode}');
      _log('🎫 RESPONSE → ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        _log('🗝 RESPONSE KEYS → ${data.keys.toList()}');

        final user = data['user'] as Map<String, dynamic>? ?? {};

        // ✅ Cherche le token dans tous les champs possibles
        final token = data['token']?.toString() ??
            data['access']?.toString() ??
            data['access_token']?.toString() ??
            data['jwt']?.toString() ??
            data['auth_token']?.toString() ??
            user['token']?.toString() ??
            '';

        _log('🔑 TOKEN → ${token.isEmpty ? "VIDE ❌" : "OUI (${token.length} chars)"}');

        if (token.isEmpty) {
          _log('❌ AUCUN TOKEN — champs disponibles : ${data.keys.toList()}');
          return false;
        }

        final userType = user['user_type']?.toString() ??
            data['user_type']?.toString() ??
            '';

        final userId = int.tryParse(
              (user['id'] ?? data['user_id'])?.toString() ?? '0',
            ) ?? 0;

        await session.saveSession(
          token: token,
          userType: userType,
          userId: userId,
          firstName: user['first_name']?.toString(),
          lastName: user['last_name']?.toString(),
          phoneNumber: user['phone_number']?.toString(),
          email: user['email']?.toString(),
        );

        AuthState.instance.setAuth(
          token: token,
          userRole: userType,
          orderId: 0,
        );

        _log('✅ SESSION SAUVEGARDÉE → type=$userType | userId=$userId');
        return true;
      }

      _log('❌ LOGIN FAILED → ${res.statusCode} | ${res.body}');
      return false;
    } catch (e) {
      _log('❌ LOGIN ERROR → $e');
      return false;
    }
  }

  Future<void> logout() async {
    AuthState.instance.clear();
    await session.clearSession();
    _log('🚪 Logout effectué');
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