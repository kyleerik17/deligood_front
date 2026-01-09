import 'dart:async';
import 'dart:convert';
import 'package:deligood/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

class HomeRestaurant extends StatefulWidget {
  final int orderId; // Id de la commande à suivre

  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  LatLng clientPos = LatLng(0, 0);
  LatLng restaurantPos = LatLng(0, 0);
  LatLng deliveryPos = LatLng(0, 0);

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchPositions(); // récupère initialement
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
            options: MapOptions(initialCenter: restaurantPos, initialZoom: 15),
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
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  Marker(
                    point: restaurantPos,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.store, color: Colors.orange),
                  ),
                  Marker(
                    point: deliveryPos,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.local_shipping, color: Colors.red),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [deliveryPos, restaurantPos, clientPos],
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(2.h),
        Text(
          "Suivi de la commande par le restaurant",
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }
}
