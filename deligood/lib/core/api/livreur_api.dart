import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:deligood/core/session/session_manager.dart';

class LivreurApi {
  static const String baseUrl = 'https://deligood-backend.onrender.com';

  static String? getToken() => SessionManager().token;

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (getToken()?.isNotEmpty ?? false) 'Authorization': 'Token ${getToken()}',
  };

  static Future<http.Response> _get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: _headers());
  }

  static Future<http.Response> _post(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: _headers());
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      return body.isEmpty ? null : jsonDecode(body);
    }

    final errorData = body.isNotEmpty ? jsonDecode(body) : {};
    final errorMessage = errorData['detail'] ?? errorData['message'] ?? body;

    throw Exception('[$statusCode] $errorMessage');
  }

  static Future<List<dynamic>> fetchCoursesDisponibles() async {
    final response = await _get('/api/orders/orders/livreur/available/');
    final data = _handleResponse(response);

    if (data is! List) {
      throw Exception('Format de réponse invalide pour les courses disponibles');
    }

    return data;
  }

  static Future<void> pickupCourse(int orderId) async {
    final response = await _post('/api/orders/orders/livreur/$orderId/pickup/');
    _handleResponse(response);
  }

  static Future<void> markOrderAsDelivered(int orderId) async {
    final response = await _post('/api/orders/orders/livreur/$orderId/deliver/');
    _handleResponse(response);
  }

  static Future<void> checkTokenValidity() async {
    try {
      await _get('/api/auth/verify-token/');
    } catch (e) {
      SessionManager().clearSession();
      throw Exception('Session expirée');
    }
  }
}