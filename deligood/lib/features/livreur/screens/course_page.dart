import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';

// ========================== MODEL ==========================
class CourseModel {
  final int id;
  final String restaurantName;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final LatLng restaurantPos;
  final LatLng customerPos;

  CourseModel({
    required this.id,
    required this.restaurantName,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.restaurantPos,
    required this.customerPos,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      restaurantName: json['restaurant_name'] ?? 'Restaurant',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at']),
      restaurantPos: _positionFromJson(
        json['restaurant_position'],
        fallbackLat: 14.692,
        fallbackLng: -17.445,
      ),
      customerPos: _positionFromJson(
        json['client_position'],
        fallbackLat: 14.6937,
        fallbackLng: -17.44406,
      ),
    );
  }

  static LatLng _positionFromJson(
    dynamic value, {
    required double fallbackLat,
    required double fallbackLng,
  }) {
    if (value is Map) {
      final lat = double.tryParse(value['latitude']?.toString() ?? '');
      final lng = double.tryParse(value['longitude']?.toString() ?? '');
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return LatLng(fallbackLat, fallbackLng);
  }
}

// ========================== PAGE ==========================
class CoursePage extends StatefulWidget {
  final Function(CourseModel) onCourseTaken;

  const CoursePage({super.key, required this.onCourseTaken});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late Future<List<CourseModel>> coursesFuture;

  @override
  void initState() {
    super.initState();
    coursesFuture = fetchCourses();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<CourseModel>> fetchCourses() async {
    final token = await getToken();
    final url = '${Api.baseUrl}/api/orders/livreur/available/';
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': Api.authHeaderValue(token ?? '')},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CourseModel.fromJson(e)).toList();
    }
    throw Exception('Erreur chargement courses');
  }

  Future<void> takeCourse(CourseModel course) async {
    final token = await getToken();
    final url = '${Api.baseUrl}/api/orders/livreur/${course.id}/pickup/';
    final res = await http.post(
      Uri.parse(url),
      headers: {'Authorization': Api.authHeaderValue(token ?? '')},
    );

    if (res.statusCode == 200) {
      // 🔄 Recharge la liste des courses après prise
      setState(() {
        coursesFuture = fetchCourses();
      });

      widget.onCourseTaken(course);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course prise avec succès !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de prendre la course')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Courses disponibles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: FutureBuilder<List<CourseModel>>(
        future: coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur serveur'));
          }

          final courses = snapshot.data!;
          if (courses.isEmpty) {
            return const Center(child: Text('Aucune course disponible'));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            itemCount: courses.length,
            itemBuilder: (_, i) {
              final c = courses[i];
              return _CourseCardElegant(course: c, onTap: () => takeCourse(c));
            },
          );
        },
      ),
    );
  }
}

// ========================== WIDGET COURSE CARD ==========================
class _CourseCardElegant extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseCardElegant({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant,
            color: Colors.deepOrange,
            size: 28,
          ),
        ),
        title: Text(
          course.restaurantName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${course.totalPrice.toStringAsFixed(0)} FCFA • ${course.createdAt.hour.toString().padLeft(2, '0')}:${course.createdAt.minute.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
            elevation: 2,
          ),
          child: const Text(
            'Prendre',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
