import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../session/session_manager.dart';

class ApiService {
  ApiService._();

  static const String baseUrl = 'http://127.0.0.1:8000';
  static const Duration _timeout = Duration(seconds: 20);

  // ================= HEADERS =================
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      final token = await SessionManager().getToken();

      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Token $token';
      }
    }

    return headers;
  }

  // ================= RESPONSE =================
  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    debugPrint("API ERROR ${response.statusCode} : ${response.body}");
    throw HttpException("Erreur API ${response.statusCode}");
  }

  static Future get(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final res = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handle(res);
  }

  static Future post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final res = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);

    return _handle(res);
  }

  static Future put(String endpoint,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final res = await http
        .put(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);

    return _handle(res);
  }

  static Future delete(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final res = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);

    return _handle(res);
  }
}