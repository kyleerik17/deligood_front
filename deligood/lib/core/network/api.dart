import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  Api._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'DELIGOOD_API_BASE_URL',
  );
  static const String _configuredPaymentBaseUrl = String.fromEnvironment(
    'DELIGOOD_PAYMENT_BASE_URL',
  );
  static const String _configuredPaymentCreateEndpoint = String.fromEnvironment(
    'GENIUSPAY_PAYMENT_CREATE_ENDPOINT',
    defaultValue: '/api/finance/payments/',
  );
  static const String geniusPayApiKey = String.fromEnvironment(
    'GENIUSPAY_API_KEY',
  );
  static const String _prodBaseUrl = 'https://deligood-backend.onrender.com';
  static const String _localDesktopBaseUrl = 'http://127.0.0.1:8000';
  static const String _localAndroidBaseUrl = 'http://10.0.2.2:8000';
  static const String _cloudinaryCloudName = 'drtfvtisi';

  static String get _devBaseUrl {
    if (kIsWeb) return _localDesktopBaseUrl;
    if (Platform.isAndroid) return _localAndroidBaseUrl;
    return _localDesktopBaseUrl;
  }

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.endsWith('/')
          ? configured.substring(0, configured.length - 1)
          : configured;
    }
    return kReleaseMode ? _prodBaseUrl : _devBaseUrl;
  }

  static String get paymentBaseUrl {
    final configured = _configuredPaymentBaseUrl.trim();
    final base = configured.isNotEmpty ? configured : baseUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  static String get paymentCreateEndpoint {
    final endpoint = _configuredPaymentCreateEndpoint.trim();
    if (endpoint.isEmpty) return '/api/finance/payments/';
    return endpoint.startsWith('/') ? endpoint : '/$endpoint';
  }

  static String resolveMediaUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '';
    final embeddedHttps = value.indexOf('https://');
    if (embeddedHttps > 0) return value.substring(embeddedHttps);
    final embeddedHttp = value.indexOf('http://');
    if (embeddedHttp > 0) {
      final url = value.substring(embeddedHttp);
      return url.contains('cloudinary.com')
          ? url.replaceFirst('http://', 'https://')
          : url;
    }
    if (value.startsWith('https://')) return value;
    if (value.startsWith('http://')) {
      return value.contains('cloudinary.com')
          ? value.replaceFirst('http://', 'https://')
          : value;
    }
    if (value.startsWith('//')) return 'https:$value';
    if (value.startsWith('/')) return '$baseUrl$value';
    if (value.contains('cloudinary.com')) return 'https://$value';
    if (value.startsWith('image/upload/')) {
      return 'https://res.cloudinary.com/$_cloudinaryCloudName/$value';
    }
    return '$baseUrl/media/$value';
  }

  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri
        .replace(scheme: scheme)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static const Duration timeout = Duration(seconds: 20);

  static String authHeaderValue(String token) {
    final trimmed = token.trim();
    return trimmed.startsWith('ey') ? 'Bearer $trimmed' : 'Token $trimmed';
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      final token = await getToken();
      headers[HttpHeaders.authorizationHeader] = authHeaderValue(token);
    }

    return headers;
  }

  static Map<String, String> paymentHeaders() {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    final apiKey = geniusPayApiKey.trim();
    if (apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }

    return headers;
  }

  static Uri _uri(String endpoint) {
    return _uriForBase(baseUrl, endpoint);
  }

  static Uri paymentUri(String endpoint) {
    return _uriForBase(paymentBaseUrl, endpoint);
  }

  static Uri _uriForBase(String base, String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }

    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$normalized');
  }

  static dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    String message = 'Erreur serveur ($status)';
    if (body.isNotEmpty && !body.trimLeft().startsWith('<')) {
      try {
        final data = jsonDecode(body);
        if (data is Map) {
          message = (data['detail'] ?? data['message'] ?? data['error'] ?? data)
              .toString();
        } else {
          message = data.toString();
        }
      } catch (_) {
        message = body;
      }
    }

    debugPrint('API ERROR [$status] ${response.request?.url}: $body');
    throw HttpException(message);
  }

  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final response = await http
        .get(_uri(endpoint), headers: await _headers(auth: auth))
        .timeout(timeout);
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await http
        .post(
          _uri(endpoint),
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await http
        .put(
          _uri(endpoint),
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await http
        .patch(
          _uri(endpoint),
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final response = await http
        .delete(_uri(endpoint), headers: await _headers(auth: auth))
        .timeout(timeout);
    return _handleResponse(response);
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw const HttpException('Utilisateur non connecte');
    }
    return token;
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final response = await get('/api/users/profile/');
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      return data is Map<String, dynamic> ? data : response;
    }
    return {};
  }
}

class ApiService {
  ApiService._();

  static String get baseUrl => Api.baseUrl;

  static Future<dynamic> get(String endpoint, {bool auth = true}) {
    return Api.get(endpoint, auth: auth);
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return Api.post(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return Api.put(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return Api.patch(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) {
    return Api.delete(endpoint, auth: auth);
  }
}

class AuthApi {
  static Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final data = await Api.post(
      '/api/users/pin/reset/identity/',
      auth: false,
      body: {
        'phone_number': phone,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    return data is Map && data['reset_allowed'] == true;
  }
}

class AuthApiReg {
  static Future<void> register({
    required String phone,
    required String pin,
    required String firstName,
    required String lastName,
    required String locality,
    required String userType,
  }) async {
    await Api.post(
      '/api/users/register/',
      auth: false,
      body: {
        'phone_number': phone,
        'pin': pin,
        'pin_confirmation': pin,
        'first_name': firstName,
        'last_name': lastName,
        'locality': locality,
        'user_type': userType,
      },
    );
  }
}

class LivreurApi {
  static Future<void> markOrderAsDelivered(int orderId) async {
    if (orderId <= 0) throw Exception('Commande invalide');
    await Api.post('/api/orders/livreur/$orderId/deliver/');
  }

  static Future<List<dynamic>> fetchCart() async {
    final data = await Api.get('/api/orders/cart/');
    return data is List ? data : <dynamic>[];
  }

  static Future<void> removeCartItem(int cartItemId) async {
    await Api.delete('/api/orders/cart/$cartItemId/delete/');
  }

  static Future<void> confirmOrder({
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    required String address,
    required String phone,
  }) async {
    await Api.post(
      '/api/orders/client/create/',
      body: {
        "restaurant": restaurantId,
        "items": items,
        "address": address,
        "phone": phone,
      },
    );
  }
}

class ProfileApi {
  ProfileApi._();

  static Future<Map<String, dynamic>> fetchProfile() async {
    final data = await Api.getUserInfo();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', data['first_name']?.toString() ?? '');
    await prefs.setString('last_name', data['last_name']?.toString() ?? '');
    await prefs.setString(
      'phone_number',
      data['phone_number']?.toString() ?? '',
    );
    await prefs.setString('user_type', data['user_type']?.toString() ?? '');

    return data;
  }

  static Uint8List? decodeAvatar(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    return base64Decode(base64Str);
  }
}
