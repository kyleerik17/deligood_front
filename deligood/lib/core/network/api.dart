import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  Api._(); // Empêche l'instanciation

  // ===================== BASE URL =====================
  static const String _prodBaseUrl = 'http://127.0.0.1:8000';
  static const String _devBaseUrl = 'http://127.0.0.1:8000';

  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;
  static const Duration timeout = Duration(seconds: 20);

  // ===================== HEADERS =====================
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
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
        .timeout(timeout);
    return _handleResponse(response);
  }

  // ===================== PUT =====================
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

  // ===================== GET TOKEN =====================
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Utilisateur non connecté");
    return token;
  }

  // ===================== GET USER INFO =====================
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/me/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(timeout);

    if (response.statusCode != 200)
      throw Exception("Impossible de récupérer le profil");
    return jsonDecode(response.body);
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

    if (response.statusCode != 200) throw Exception('Erreur serveur');
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
            'first_name': firstName,
            'last_name': lastName,
            'locality': locality,
            'user_type': userType,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Erreur inscription');
    }
  }
}

// ===================== LIVREUR & PANIER API =====================
class LivreurApi {
  // Marquer commande livrée
  static Future<void> markOrderAsDelivered(int orderId) async {
    if (orderId <= 0) throw Exception("Commande invalide");

    final token = await Api.getToken();
    final url = Uri.parse(
      '${Api.baseUrl}api/orders/orders/livreur/$orderId/deliver/',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      if (response.statusCode == 404) throw Exception('Commande introuvable');
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  // Récupérer le panier
  static Future<List<dynamic>> fetchCart() async {
    final token = await Api.getToken();
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/api/orders/cart/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode != 200) throw Exception("Erreur chargement panier");
    return jsonDecode(response.body);
  }

  // Supprimer un item du panier
  static Future<void> removeCartItem(int cartItemId) async {
    final token = await Api.getToken();
    final response = await http.delete(
      Uri.parse('${Api.baseUrl}/orders/cart/$cartItemId/delete/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Échec suppression article du panier");
    }
  }

  // Confirmer la commande
  static Future<void> confirmOrder({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String locality,
  }) async {
    final token = await Api.getToken();

    // Création commande
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/api/orders/orders/create/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "first_name": firstName,
        "last_name": lastName,
        "locality": locality,
        "phone_number": phoneNumber,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erreur lors de la confirmation de commande");
    }

    // Nettoyage du panier backend
    await http.post(
      Uri.parse('${Api.baseUrl}/cart/clear/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
  }
}

class ProfileApi {
  ProfileApi._();

  // ================= GET PROFIL =================
  static Future<Map<String, dynamic>> fetchProfile() async {
    final token = await Api.getToken();
    final response = await http.get(
      Uri.parse(
        '${Api.baseUrl}/api/users/profile/',
      ), // <-- à ajuster selon ton backend
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement profil');
    }

    final data = jsonDecode(response.body);
    // Sauvegarde locale
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', data['first_name'] ?? '');
    await prefs.setString('last_name', data['last_name'] ?? '');
    await prefs.setString('phone_number', data['phone_number'] ?? '');
    await prefs.setString('user_type', data['user_type'] ?? '');
    if (data['avatar_base64'] != null) {
      await prefs.setString('avatar_base64', data['avatar_base64']);
    }

    return data;
  }

  static Uint8List? decodeAvatar(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    return base64Decode(base64Str);
  }
}
