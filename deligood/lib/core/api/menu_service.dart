import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static const String _baseUrl =
      'https://deligood-backend.onrender.com/api/menu';

  // ─────────────────────────────
  // CREATE MENU ITEM
  // ─────────────────────────────
  static Future<Map<String, dynamic>> createMenuItem({
    required String token,
    required String name,
    required String description,
    required int price,
    required int categoryId,
    Uint8List? imageBytes,
  }) async {
    debugPrint("🔑 TOKEN => $token");

    final uri = Uri.parse('$_baseUrl/create/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'  // ✅ Token pas Bearer
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['price'] = price.toString()
      ..fields['category'] = categoryId.toString();

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'menu.jpg',
        ),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    debugPrint("📦 RESPONSE => ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      return {"success": true, "data": data};
    } else {
      return {"success": false, "message": data.toString(), "errors": data};
    }
  }

  // ─────────────────────────────
  // CATEGORIES
  // ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. CHECK CACHE (seulement si non vide)
    final cached = prefs.getString('categories_cache');
    if (cached != null) {
      try {
        final List data = jsonDecode(cached);
        if (data.isNotEmpty) {
          debugPrint("⚡ CATEGORIES FROM CACHE => ${data.length}");
          return data.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }

    // 2. API CALL
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/'));

      debugPrint('🏷️ STATUS => ${response.statusCode}');
      debugPrint('🏷️ BODY => ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          prefs.setString('categories_cache', jsonEncode(data));
        }

        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("❌ CATEGORY ERROR => $e");
    }

    return [];
  }
}