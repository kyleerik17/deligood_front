import 'package:deligood/core/network/api.dart' as network;

class ApiService {
  String? token;

  ApiService({this.token});

  static String get baseUrl => network.Api.baseUrl;

  static Future<dynamic> get(String endpoint, {bool auth = true}) {
    return network.Api.get(endpoint, auth: auth);
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return network.Api.post(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return network.Api.put(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return network.Api.patch(endpoint, body: body, auth: auth);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) {
    return network.Api.delete(endpoint, auth: auth);
  }

  Future<dynamic> requestGet(String endpoint) => get(endpoint);

  Future<dynamic> requestPost(String endpoint, Map<String, dynamic> data) {
    return post(endpoint, body: data);
  }

  static Future<void> submitReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    // Le backend DeliGood actuel n'expose pas encore d'endpoint avis.
    // On garde l'action non bloquante pour ne pas casser le parcours client.
    return;
  }
}
