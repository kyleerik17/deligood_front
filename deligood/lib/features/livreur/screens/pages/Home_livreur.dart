import 'dart:async';
import 'package:deligood/core/api.dart';
import 'package:deligood/features/pages/course_page.dart';
import 'package:deligood/widgets/CustomAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http show post;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ========================== HOME LIVREUR (MAP + POSITION) ==========================
class HomeLivreur extends StatefulWidget {
  final CourseModel course;
  const HomeLivreur({super.key, required this.course});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  late LatLng deliveryPos;
  late LatLng restaurantPos;
  late LatLng customerPos;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    restaurantPos = widget.course.restaurantPos;
    customerPos = widget.course.customerPos;
    deliveryPos = LatLng(
      restaurantPos.latitude - 0.001,
      restaurantPos.longitude - 0.001,
    );

    // Sauvegarde la course en cours pour rester visible
    saveCurrentCourse(widget.course);

    timer = Timer.periodic(const Duration(seconds: 2), (_) => updatePosition());
  }

  void updatePosition() {
    setState(() {
      const step = 0.0005;
      double latDiff = customerPos.latitude - deliveryPos.latitude;
      double lngDiff = customerPos.longitude - deliveryPos.longitude;

      if (latDiff.abs() < step && lngDiff.abs() < step) {
        timer?.cancel();
        deliveryPos = customerPos;
      } else {
        deliveryPos = LatLng(
          deliveryPos.latitude + latDiff * 0.1,
          deliveryPos.longitude + lngDiff * 0.1,
        );
      }
    });
  }

  Future<void> saveCurrentCourse(CourseModel course) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_course_id', course.id);
    await prefs.setDouble(
      'current_course_rest_lat',
      course.restaurantPos.latitude,
    );
    await prefs.setDouble(
      'current_course_rest_lng',
      course.restaurantPos.longitude,
    );
    await prefs.setDouble(
      'current_course_cust_lat',
      course.customerPos.latitude,
    );
    await prefs.setDouble(
      'current_course_cust_lng',
      course.customerPos.longitude,
    );
    await prefs.setString('current_course_rest_name', course.restaurantName);
    await prefs.setDouble('current_course_total_price', course.totalPrice);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: FlutterMap(
        options: MapOptions(initialCenter: deliveryPos, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.deligood',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: customerPos,
                width: 40,
                height: 40,
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              Marker(
                point: restaurantPos,
                width: 40,
                height: 40,
                child: const Icon(Icons.store, color: Colors.orange),
              ),
              Marker(
                point: deliveryPos,
                width: 40,
                height: 40,
                child: const Icon(Icons.local_shipping, color: Colors.red),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [deliveryPos, restaurantPos, customerPos],
                color: Colors.red,
                strokeWidth: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================== HOME LIVREUR WRAPPER ==========================
class HomeLivreurWrapper extends StatefulWidget {
  const HomeLivreurWrapper({super.key});

  @override
  State<HomeLivreurWrapper> createState() => _HomeLivreurWrapperState();
}

class _HomeLivreurWrapperState extends State<HomeLivreurWrapper> {
  CourseModel? currentCourse;

  @override
  void initState() {
    super.initState();
    loadCurrentCourse();
  }

  Future<void> loadCurrentCourse() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('current_course_id');
    if (id == null) return;

    setState(() {
      currentCourse = CourseModel(
        id: id,
        restaurantName:
            prefs.getString('current_course_rest_name') ?? "Restaurant",
        totalPrice: prefs.getDouble('current_course_total_price') ?? 0.0,
        status: "PENDING",
        createdAt: DateTime.now(),
        restaurantPos: LatLng(
          prefs.getDouble('current_course_rest_lat') ?? 14.692,
          prefs.getDouble('current_course_rest_lng') ?? -17.445,
        ),
        customerPos: LatLng(
          prefs.getDouble('current_course_cust_lat') ?? 14.6937,
          prefs.getDouble('current_course_cust_lng') ?? -17.44406,
        ),
      );
    });
  }

  Future<void> removeCurrentCourse() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('current_course_id');
    prefs.remove('current_course_rest_lat');
    prefs.remove('current_course_rest_lng');
    prefs.remove('current_course_cust_lat');
    prefs.remove('current_course_cust_lng');
    prefs.remove('current_course_rest_name');
    prefs.remove('current_course_total_price');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(),
        Expanded(
          child: currentCourse == null
              ? const Center(
                  child: Text(
                    "Aucune course sélectionnée",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: HomeLivreur(course: currentCourse!)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () async {
                            final token = await SharedPreferences.getInstance()
                                .then(
                                  (prefs) => prefs.getString('access_token'),
                                );
                            if (token == null || token.isEmpty) return;

                           final url = Uri.parse(
  '${ApiConfig.baseUrl}/api/orders/livreur/${currentCourse!.id}/delivered/',
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
                                  const SnackBar(
                                    content: Text("Commande livrée !"),
                                  ),
                                );

                                // Supprime la course actuelle
                                await removeCurrentCourse();
                                setState(() {
                                  currentCourse = null;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Erreur API : ${response.statusCode}",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erreur : $e")),
                              );
                            }
                          },
                          child: const Text("Livré !"),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
