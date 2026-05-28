import 'dart:convert';

import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/session/logout_coordinator.dart';
import 'package:deligood/core/session/session_manager.dart';
import 'package:deligood/features/auth/providers/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void _log(String msg) {
  if (kDebugMode) debugPrint(msg);
}

class AuthService {
  final session = SessionManager();

  String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('225') && digits.length > 10) {
      digits = digits.substring(3);
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<bool> login({required String phone, required String pin}) async {
    final url = Uri.parse('${Api.baseUrl}/api/users/login/');
    final normalizedPhone = normalizePhone(phone);

    try {
      final res = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': normalizedPhone, 'pin': pin}),
          )
          .timeout(const Duration(seconds: 20));

      _log('LOGIN status=${res.statusCode}');

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final token =
          data['token']?.toString() ??
          data['access']?.toString() ??
          data['access_token']?.toString() ??
          data['jwt']?.toString() ??
          data['auth_token']?.toString() ??
          user['token']?.toString() ??
          '';

      if (token.isEmpty) return false;

      final userType = (user['user_type'] ?? data['user_type'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final userId =
          int.tryParse((user['id'] ?? data['user_id'])?.toString() ?? '0') ?? 0;

      await session.saveSession(
        token: token,
        userType: userType,
        userId: userId,
        firstName: user['first_name']?.toString(),
        lastName: user['last_name']?.toString(),
        phoneNumber: user['phone_number']?.toString(),
        email: user['email']?.toString(),
      );

      AuthState.instance.setAuth(token: token, userRole: userType, orderId: 0);
      return true;
    } catch (error) {
      _log('LOGIN error=$error');
      return false;
    }
  }

  Future<void> logout() => LogoutCoordinator.clearLocalSessionOnly();

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
      '/api/users/pin/reset/identity/',
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
