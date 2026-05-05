import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static const String _baseUrl =
      'https://deligood-backend.onrender.com/api/menu';

  // ─────────────────────────────────────────────
  // HELPER : force HTTPS sur toutes les URLs
  // ─────────────────────────────────────────────
static String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  if (url.startsWith('http')) return url;

  if (url.contains('cloudinary')) return 'https://$url';

  return url;
}

  // ─────────────────────────────────────────────
  // CRÉER UN MENU ITEM (multipart → backend Django)
  // L'image est envoyée au backend qui la stocke
  // sur Cloudinary via cloudinary_storage
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createMenuItem({
    required String token,
    required String name,
    required String description,
    required int price,
    required int categoryId,
    Uint8List? imageBytes,
    String imageFileName = 'menu.jpg',
  }) async {
    debugPrint('🔑 TOKEN => $token');

    final uri = Uri.parse('$_baseUrl/create/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['price'] = price.toString()
      ..fields['category'] = categoryId.toString();

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName,
        ),
      );
    }

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedResponse);

      debugPrint('📦 CREATE STATUS => ${res.statusCode}');
      debugPrint('📦 CREATE BODY   => ${res.body}');

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        // ✅ Normalise l'URL image retournée par Django/Cloudinary
        if (data['image'] != null) {
          data['image'] = fixImageUrl(data['image'].toString());
        }
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data.toString(),
          'errors': data,
          'status': res.statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ createMenuItem error => $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // MODIFIER UN MENU ITEM
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateMenuItem({
    required String token,
    required int itemId,
    String? name,
    String? description,
    int? price,
    int? categoryId,
    bool? isAvailable,
    Uint8List? imageBytes,
    String imageFileName = 'menu.jpg',
  }) async {
    final uri = Uri.parse('$_baseUrl/items/$itemId/update/');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Token $token';

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (price != null) request.fields['price'] = price.toString();
    if (categoryId != null) request.fields['category'] = categoryId.toString();
    if (isAvailable != null) {
      request.fields['is_available'] = isAvailable.toString();
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName,
        ),
      );
    }

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedResponse);

      debugPrint('📦 UPDATE STATUS => ${res.statusCode}');

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (data['image'] != null) {
          data['image'] = fixImageUrl(data['image'].toString());
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data.toString(), 'errors': data};
      }
    } catch (e) {
      debugPrint('❌ updateMenuItem error => $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // SUPPRIMER UN MENU ITEM
  // ─────────────────────────────────────────────
  static Future<bool> deleteMenuItem({
    required String token,
    required int itemId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/items/$itemId/delete/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('🗑 DELETE STATUS => ${res.statusCode}');
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('❌ deleteMenuItem error => $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // RÉCUPÉRER LES ITEMS D'UN RESTAURANT
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMenuItems(
    
      int restaurantId) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/items/?restaurant_id=$restaurantId'))
          .timeout(const Duration(seconds: 15));

      debugPrint('🍽 MENU STATUS => ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawList = data is List ? data : (data['results'] ?? []);

        return (rawList as List).map<Map<String, dynamic>>((e) {
          return {
            'id': e['id'] ?? 0,
            'name': e['name'] ?? 'Produit',
            'description': e['description'] ?? '',
            'price': _parsePrice(e['price']),
            // ✅ Force HTTPS pour toutes les images Cloudinary
            'image': fixImageUrl(e['image']?.toString()) == ''
    ? 'https://via.placeholder.com/300'
    : fixImageUrl(e['image']?.toString()),
            'category': e['category'],
            'is_available': e['is_available'] ?? true,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ getMenuItems error => $e');
    }
    
    return [];

    
  }

  // ─────────────────────────────────────────────
  // CATÉGORIES avec cache SharedPreferences
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategories({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'categories_cache';
    const cacheTimeKey = 'categories_cache_time';

    // ✅ Cache valide 1h seulement (évite les données périmées)
    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isRecent = (now - cachedTime) < const Duration(hours: 1).inMilliseconds;

      if (cached != null && isRecent) {
        try {
          final List data = jsonDecode(cached);
          if (data.isNotEmpty) {
            debugPrint('⚡ CATEGORIES FROM CACHE => ${data.length}');
            return data.cast<Map<String, dynamic>>();
          }
        } catch (_) {}
      }
    }

    // API call
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories/'))
          .timeout(const Duration(seconds: 15));

      debugPrint('🏷️ CATEGORIES STATUS => ${response.statusCode}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          await prefs.setString(cacheKey, jsonEncode(data));
          await prefs.setInt(
              cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        }

        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ getCategories error => $e');
    }

    return [];
  }

  // ─────────────────────────────────────────────
  // VIDER LE CACHE CATÉGORIES
  // ─────────────────────────────────────────────
  static Future<void> clearCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('categories_cache');
    await prefs.remove('categories_cache_time');
  }

  // ─────────────────────────────────────────────
  // HELPER PRIVÉ : parser un prix en double
  // ─────────────────────────────────────────────
  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}