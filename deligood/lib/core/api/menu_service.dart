// lib/services/menu_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class MenuService {
  // 🔧 Remplace par ton URL de base
  // 🔧 Remplace l'IP par la tienne
  // Endpoints dispo :
  //   POST   /api/menu/create/
  //   GET    /api/menu/items/
  //   GET    /api/menu/items/<id>/
  //   PUT    /api/menu/update/<id>/
  //   DELETE /api/menu/delete/<id>/
  //   GET    /api/menu/mine/
  //   GET    /api/menu/categories/
  //   GET    /api/menu/category/<id>/items/
  //   GET    /api/menu/restaurants/
  static const String _baseUrl = 'http://192.168.1.X:8000/api/menu';

  /// Crée un plat via POST multipart/form-data
  static Future<Map<String, dynamic>> createMenuItem({
    required String token,
    required String name,
    required String description,
    required int price,
    required int categoryId,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final uri = Uri.parse('$_baseUrl/create/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name']        = name
      ..fields['description'] = description
      ..fields['price']       = price.toString()
      ..fields['category']    = categoryId.toString();

    // Ajout de l'image si présente
    if (imageBytes != null) {
      final fileName = imageFileName ?? 'plat.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final body             = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {'success': false, 'errors': body};
    }
  }

  /// Récupère les catégories disponibles
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Récupère les plats du restaurant connecté
  static Future<List<Map<String, dynamic>>> getMyMenus({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/mine/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}