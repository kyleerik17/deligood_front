import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
      restaurantName: json['restaurant_name'] ?? "Restaurant",
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? "PENDING",
      createdAt: DateTime.parse(json['created_at']),
      restaurantPos: LatLng(
        (json['restaurant_lat'] ?? 14.692).toDouble(),
        (json['restaurant_lng'] ?? -17.445).toDouble(),
      ),
      customerPos: LatLng(
        (json['customer_lat'] ?? 14.6937).toDouble(),
        (json['customer_lng'] ?? -17.44406).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_name': restaurantName,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'restaurant_lat': restaurantPos.latitude,
      'restaurant_lng': restaurantPos.longitude,
      'customer_lat': customerPos.latitude,
      'customer_lng': customerPos.longitude,
    };
  }
}

// ========================== PAGE ==========================
class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late Future<List<CourseModel>> _coursesFuture;
  CourseModel? selectedCourse;

  LatLng? deliveryPos; // Position dynamique du livreur
  Timer? timer; // Timer pour simuler le suivi live

  @override
  void initState() {
    super.initState();
    _coursesFuture = fetchAvailableCourses();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ========================== TOKEN ==========================
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print("TOKEN récupéré : $token");
    return token;
  }

  // ========================== FETCH COURSES ==========================
  Future<List<CourseModel>> fetchAvailableCourses() async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Vous devez être connecté pour voir les courses disponibles.",
      );
    }

    final response = await http.get(
      Uri.parse(
        'http://deligood-production.up.railway.app/orders/livreur/available/',
      ),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    print("=== DEBUG API AVAILABLE COURSES ===");
    print("Status code: ${response.statusCode}");
    print("Body: ${response.body}");
    print("===================================");

    if (response.statusCode == 200) {
      final List data = List.from(jsonDecode(response.body));
      return data.map((e) => CourseModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Token invalide ou expiré. Reconnectez-vous.");
    } else if (response.statusCode == 500) {
      throw Exception("Erreur serveur");
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }

  // ========================== BUILD ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCourse == null
              ? "Courses disponibles"
              : "Détails de la course",
        ),
        centerTitle: true,
      ),
      body: selectedCourse == null
          ? buildCourseList()
          : buildCourseDetail(selectedCourse!),
    );
  }

  // ========================== LISTE DES COURSES ==========================
  Widget buildCourseList() {
    return FutureBuilder<List<CourseModel>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Center(child: Text("Aucune course disponible"));
        }

        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return ListTile(
              leading: const Icon(Icons.delivery_dining, color: Colors.orange),
              title: Text(course.restaurantName),
              subtitle: Text("Prix total : ${course.totalPrice} FCFA"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  selectedCourse = course;
                  deliveryPos = LatLng(
                    course.restaurantPos.latitude - 0.001,
                    course.restaurantPos.longitude - 0.001,
                  );

                  // Démarre le suivi live
                  timer?.cancel();
                  timer = Timer.periodic(
                    const Duration(seconds: 2),
                    (_) => updateDeliveryPosition(course),
                  );
                });
              },
            );
          },
        );
      },
    );
  }

  // ========================== UPDATE DELIVERY ==========================
  void updateDeliveryPosition(CourseModel course) {
    if (deliveryPos == null) return;

    final distance = Distance();
    final double distToRestaurant = distance(
      deliveryPos!,
      course.restaurantPos,
    );
    final double distToCustomer = distance(deliveryPos!, course.customerPos);

    setState(() {
      const step = 5.0; // déplacement simulé en mètres

      // Si pas encore arrivé au restaurant
      if (distToRestaurant > step) {
        final newLat =
            deliveryPos!.latitude +
            (course.restaurantPos.latitude - deliveryPos!.latitude) * 0.01;
        final newLng =
            deliveryPos!.longitude +
            (course.restaurantPos.longitude - deliveryPos!.longitude) * 0.01;
        deliveryPos = LatLng(newLat, newLng);
      }
      // Sinon vers le client
      else if (distToCustomer > step) {
        final newLat =
            deliveryPos!.latitude +
            (course.customerPos.latitude - deliveryPos!.latitude) * 0.01;
        final newLng =
            deliveryPos!.longitude +
            (course.customerPos.longitude - deliveryPos!.longitude) * 0.01;
        deliveryPos = LatLng(newLat, newLng);
      }
      // Arrivé
      else {
        timer?.cancel();
      }
    });
  }

  // ========================== DÉTAIL DE LA COURSE ==========================
  Widget buildCourseDetail(CourseModel course) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: deliveryPos ?? course.restaurantPos,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.deligood',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: course.customerPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  Marker(
                    point: course.restaurantPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.store, color: Colors.orange),
                  ),
                  Marker(
                    point: deliveryPos ?? course.restaurantPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.local_shipping, color: Colors.red),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      deliveryPos ?? course.restaurantPos,
                      course.restaurantPos,
                      course.customerPos,
                    ],
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (selectedCourse == null) return;

                final token = await getAccessToken();
                if (token == null || token.isEmpty) return;

                final url = Uri.parse(
                  'http://deligood-production.up.railway.app/orders/livreur/${selectedCourse!.id}/pickup/',
                );

                try {
                  final response = await http.post(
                    url,
                    headers: {
                      'Authorization': 'Token $token',
                      'Content-Type': 'application/json',
                    },
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Commande prise !")),
                    );

                    setState(() {
                      selectedCourse = null;
                      _coursesFuture = fetchAvailableCourses();
                      timer?.cancel();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur API : ${response.statusCode}"),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
                }
              },
              child: const Text("Prendre la commande"),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              selectedCourse = null;
              timer?.cancel();
            });
          },
          child: const Text("Retour à la liste"),
        ),
      ],
    );
  }
}
