import 'package:deligood/core/network/api.dart';

class ProfileApi {
  ProfileApi._();

  static Future<Map<String, dynamic>> fetchProfile() async {
    final data = await ApiService.get('/api/users/profile/');
    return data as Map<String, dynamic>;
  }
}