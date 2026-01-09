import 'dart:async';
import 'dart:convert';

import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatefulWidget {
  final int? orderId; // ID de la commande à suivre

  const HomeScreen({super.key, this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng clientPos = const LatLng(
    5.348,
    -4.027,
  ); // position par défaut (Abidjan)
  LatLng restaurantPos = const LatLng(5.348, -4.027);
  LatLng deliveryPos = const LatLng(5.348, -4.027);

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
      '${ApiConfig.baseUrl}/api/orders/${widget.orderId}/positions/',
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
        clientPos = LatLng(
          data['client']['lat'],
          data['client']['lng'],
        );
        deliveryPos = LatLng(
          data['livreur']['lat'],
          data['livreur']['lng'],
        );
      });
    } else {
      debugPrint('Erreur API: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Erreur fetchPositions: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60.h,
          child: FlutterMap(
            options: MapOptions(initialCenter: clientPos, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.deligood',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: clientPos,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                  Marker(
                    point: restaurantPos,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.store,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  Marker(
                    point: deliveryPos,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [deliveryPos, restaurantPos, clientPos],
                    strokeWidth: 4,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(2.h),
        Text(
          "Suivi de la commande en temps réel",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
