import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  // ===================== BASE URL =====================
  static const String _baseUrl = 'https://deligood-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 20);

  static String get baseUrl => _baseUrl;

  // ===================== HEADERS =====================
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      final token = await _getToken();
      headers[HttpHeaders.authorizationHeader] = 'Token $token';
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

    debugPrint('❌ API ERROR [$status]: ${response.body}');

    // Essaye d'extraire le message d'erreur depuis le JSON
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final msg =
            data['detail'] ?? data['message'] ?? data.values.first?.toString();
        if (msg != null) throw HttpException(msg);
      }
    } catch (e) {
      if (e is HttpException) rethrow;
    }

    throw HttpException('Erreur serveur ($status)');
  }

  // ===================== HTTP METHODS =====================
  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .put(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handleResponse(response);
  }

  // ===================== TOKEN =====================
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }

    return token;
  }

  // ===================== USER =====================
  static Future<Map<String, dynamic>> getUserInfo() async {
    final data = await get('/api/users/me/');
    return data as Map<String, dynamic>;
  }

  // ===================== ORDERS =====================
  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final data = await get('/api/orders/orders/$orderId/');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrderPositions(int orderId) async {
    final data = await get('/api/orders/orders/$orderId/positions/');
    return data as Map<String, dynamic>;
  }

  // ===================== PANIER =====================
  static Future<List<dynamic>> fetchCart() async {
    final data = await get('/api/orders/cart/');
    return data as List<dynamic>;
  }

  static Future<void> removeCartItem(int cartItemId) async {
    await delete('/api/orders/cart/$cartItemId/delete/');
  }

  static Future<void> clearCart() async {
    await post('/api/orders/cart/clear/');
  }

  static Future<Map<String, dynamic>> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    final data = await post(
      '/api/orders/orders/create/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'locality': locality,
      },
    );

    await clearCart();
    return data as Map<String, dynamic>;
  }

  // ===================== LIVREUR =====================
  static Future<List<dynamic>> fetchAvailableOrders() async {
    final data = await get('/api/orders/orders/livreur/available/');
    return data as List<dynamic>;
  }

  static Future<void> pickupOrder(int orderId) async {
    await post('/api/orders/orders/livreur/$orderId/pickup/');
  }

  static Future<void> deliverOrder(int orderId) async {
    await post('/api/orders/orders/livreur/$orderId/deliver/');
  }

  static Future<List<dynamic>> fetchMyDeliveries() async {
    final data = await get('/api/orders/orders/livreur/my-orders/');
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> fetchDeliveredOrders() async {
    final data = await get('/api/orders/orders/livreur/delivered/');
    return data as List<dynamic>;
  }

  static Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final data = await post(
      '/api/users/pin/reset/identity/',
      auth: false,
      body: {
        'phone_number': phone,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    return data['reset_allowed'] == true;
  }

  static Future<void> resetPin({
    required String phoneNumber,
    required String newPin,
    required String newPinConfirmation,
  }) async {
    await post(
      '/api/users/pin/reset/confirm/',
      auth: false,
      body: {
        'phone_number': phoneNumber,
        'new_pin': newPin,
        'new_pin_confirmation': newPinConfirmation,
      },
    );
  }
}

// ===================== REGISTER =====================
Future<void> register({
  required String phone,
  required String pin,
  required String firstName,
  required String lastName,
  required String locality,
  required String userType,
}) async {
  final response = await http
      .post(
        Uri.parse('https://deligood-backend.onrender.com/api/users/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

  debugPrint("STATUS: ${response.statusCode}");
  debugPrint("BODY: ${response.body}");

  // Protection anti HTML (réponse nginx/django non JSON)
  if (!response.body.trim().startsWith("{")) {
    throw Exception(
      "Réponse serveur invalide. Vérifie que le serveur est bien démarré.",
    );
  }

  if (response.statusCode != 200 && response.statusCode != 201) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final msg =
            data['detail'] ??
            data['message'] ??
            data.values.first?.toString() ??
            'Erreur inscription';
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    throw Exception('Erreur inscription (${response.statusCode})');
  }

  // ✅ 200 ou 201 → succès, on ne throw rien
}

// ===================== PANIER API =====================
class PanierApi {
  static Future<List<dynamic>> fetchCart() async {
    final data = await ApiService.get('/api/orders/cart/');
    return data as List<dynamic>;
  }

  static Future<void> removeCartItem(int cartItemId) async {
    await ApiService.delete('/api/orders/cart/$cartItemId/delete/');
  }

  static Future<void> clearCart() async {
    await ApiService.post('/api/orders/cart/clear/');
  }

  static Future<Map<String, dynamic>> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    final data = await ApiService.post(
      '/api/orders/orders/create/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'locality': locality,
        'phone_number': phoneNumber,
      },
    );
    await clearCart();
    return data as Map<String, dynamic>;
  }
}
