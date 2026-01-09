import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL de base de ton backend Django
  static const String baseUrl = 'http://deligood-production.up.railway.app/api';

  // Token (sera rempli après login)
  String? token;

  ApiService({this.token});

  // Méthode GET simple
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(url, headers: _buildHeaders());
    return _processResponse(response);
  }

  // Méthode POST simple
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  // Headers avec ou sans token
  Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // Traitement basique de la réponse
  dynamic _processResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      return jsonDecode(body);
    } else {
      throw Exception('Erreur API: $status, $body');
    }
  }
}
