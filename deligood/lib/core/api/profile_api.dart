import 'package:deligood/core/network/api.dart';
import 'package:flutter/foundation.dart';

class ProfileApi {
  ProfileApi._();

  static Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await ApiService.get('/api/users/profile/');

      if (response == null) {
        debugPrint('⚠️ ProfileApi: réponse nulle');
        return {};
      }

      if (response is! Map<String, dynamic>) {
        debugPrint('⚠️ ProfileApi: type inattendu → ${response.runtimeType}');
        return {};
      }

      debugPrint('✅ ProfileApi data: $response');
      return response;
    } catch (e) {
      debugPrint('❌ ProfileApi error: $e');
      return {};
    }
  }
}
