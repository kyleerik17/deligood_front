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

  // ✅ Sauvegarde seulement si le token n'est pas vide
  if (token.isNotEmpty) {
    await prefs.setString('access_token', token);
  }
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

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  token = null;
  userType = null;
  userId = null;
  firstName = null;
  lastName = null;
  phoneNumber = null;
  email = null;

  // ✅ Supprime seulement les clés de session, pas tout
  await prefs.remove('access_token');
  await prefs.remove('user_type');
  await prefs.remove('user_id');
  await prefs.remove('first_name');
  await prefs.remove('last_name');
  await prefs.remove('phone_number');
  await prefs.remove('email');
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

  
}