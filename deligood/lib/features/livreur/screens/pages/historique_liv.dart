import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:deligood/features/pages/course_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<CourseModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistory();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<CourseModel>> fetchHistory() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Vous devez être connecté");
    }

    final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/api/orders/livreur/history/'),
  headers: {
    'Authorization': 'Token $token',
    'Content-Type': 'application/json',
  },
);


    if (response.statusCode == 200) {
      final List data = List.from(jsonDecode(response.body));
      return data.map((e) => CourseModel.fromJson(e)).toList();
    } else {
      throw Exception("Erreur API : ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historique des courses")),
      body: FutureBuilder<List<CourseModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(
              child: Text("Aucune course livrée pour le moment"),
            );
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(course.restaurantName),
                subtitle: Text(
                  "Prix total : ${course.totalPrice} FCFA\n${course.createdAt.toLocal()}",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
