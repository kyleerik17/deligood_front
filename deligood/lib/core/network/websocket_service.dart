import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:deligood/core/network/api.dart';

/// ===== SERVICE CENTRAL WS + JWT =====
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _wsUrl;
  String? _token;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Stream<Map<String, dynamic>> get stream =>
      _messageController?.stream ?? Stream.empty();
  bool get isConnected => _isConnected;

  /// ===== INITIALISER WS =====
  Future<void> connect({String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Si un token est passé, on l'utilise, sinon on prend celui du stockage
      if (token != null) {
        _token = token;
        await prefs.setString('access_token', token);
      } else {
        _token = prefs.getString('access_token');
      }

      if (_token == null || _token!.isEmpty) {
        debugPrint('❌ WS: token manquant, impossible de se connecter');
        return;
      }

      // ⚠️ Remplace l'IP si tu es sur un vrai device
      _wsUrl = '${Api.wsBaseUrl}/ws/orders/?token=$_token';

      _messageController ??= StreamController<Map<String, dynamic>>.broadcast();

      await _connect();
    } catch (e) {
      debugPrint('❌ WS connect error: $e');
    }
  }

  Future<void> _connect() async {
    try {
      debugPrint('🔄 WS connecting with token: $_token');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ WS connecté');

      _startHeartbeat();
    } catch (e) {
      debugPrint('❌ WS connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) async {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;

      if (data['type'] == 'error' && data['code'] == 'token_expired') {
        debugPrint('⚠️ WS: Token expiré, on reconnecte');
        await _refreshTokenAndReconnect();
        return;
      }

      _messageController?.add(data);

      if (data['type'] == 'ping') {
        _channel?.sink.add(json.encode({'type': 'pong'}));
      }
    } catch (e) {
      debugPrint('❌ WS parse error: $e');
    }
  }

  void _handleError(error) {
    debugPrint('❌ WS error: $error');
    _isConnected = false;
  }

  void _handleDone() {
    debugPrint('🔌 WS disconnected');
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    debugPrint('🔄 WS reconnect in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) _channel?.sink.add(json.encode({'type': 'ping'}));
    });
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode(message));
    } else {
      debugPrint('⚠️ WS not connected, message dropped');
    }
  }

  void joinOrderRoom(int orderId) {
    send({'type': 'join_order', 'order_id': orderId});
  }

  Future<void> disconnect() async {
    debugPrint('🔌 WS disconnecting...');
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _channel?.sink.close();
    await _messageController?.close();

    _channel = null;
    _messageController = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  /// ===== Rafraîchir le token et reconnecter =====
  Future<void> _refreshTokenAndReconnect() async {
    // ⚠️ Ici tu devrais appeler ton endpoint /token/refresh/ pour récupérer un nouveau JWT
    debugPrint('🔄 Simuler refresh token...');
    // Pour test, on réutilise le token actuel
    await Future.delayed(const Duration(seconds: 1));

    await reconnect();
  }
}

/// ===== TRACKING GPS =====
class LocationTrackingManager {
  static final LocationTrackingManager _instance =
      LocationTrackingManager._internal();
  factory LocationTrackingManager() => _instance;
  LocationTrackingManager._internal();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _locationController;
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get stream =>
      _locationController?.stream ?? Stream.empty();

  Future<void> connectToOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      debugPrint('❌ GPS tracking: token manquant');
      return;
    }

    _locationController ??= StreamController<Map<String, dynamic>>.broadcast();
    final wsUrl = '${Api.wsBaseUrl}/ws/tracking/$orderId/?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (msg) {
          try {
            final data = json.decode(msg as String) as Map<String, dynamic>;
            if (data['type'] == 'error' && data['code'] == 'token_expired') {
              debugPrint('⚠️ GPS token expiré');
              disconnect();
              return;
            }
            _locationController?.add(data);
          } catch (e) {
            debugPrint('❌ GPS parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ GPS error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('🔌 GPS disconnected');
          _isConnected = false;
        },
      );

      _isConnected = true;
      debugPrint('✅ GPS connected for order $orderId');
    } catch (e) {
      debugPrint('❌ GPS connection failed: $e');
    }
  }

  void updateLocation(double lat, double lng) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(
        json.encode({
          'type': 'update_location',
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _locationController?.close();
    _channel = null;
    _locationController = null;
    _isConnected = false;
  }
}

class WebSocketService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _controller.stream;

  Future<void> connect() async {
    // init WebSocket
  }

  void joinOrderRoom(int orderId) {
    // subscribe à la room
  }

  void disconnect() {
    _controller.close();
    // ferme la connexion WebSocket
  }

  void _onMessageReceived(dynamic data) {
    _controller.add(data as Map<String, dynamic>);
  }
}

class LocationTrackingService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get locationStream => _controller.stream;

  Future<void> connectToOrder(int orderId) async {
    // init tracking live
  }

  void disconnect() {
    _controller.close();
  }

  void _onLocationUpdate(dynamic data) {
    _controller.add(data as Map<String, dynamic>);
  }
}
