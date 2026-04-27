import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:deligood/core/session/session_manager.dart';

class LivreurApi {
  static const String baseUrl = 'https://deligood-backend.onrender.com';

  // ================= TOKEN =================
  static String? getToken() {
    return SessionManager().token;
  }

  static Map<String, String> _headers() {
    final token = getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
    };
  }

  // ================= COURSES DISPONIBLES =================
  static Future<List<dynamic>> fetchCoursesDisponibles() async {
    final url = Uri.parse('$baseUrl/api/orders/orders/livreur/available/');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Erreur fetch courses: ${res.body}');
    }
  }

  // ================= PICKUP COURSE =================
  static Future<void> pickupCourse(int orderId) async {
    final url = Uri.parse(
      '$baseUrl/api/orders/orders/livreur/$orderId/pickup/',
    );

    final res = await http.post(url, headers: _headers());

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erreur pickup course: ${res.body}');
    }
  }

  // ================= DELIVER COURSE =================
  static Future<void> markOrderAsDelivered(int orderId) async {
    final url = Uri.parse(
      '$baseUrl/api/orders/orders/livreur/$orderId/deliver/',
    );

    final res = await http.post(url, headers: _headers());

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erreur livraison: ${res.body}');
    }
  }
}
