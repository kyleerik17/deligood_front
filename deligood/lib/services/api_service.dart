import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  // ===================== BASE CONFIGURATION =====================
  static const String _baseUrl = 'https://deligood-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 20);

  // ===================== HEADERS MANAGEMENT =====================
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    if (auth) {
      try {
        final token = await _getToken();
        headers[HttpHeaders.authorizationHeader] = 'Token $token';
      } catch (e) {
        debugPrint('⚠️ No token available: $e');
      }
    }

    return headers;
  }

  // ===================== TOKEN MANAGEMENT =====================
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    return token;
  }

  // ===================== RESPONSE HANDLER =====================
  static dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    debugPrint('📦 API Response [$status]: ${_truncateBody(body)}');

    // Handle empty responses
    if (body.isEmpty) {
      if (status >= 200 && status < 300) return null;
      throw HttpException('Empty response from server ($status)');
    }

    // Check if response is HTML (error page)
    if (body.trim().startsWith('<')) {
      throw HttpException('Server returned HTML instead of JSON. Endpoint might not exist or server is misconfigured.');
    }

    try {
      final data = jsonDecode(body);

      if (status >= 200 && status < 300) {
        return data;
      }

      // Extract error message
      if (data is Map) {
        final msg = data['detail'] ?? data['message'] ?? data['error'] ?? 'Unknown error';
        throw HttpException(msg is String ? msg : jsonEncode(msg));
      }

      throw HttpException('Server error ($status)');
    } on FormatException {
      throw HttpException('Invalid JSON response from server');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Failed to process response: ${e.toString()}');
    }
  }

  static String _truncateBody(String body) {
    if (body.length <= 200) return body;
    return '${body.substring(0, 200)}... (${body.length} chars total)';
  }

  // ===================== HTTP METHODS =====================
  static Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;

    try {
      debugPrint('📤 $method $uri ${auth ? '(with auth)' : ''}');
      if (body != null) debugPrint('📦 Request body: ${jsonEncode(body)}');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: await _headers(auth: auth)).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          ).timeout(_timeout);
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: await _headers(auth: auth)).timeout(_timeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      return _handleResponse(response);
    } on SocketException {
      throw HttpException('No internet connection');
    } on TimeoutException {
      throw HttpException('Request timed out after ${_timeout.inSeconds} seconds');
    } on HandshakeException {
      throw HttpException('SSL handshake failed - server might not be secure');
    } catch (e) {
      throw HttpException('Network error: ${e.toString()}');
    }
  }

  static Future<dynamic> get(String endpoint, {bool auth = true}) =>
      _request('GET', endpoint, auth: auth);

  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool auth = true}) =>
      _request('POST', endpoint, body: body, auth: auth);

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool auth = true}) =>
      _request('PUT', endpoint, body: body, auth: auth);

  static Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool auth = true}) =>
      _request('PATCH', endpoint, body: body, auth: auth);

  static Future<dynamic> delete(String endpoint, {bool auth = true}) =>
      _request('DELETE', endpoint, auth: auth);

  // ===================== AUTHENTICATION =====================
  static Future<Map<String, dynamic>> login(String phone, String pin) async {
    try {
      final response = await post(
        '/api/users/login/',
        auth: false,
        body: {
          'phone_number': phone,
          'pin': pin,
        },
      );

      if (response is Map) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response['token']);
        await prefs.setString('user_type', response['user_type']);
        await prefs.setString('first_name', response['first_name']);
        await prefs.setString('last_name', response['last_name']);
        await prefs.setString('phone_number', response['phone_number']);
        await prefs.setString('locality', response['locality'] ?? '');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Login failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    try {
      await post('/api/users/logout/');
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_type');
      await prefs.remove('first_name');
      await prefs.remove('last_name');
      await prefs.remove('phone_number');
      await prefs.remove('locality');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  // ===================== USER MANAGEMENT =====================
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final data = await get('/api/users/me/');
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to get user info: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateUserInfo({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? locality,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (locality != null) body['locality'] = locality;

      final data = await patch('/api/users/me/', body: body);
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to update user info: ${e.toString()}');
    }
  }

  static Future<void> register({
    required String phone,
    required String pin,
    required String firstName,
    required String lastName,
    required String locality,
    required String userType,
  }) async {
    try {
      await post(
        '/api/users/register/',
        auth: false,
        body: {
          'phone_number': phone,
          'pin': pin,
          'pin_confirmation': pin,
          'first_name': firstName,
          'last_name': lastName,
          'locality': locality,
          'user_type': userType,
        },
      );
    } catch (e) {
      throw HttpException('Registration failed: ${e.toString()}');
    }
  }

  static Future<bool> verifyIdentity({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final data = await post(
        '/api/users/pin/reset/identity/',
        auth: false,
        body: {
          'phone_number': phone,
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      return data['reset_allowed'] == true;
    } catch (e) {
      throw HttpException('Identity verification failed: ${e.toString()}');
    }
  }

  static Future<void> resetPin({
    required String phoneNumber,
    required String newPin,
    required String newPinConfirmation,
  }) async {
    try {
      await post(
        '/api/users/pin/reset/confirm/',
        auth: false,
        body: {
          'phone_number': phoneNumber,
          'new_pin': newPin,
          'new_pin_confirmation': newPinConfirmation,
        },
      );
    } catch (e) {
      throw HttpException('PIN reset failed: ${e.toString()}');
    }
  }

  // ===================== CART MANAGEMENT =====================
static Future<List<dynamic>> fetchCart() async {
  try {
    final data = await get('/api/orders/cart/');

    if (data == null) return [];
    if (data is List) return data;
    if (data is Map && data['results'] != null) return data['results'];

    return [];
  } catch (e) {
    throw HttpException('Failed to fetch cart: ${e.toString()}');
  }
}

  static Future<Map<String, dynamic>> addToCart(int menuItemId, int quantity) async {
    try {
      final data = await post(
        '/api/orders/cart/add/',
        body: {
          'menu_item_id': menuItemId,
          'quantity': quantity,
        },
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to add item to cart: ${e.toString()}');
    }
  }

  static Future<void> updateCartItem(int cartItemId, int quantity) async {
    try {
      await patch(
        '/api/orders/cart/$cartItemId/update/',
        body: {'quantity': quantity},
      );
    } catch (e) {
      throw HttpException('Failed to update cart item: ${e.toString()}');
    }
  }

  static Future<void> removeCartItem(int cartItemId) async {
    try {
      await delete('/api/orders/cart/$cartItemId/delete/');
    } catch (e) {
      throw HttpException('Failed to remove cart item: ${e.toString()}');
    }
  }

  static Future<void> clearCart() async {
    try {
      await post('/api/orders/cart/clear/');
    } catch (e) {
      throw HttpException('Failed to clear cart: ${e.toString()}');
    }
  }

static Future<Map<String, dynamic>> confirmOrder({
  required String firstName,
  required String lastName,
  required String phoneNumber,
  required String locality,
}) async {
  try {
    final data = await post(
      '/api/orders/create/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'locality': locality,
      },
    );

    await clearCart();
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Order confirmation failed: ${e.toString()}');
  }
}
static String imageUrl(String path) {
  return '$_baseUrl/$path';
}

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final data = await get('/api/orders/$orderId/');
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to get order details: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getOrderPositions(int orderId) async {
    try {
      final data = await get('/api/orders/$orderId/positions/');
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to get order positions: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getUserOrders() async {
    try {
      final data = await get('/api/orders/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to get user orders: ${e.toString()}');
    }
  }

  // ===================== DELIVERY MANAGEMENT =====================
  static Future<List<dynamic>> fetchAvailableOrders() async {
    try {
      final data = await get('/api/orders/livreur/available/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to fetch available orders: ${e.toString()}');
    }
  }

  static Future<void> pickupOrder(int orderId) async {
    try {
      await post('/api/orders/livreur/$orderId/pickup/');
    } catch (e) {
      throw HttpException('Failed to pickup order: ${e.toString()}');
    }
  }

  static Future<void> deliverOrder(int orderId) async {
    try {
      await post('/api/orders/livreur/$orderId/deliver/');
    } catch (e) {
      throw HttpException('Failed to mark order as delivered: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> fetchMyDeliveries() async {
    try {
      final data = await get('/api/orders/livreur/my-orders/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to fetch my deliveries: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> fetchDeliveredOrders() async {
    try {
      final data = await get('/api/orders/livreur/delivered/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to fetch delivered orders: ${e.toString()}');
    }
  }

  // ===================== RESTAURANT MANAGEMENT =====================
  static Future<List<dynamic>> fetchRestaurants() async {
    try {
      final data = await get('/api/restaurants/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to fetch restaurants: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getRestaurantDetails(int restaurantId) async {
    try {
      final data = await get('/api/restaurants/$restaurantId/');
      return data as Map<String, dynamic>;
    } catch (e) {
      throw HttpException('Failed to get restaurant details: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> fetchMenuItems(int restaurantId) async {
    try {
      final data = await get('/api/restaurants/$restaurantId/menu/');
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (e) {
      throw HttpException('Failed to fetch menu items: ${e.toString()}');
    }
  }

  // ===================== LOCATION SERVICES =====================
static Future<Map<String, dynamic>> getNearbyRestaurants({
  required double latitude,
  required double longitude,
  double radius = 5.0,
}) async {
  try {
    final uri = Uri.parse('$_baseUrl/api/restaurants/nearby/').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(_timeout);

    final data = _handleResponse(response);
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Failed to get nearby restaurants: $e');
  }
}

static Future<Map<String, dynamic>> updateDeliveryLocation({
  required int orderId,
  required double latitude,
  required double longitude,
}) async {
  try {
    final data = await patch(
      '/api/orders/livreur/$orderId/location/',
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Failed to update delivery location: ${e.toString()}');
  }
}

// ===================== NOTIFICATIONS =====================
static Future<List<dynamic>> getNotifications() async {
  try {
    final data = await get('/api/notifications/');
    if (data is List) return data;
    if (data is Map && data['results'] != null) return data['results'] as List;
    return [];
  } catch (e) {
    throw HttpException('Failed to get notifications: ${e.toString()}');
  }
}

static Future<void> markNotificationAsRead(int notificationId) async {
  try {
    await patch('/api/notifications/$notificationId/read/');
  } catch (e) {
    throw HttpException('Failed to mark notification as read: ${e.toString()}');
  }
}

// ===================== PAYMENT SERVICES =====================
static Future<Map<String, dynamic>> createPaymentIntent({
  required int orderId,
  required String paymentMethod,
  required double amount,
}) async {
  try {
    final data = await post(
      '/api/payments/create/',
      body: {
        'order_id': orderId,
        'payment_method': paymentMethod,
        'amount': amount,
      },
    );
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Failed to create payment intent: ${e.toString()}');
  }
}

static Future<Map<String, dynamic>> confirmPayment({
  required String paymentIntentId,
  required String paymentMethodId,
}) async {
  try {
    final data = await post(
      '/api/payments/confirm/',
      body: {
        'payment_intent_id': paymentIntentId,
        'payment_method_id': paymentMethodId,
      },
    );
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Failed to confirm payment: ${e.toString()}');
  }
}

// ===================== REVIEW SERVICES =====================
static Future<void> submitReview({
  required int orderId,
  required int rating,
  String? comment,
}) async {
  try {
    await post(
      '/api/reviews/',
      body: {
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      },
    );
  } catch (e) {
    throw HttpException('Failed to submit review: ${e.toString()}');
  }
}

static Future<List<dynamic>> getRestaurantReviews(int restaurantId) async {
  try {
    final data = await get('/api/restaurants/$restaurantId/reviews/');
    if (data is List) return data;
    if (data is Map && data['results'] != null) return data['results'] as List;
    return [];
  } catch (e) {
    throw HttpException('Failed to get restaurant reviews: ${e.toString()}');
  }
}

// ===================== UTILITY METHODS =====================
static Future<bool> checkApiHealth() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/health/'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 5));

    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ API health check failed: $e');
    return false;
  }
}

static Future<Map<String, dynamic>> getAppConfig() async {
  try {
    final data = await get('/api/config/', auth: false);
    return data as Map<String, dynamic>;
  } catch (e) {
    throw HttpException('Failed to get app configuration: ${e.toString()}');
  }
}

// ===================== FILE UPLOAD =====================
static Future<Map<String, dynamic>> uploadFile({
  required File file,
  required String uploadType, // 'profile', 'restaurant', 'menu_item'
  int? entityId,
}) async {
  try {
    final uri = Uri.parse('$_baseUrl/api/uploads/');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    final headers = await _headers();
    request.headers.addAll(headers);

    // Add file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
      ),
    );

    // Add fields
    request.fields['upload_type'] = uploadType;
    if (entityId != null) {
      request.fields['entity_id'] = entityId.toString();
    }

    final response = await request.send().timeout(_timeout);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    }

    throw HttpException('File upload failed: $responseBody');
  } catch (e) {
    throw HttpException('File upload error: ${e.toString()}');
  }
}

// ===================== WEBSOCKET CONNECTION =====================
static Future<WebSocket> connectToOrderUpdates(int orderId) async {
  try {
    final token = await _getToken();
    final url = '$_baseUrl/ws/orders/$orderId/?token=$token';
    final socket = await WebSocket.connect(url);

    socket.pingInterval = const Duration(seconds: 30);
    return socket;
  } catch (e) {
    throw HttpException('WebSocket connection failed: ${e.toString()}');
  }
}


// ===================== CACHE MANAGEMENT =====================
static Future<void> clearCache() async {
  try {
    await delete('/api/cache/clear/');
  } catch (e) {
    debugPrint('⚠️ Cache clearing failed: $e');
  }
}

// ===================== HELPER METHODS =====================
static Future<Map<String, dynamic>> getCurrentUserInfo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return {
      'first_name': prefs.getString('first_name') ?? '',
      'last_name': prefs.getString('last_name') ?? '',
      'phone_number': prefs.getString('phone_number') ?? '',
      'locality': prefs.getString('locality') ?? '',
      'user_type': prefs.getString('user_type') ?? '',
    };
  } catch (e) {
    throw HttpException('Failed to get current user info: ${e.toString()}');
  }
}

static Future<void> updateLocalUserInfo({
  String? firstName,
  String? lastName,
  String? phoneNumber,
  String? locality,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) await prefs.setString('first_name', firstName);
    if (lastName != null) await prefs.setString('last_name', lastName);
    if (phoneNumber != null) await prefs.setString('phone_number', phoneNumber);
    if (locality != null) await prefs.setString('locality', locality);
  } catch (e) {
    throw HttpException('Failed to update local user info: ${e.toString()}');
  }
}


}

// ===================== CUSTOM EXCEPTION =====================
class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}

