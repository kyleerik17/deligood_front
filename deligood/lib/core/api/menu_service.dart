import 'dart:convert';
import 'dart:typed_data';

import 'package:deligood/core/network/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static String get _baseUrl => ApiService.baseUrl;

  static String fixImageUrl(String? url) => Api.resolveMediaUrl(url);

  static Future<Map<String, dynamic>> createMenuItem({
    required String token,
    required String name,
    required String description,
    required int price,
    required int categoryId,
    Uint8List? imageBytes,
    String imageFileName = 'menu.jpg',
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/menu/create/'))
          ..headers['Authorization'] = Api.authHeaderValue(token)
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
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      final data = _decodeMap(response.body);

      if (response.statusCode == 201) {
        data['image'] = fixImageUrl(
          (data['image_url'] ?? data['image'])?.toString(),
        );
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': _errorMessage(data, response.statusCode),
        'errors': data,
        'status': response.statusCode,
      };
    } catch (error) {
      debugPrint('createMenuItem error: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

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
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$_baseUrl/api/menu/update/$itemId/'),
    )..headers['Authorization'] = Api.authHeaderValue(token);

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
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      final data = _decodeMap(response.body);

      if (response.statusCode == 200) {
        data['image'] = fixImageUrl(
          (data['image_url'] ?? data['image'])?.toString(),
        );
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': _errorMessage(data, response.statusCode),
        'errors': data,
        'status': response.statusCode,
      };
    } catch (error) {
      debugPrint('updateMenuItem error: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  static Future<bool> deleteMenuItem({
    required String token,
    required int itemId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/menu/delete/$itemId/'),
            headers: {'Authorization': Api.authHeaderValue(token)},
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (error) {
      debugPrint('deleteMenuItem error: $error');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMenuItems(
    int restaurantId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/menu/items/?restaurant_id=$restaurantId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 ||
          response.body.trimLeft().startsWith('<')) {
        debugPrint('getMenuItems failed: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);
      final rawList = switch (decoded) {
        List() => decoded,
        Map() when decoded.containsKey('results') => decoded['results'],
        Map() when decoded.containsKey('items') => decoded['items'],
        Map() when decoded.containsKey('data') => decoded['data'],
        _ => <dynamic>[],
      };

      return (rawList as List)
          .whereType<Map>()
          .map<Map<String, dynamic>>((raw) {
            final item = Map<String, dynamic>.from(raw);
            return {
              'id': int.tryParse(item['id']?.toString() ?? '') ?? 0,
              'name': item['name']?.toString() ?? 'Produit',
              'description': item['description']?.toString() ?? '',
              'price': _parsePrice(item['price']),
              'image': fixImageUrl(
                (item['image_url'] ?? item['image'])?.toString(),
              ),
              'category': item['category'],
              'category_id': item['category_id'] ?? item['category'],
              'is_available': item['is_available'] ?? item['available'] ?? true,
              'restaurant_id':
                  item['restaurant_id'] ?? item['restaurant'] ?? restaurantId,
            };
          })
          .where((item) => item['id'] != 0)
          .toList();
    } catch (error, stackTrace) {
      debugPrint('getMenuItems error: $error\n$stackTrace');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCategories({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'categories_cache';
    const cacheTimeKey = 'categories_cache_time';

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isRecent =
          (now - cachedTime) < const Duration(hours: 1).inMilliseconds;

      if (cached != null && isRecent) {
        try {
          return (jsonDecode(cached) as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } catch (_) {}
      }
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/menu/categories/'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 &&
          !response.body.trimLeft().startsWith('<')) {
        final data = (jsonDecode(response.body) as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        if (data.isNotEmpty) {
          await prefs.setString(cacheKey, jsonEncode(data));
          await prefs.setInt(
            cacheTimeKey,
            DateTime.now().millisecondsSinceEpoch,
          );
        }

        return data;
      }
    } catch (error) {
      debugPrint('getCategories error: $error');
    }

    return [];
  }

  static Future<void> clearCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('categories_cache');
    await prefs.remove('categories_cache_time');
  }

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.isEmpty || body.trimLeft().startsWith('<')) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  static String _errorMessage(Map<String, dynamic> data, int statusCode) {
    return (data['detail'] ?? data['message'] ?? data['error'] ?? data)
        .toString();
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
