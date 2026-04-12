import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ===================== API BASE =====================
class Api {
  Api._();

  static const String baseUrl = 'http://127.0.0.1:8000';
  static const Duration timeout = Duration(seconds: 20);

  // ===================== HEADERS =====================
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      final token = await getTokenSafe();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Token $token'; // ✅ Django TokenAuth
      }
    }

    return headers;
  }

  // ===================== RESPONSE HANDLER =====================
  static dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    debugPrint('API ERROR [$status]: ${response.body}');
    throw HttpException('Erreur serveur ($status)');
  }

  // ===================== GET =====================
  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(timeout);
    return _handleResponse(response);
  }

  // ===================== POST =====================
  static Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  // ===================== PUT =====================
  static Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .put(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  // ===================== DELETE =====================
  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(timeout);
    return _handleResponse(response);
  }

  // ===================== TOKEN SAFE =====================
  static Future<String?> getTokenSafe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  // ===================== TOKEN STRICT =====================
  static Future<String> getToken() async {
    final token = await getTokenSafe();
    if (token == null) {
      throw Exception("Utilisateur non connecté ou session expirée");
    }
    return token;
  }
}

// ===================== AUTH API =====================
class AuthApi {
  static Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Api.baseUrl}/pin/reset/identity/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'first_name': firstName,
            'last_name': lastName,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur');
    }

    final data = jsonDecode(response.body);
    return data['reset_allowed'] == true;
  }
}

// ===================== REGISTER API =====================
class AuthApiReg {
  static Future<void> register({
    required String phone,
    required String pin,
    required String firstName,
    required String lastName,
    required String locality,
    required String userType,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Api.baseUrl}/api/users/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'pin': pin, 
            'pin_confirmation': pin,
            'first_name': firstName,
            'last_name': lastName,
            'locality': locality,
            'user_type': userType,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('❌ Register error body: ${response.body}'); // ← AJOUTE ÇA
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Erreur inscription');
    }
  }
}

// ===================== LIVREUR API =====================
class LivreurApi {
  static Future<List<dynamic>> fetchCoursesDisponibles() async {
    final data = await Api.get('/api/orders/orders/livreur/available/');
    return data as List<dynamic>;
  }

  static Future<dynamic> pickupCourse(int orderId) async {
    return await Api.post('/api/orders/orders/livreur/$orderId/pickup/');
  }

  static Future<void> markOrderAsDelivered(int orderId) async {
    if (orderId <= 0) throw Exception("Commande invalide");
    await Api.post('/api/orders/orders/livreur/$orderId/deliver/');
  }

  static Future<List<dynamic>> fetchMyOrders() async {
    final data = await Api.get('/api/orders/orders/livreur/my-orders/');
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> fetchDeliveredOrders() async {
    final data = await Api.get('/api/orders/orders/livreur/delivered/');
    return data as List<dynamic>;
  }
}

// ===================== PANIER API =====================
class PanierApi {
  static Future<List<dynamic>> fetchCart() async {
    final data = await Api.get('/api/orders/cart/');
    return data as List<dynamic>;
  }

  static Future<void> removeCartItem(int cartItemId) async {
    await Api.delete('/api/orders/cart/$cartItemId/delete/');
  }

  static Future<void> clearCart() async {
    await Api.post('/api/orders/cart/clear/');
  }

  static Future<Map<String, dynamic>> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    final data = await Api.post(
      '/api/orders/orders/create/',
      body: {
        "first_name": firstName,
        "last_name": lastName,
        "locality": locality,
        "phone_number": phoneNumber,
      },
    );
    await clearCart();
    return data as Map<String, dynamic>;
  }
}

// ===================== PROFILE API =====================
class ProfileApi {
  ProfileApi._();

  static Future<Map<String, dynamic>> fetchProfile() async {
    final data = await Api.get('/api/users/profile/');
    final map = data as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', map['first_name'] ?? '');
    await prefs.setString('last_name', map['last_name'] ?? '');
    await prefs.setString('phone_number', map['phone_number'] ?? '');
    await prefs.setString('user_type', map['user_type'] ?? '');

    if (map['avatar_base64'] != null) {
      await prefs.setString('avatar_base64', map['avatar_base64']);
    }

    return map;
  }

  static Uint8List? decodeAvatar(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    return base64Decode(base64Str);
  }
}

// ===================== RESTAURANT API =====================
class RestaurantApi {
  static Future<Map<String, dynamic>> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    final data = await Api.post(
      '/api/orders/orders/create/',
      body: {
        "first_name": firstName,
        "last_name": lastName,
        "locality": locality,
        "phone_number": phoneNumber,
      },
    );
    await PanierApi.clearCart();
    return data as Map<String, dynamic>;
  }
}