import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? token;
  String? userType;
  int? userId;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? email;

  // ================= SAVE SESSION =================
  Future<void> saveSession({
    required String token,
    required String userType,
    required int userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    this.token = token;
    this.userType = userType;
    this.userId = userId;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phoneNumber = phoneNumber;
    this.email = email;

    await prefs.setString('access_token', token);
    await prefs.setString('user_type', userType);
    await prefs.setInt('user_id', userId);

    if (firstName != null && firstName.isNotEmpty) {
      await prefs.setString('first_name', firstName);
    }
    if (lastName != null && lastName.isNotEmpty) {
      await prefs.setString('last_name', lastName);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await prefs.setString('phone_number', phoneNumber);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString('email', email);
    }
  }

  // ================= LOAD SESSION =================
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    userType = prefs.getString('user_type');
    userId = prefs.getInt('user_id');
    firstName = prefs.getString('first_name');
    lastName = prefs.getString('last_name');
    phoneNumber = prefs.getString('phone_number');
    email = prefs.getString('email');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return "$f $l".trim();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;
    userType = null;
    userId = null;
    firstName = null;
    lastName = null;
    phoneNumber = null;
    email = null;
    await prefs.clear();
  }
}