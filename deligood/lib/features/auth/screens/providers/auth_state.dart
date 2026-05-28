import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  String _token = '';
  String _userRole = '';
  int _orderId = 0;

  String get token => _token;
  String get userRole => _userRole;
  int get orderId => _orderId;
  bool get isAuthenticated => _token.isNotEmpty && _userRole.isNotEmpty;

  void setAuth({
    required String token,
    required String userRole,
    required int orderId,
  }) {
    _token = token;
    _userRole = userRole.toLowerCase().trim();
    _orderId = orderId;
    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token') ?? '';
    _userRole = (prefs.getString('user_type') ?? '').toLowerCase().trim();
    _orderId = prefs.getInt('order_id') ?? prefs.getInt('last_order_id') ?? 0;
    notifyListeners();
  }

  void clear() {
    _token = '';
    _userRole = '';
    _orderId = 0;
    notifyListeners();
  }
}
