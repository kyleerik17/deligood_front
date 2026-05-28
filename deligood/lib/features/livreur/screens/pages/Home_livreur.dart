import 'dart:async';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

class HomeLivreur extends StatefulWidget {
  final CourseModel? course;

  const HomeLivreur({super.key, this.course});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  late LatLng restaurantPos;
  late LatLng clientPos;
  late LatLng livreurPos;
  late int orderId;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    if (widget.course != null) {
      restaurantPos = widget.course!.restaurantPos;
      clientPos = widget.course!.customerPos;
      orderId = widget.course!.id;
    } else {
      restaurantPos = LatLng(5.3292, -4.0082);
      clientPos = LatLng(5.3290, -4.0080);
      orderId = 0;
    }

    livreurPos = LatLng(
      restaurantPos.latitude - 0.0007,
      restaurantPos.longitude - 0.0007,
    );

    timer = Timer.periodic(const Duration(seconds: 2), (_) => moveLivreur());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void moveLivreur() {
    if (orderId == 0) return;
    setState(() {
      livreurPos = LatLng(
        livreurPos.latitude + (clientPos.latitude - livreurPos.latitude) * 0.12,
        livreurPos.longitude +
            (clientPos.longitude - livreurPos.longitude) * 0.12,
      );
    });
  }

  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  Future<void> markAsDelivered() async {
    if (orderId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Commande invalide")));
      return;
    }

    try {
      await LivreurApi.markOrderAsDelivered(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande livrée avec succès !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderId == 0) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Text(
            "Aucune course sélectionnée",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final livreurDistanceToClient = calculateDistance(livreurPos, clientPos);
    final livreurDistanceToRestaurant = calculateDistance(
      livreurPos,
      restaurantPos,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // AppBar Gradient
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
                const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 32,
                ),
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
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 35.h,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: livreurPos,
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
                          _customMarker(clientPos, "Client", Colors.blue),
                          _customMarker(
                            restaurantPos,
                            "Restaurant",
                            Colors.orange,
                          ),
                          _customMarker(livreurPos, "Livreur", Colors.red),
                        ],
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [restaurantPos, livreurPos, clientPos],
                            color: Colors.deepOrangeAccent,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap(2.h),
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: ElevatedButton(
                    onPressed: markAsDelivered,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        Gap(2.w),
                        Text(
                          "Marquer comme Livré",
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
              ],
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
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
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
