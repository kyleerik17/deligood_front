import 'dart:async';
import 'dart:convert';

import 'package:deligood/core/network/api.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

class HomeRestaurant extends StatefulWidget {
  final int orderId;
  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  // Positions autour du Plateau à Abidjan, 30m entre elles
  LatLng clientPos = LatLng(5.3290, -4.0080);
  LatLng restaurantPos = LatLng(5.3292, -4.0082);
  LatLng deliveryPos = LatLng(5.3288, -4.0082);

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchPositions();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchPositions());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPositions() async {
    try {
      final url = Uri.parse(
        '${Api.baseUrl}/api/orders/${widget.orderId}/positions/',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          restaurantPos = LatLng(
            data['restaurant']['lat'],
            data['restaurant']['lng'],
          );
          clientPos = LatLng(data['client']['lat'], data['client']['lng']);
          deliveryPos = LatLng(data['livreur']['lat'], data['livreur']['lng']);
        });
      }
    } catch (e) {
      debugPrint('Erreur fetchPositions: $e');
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  @override
  Widget build(BuildContext context) {
    final livreurDistanceToClient = calculateDistance(deliveryPos, clientPos);
    final livreurDistanceToRestaurant = calculateDistance(
      deliveryPos,
      restaurantPos,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
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
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 32,
                ),
                Text(
                  "Suivi Livraison",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white, size: 32),
              ],
            ),
          ),

          Gap(2.h),

          // Carte réduite + immersive
          SizedBox(
            height: 35.h,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: deliveryPos,
                initialZoom: 18,
                maxZoom: 20,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.deligood',
                ),
                MarkerLayer(
                  markers: [
                    _customMarker(clientPos, "Client", Colors.blue),
                    _customMarker(restaurantPos, "Restaurant", Colors.orange),
                    _customMarker(deliveryPos, "Livreur", Colors.red),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [restaurantPos, deliveryPos, clientPos],
                      color: Colors.deepOrangeAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Gap(2.h),

          // Timeline style design UI
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

          // Info Cards flottantes avec effet glass
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                _infoCard(
                  title: "Distance livreur → restaurant",
                  value: "${livreurDistanceToRestaurant.toStringAsFixed(0)} m",
                  color: Colors.orange,
                  icon: Icons.store,
                ),
                Gap(1.h),
                _infoCard(
                  title: "Distance livreur → client",
                  value: "${livreurDistanceToClient.toStringAsFixed(0)} m",
                  color: Colors.blue,
                  icon: Icons.person,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Recentre sur le livreur
        },
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

  Widget _stepIndicator(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 12, backgroundColor: color),
        Gap(1.h / 2),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _lineBetween() {
    return Container(width: 5.w, height: 3, color: Colors.grey.shade300);
  }
}
