import 'package:deligood/core/network/api.dart';

class LivreurApi {
  static Future<List<dynamic>> fetchCoursesDisponibles() async {
    final data = await Api.get('/api/orders/livreur/available/');
    if (data is! List) {
      throw Exception(
        'Format de reponse invalide pour les courses disponibles',
      );
    }
    return data;
  }

  static Future<void> pickupCourse(int orderId) async {
    await Api.post('/api/orders/livreur/$orderId/pickup/');
  }

  static Future<void> markOrderAsDelivered(int orderId) async {
    await Api.post('/api/orders/livreur/$orderId/deliver/');
  }

  static Future<void> checkTokenValidity() async {
    await Api.get('/api/users/profile/');
  }
}
