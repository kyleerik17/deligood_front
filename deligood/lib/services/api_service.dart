import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  // ===================== BASE URL =====================
  static const String _baseUrl = 'http://127.0.0.1:8000';
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

  // 📦 Détails d’une commande
  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final data = await get('/api/orders/orders/$orderId/');
    return data as Map<String, dynamic>;
  }

  // 📍 Positions (client / restaurant / livreur)
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
}
