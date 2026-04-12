import 'dart:async';
import 'dart:convert';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

class HomeLivreur extends StatefulWidget {
  final CourseModel? course;

  const HomeLivreur({super.key, this.course});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  LatLng? restaurantPos;
  LatLng? clientPos;
  LatLng? livreurPos;
  int orderId = 0;
  Timer? timer;
  bool _delivered = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  // ✅ Charger la course depuis le paramètre OU depuis SharedPreferences
  Future<void> _loadCourse() async {
    CourseModel? course = widget.course;

    // Si rien passé en paramètre, on cherche dans SharedPreferences
    if (course == null) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('active_course');
      if (saved != null) {
        course = CourseModel.fromJson(jsonDecode(saved));
      }
    }

    if (!mounted) return;

    if (course != null) {
      setState(() {
        restaurantPos = course!.restaurantPos;
        clientPos = course.customerPos;
        orderId = course.id;
        livreurPos = LatLng(
          restaurantPos!.latitude - 0.0007,
          restaurantPos!.longitude - 0.0007,
        );
        _loading = false;
      });

      // Démarrer le timer après avoir chargé la course
      timer = Timer.periodic(const Duration(seconds: 2), (_) => moveLivreur());
    } else {
      // Aucune course trouvée
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void moveLivreur() {
    if (orderId == 0 || _delivered || livreurPos == null || clientPos == null) {
      return;
    }
    setState(() {
      livreurPos = LatLng(
        livreurPos!.latitude +
            (clientPos!.latitude - livreurPos!.latitude) * 0.12,
        livreurPos!.longitude +
            (clientPos!.longitude - livreurPos!.longitude) * 0.12,
      );
    });
  }

  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  // ✅ Supprimer la course sauvegardée après livraison
  Future<void> clearSavedCourse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_course');
  }

  Future<void> markAsDelivered() async {
    if (orderId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Commande invalide")),
      );
      return;
    }

    try {
      await LivreurApi.markOrderAsDelivered(orderId);
      if (!mounted) return;

      // ✅ Supprimer la course de SharedPreferences après livraison
      await clearSavedCourse();

      setState(() {
        _delivered = true;
      });
      timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande livrée avec succès !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loader tant qu'on attend la lecture de SharedPreferences
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Aucune course trouvée ni en paramètre ni en SharedPreferences
    if (orderId == 0) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Text(
            "Aucune course en cours",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final livreurDistanceToClient =
        calculateDistance(livreurPos!, clientPos!);
    final livreurDistanceToRestaurant =
        calculateDistance(livreurPos!, restaurantPos!);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // ======================== AppBar Gradient ========================
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.delivery_dining, color: Colors.white, size: 32),
                Text(
                  "Suivi Livreur",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white, size: 32),
              ],
            ),
          ),
          Gap(2.h),

          // ======================== Contenu principal ========================
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Column(
                  children: [
                    // ============ MAP ============
                    SizedBox(
                      height: 35.h,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: livreurPos!,
                          initialZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.example.deligood',
                          ),
                          MarkerLayer(
                            markers: [
                              _customMarker(
                                  restaurantPos!, "Restaurant", Colors.orange),
                              _customMarker(clientPos!, "Client", Colors.blue),
                              _customMarker(livreurPos!, "Livreur", Colors.red),
                            ],
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [restaurantPos!, livreurPos!, clientPos!],
                                color: Colors.deepOrangeAccent,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Gap(2.h),

                    // ============ INDICATEUR D'ÉTAPES ============
                    SizedBox(
                      height: 8.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stepIndicator("Restaurant", Colors.orange),
                          _lineBetween(),
                          _stepIndicator("Livreur", Colors.red),
                          _lineBetween(),
                          _stepIndicator("Client", Colors.blue),
                        ],
                      ),
                    ),
                    Gap(2.h),

                    // ============ CARTES DE DISTANCE ============
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        children: [
                          _infoCard(
                            title: "Distance livreur → restaurant",
                            value:
                                "${livreurDistanceToRestaurant.toStringAsFixed(0)} m",
                            color: Colors.orange,
                            icon: Icons.store,
                          ),
                          Gap(1.h),
                          _infoCard(
                            title: "Distance livreur → client",
                            value:
                                "${livreurDistanceToClient.toStringAsFixed(0)} m",
                            color: Colors.blue,
                            icon: Icons.person,
                          ),
                        ],
                      ),
                    ),
                    Gap(2.h),

                    // ============ BOUTON MARQUER COMME LIVRÉ ============
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _delivered ? null : markAsDelivered,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor:
                                Colors.green.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _delivered
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              Gap(2.w),
                              Text(
                                _delivered
                                    ? "Déjà livré"
                                    : "Marquer comme Livré",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // ======================== WIDGETS RÉUTILISABLES ========================

  Marker _customMarker(LatLng pos, String label, Color color) {
    return Marker(
      point: pos,
      width: 60,
      height: 60,
      child: Column(
        children: [
          Icon(Icons.location_on, color: color, size: 38),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Gap(4.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, Color color) => Column(
        children: [
          CircleAvatar(radius: 12, backgroundColor: color),
          Gap(1.h / 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ],
      );

  Widget _lineBetween() =>
      Container(width: 5.w, height: 3, color: Colors.grey.shade300);
}