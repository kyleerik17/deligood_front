import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

class HomeRestaurant extends StatefulWidget {
  final int orderId; // ID de la commande à suivre

  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  LatLng clientPos = const LatLng(5.3290, -4.0080);
  LatLng restaurantPos = const LatLng(5.3292, -4.0082);
  LatLng deliveryPos = const LatLng(5.3288, -4.0082);

  Timer? timer;
  bool isDelivering = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId > 0) {
      fetchPositions(); // première récupération
      timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchPositions());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// ================== FETCH POSITIONS ==================
  Future<void> fetchPositions() async {
    if (widget.orderId <= 0) return;

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/orders/${widget.orderId}/positions/');
      debugPrint("🌐 Fetch positions: $url");

      final response = await http.get(url);

      debugPrint("📡 Status code fetchPositions: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          restaurantPos = LatLng(data['restaurant']['lat'], data['restaurant']['lng']);
          clientPos = LatLng(data['client']['lat'], data['client']['lng']);
          deliveryPos = LatLng(data['livreur']['lat'], data['livreur']['lng']);
        });
      } else {
        debugPrint('Erreur fetchPositions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur fetchPositions: $e');
    }
  }

  /// ================== MARK AS DELIVERED ==================
  Future<void> markAsDelivered() async {
    if (isDelivering || widget.orderId <= 0) return;

    setState(() => isDelivering = true);
    debugPrint("📦 Bouton 'Marquer livré' pressé pour orderId: ${widget.orderId}");

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/orders/orders/livreur/${widget.orderId}/deliver/');
      debugPrint("🌐 Appel API POST vers: $url");

      final response = await http.post(url);

      debugPrint("📡 Status code: ${response.statusCode}");
      debugPrint("📄 Body: ${response.body}");

      if (response.statusCode == 200) {
        timer?.cancel();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Commande livrée avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Erreur ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Livraison échouée : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isDelivering = false);
    }
  }

  /// ================== DISTANCE ==================
  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  /// ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    if (widget.orderId <= 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Suivi Livraison"),
          backgroundColor: Colors.deepOrange,
        ),
        body: const Center(
          child: Text(
            "🚫 Aucune commande sélectionnée",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final livreurDistanceToClient = calculateDistance(deliveryPos, clientPos);
    final livreurDistanceToRestaurant = calculateDistance(deliveryPos, restaurantPos);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                Text(
                  "Suivi Livraison",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),

          Gap(2.h),

          // Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: deliveryPos, initialZoom: 17),
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

          // Step Indicator
          SizedBox(
            height: 10.h,
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

          // Info distances
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                _infoCard(
                  "Livreur → Restaurant",
                  "${livreurDistanceToRestaurant.toStringAsFixed(0)} m",
                  Icons.store,
                  Colors.orange,
                ),
                Gap(1.h),
                _infoCard(
                  "Livreur → Client",
                  "${livreurDistanceToClient.toStringAsFixed(0)} m",
                  Icons.person,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "loc",
            backgroundColor: Colors.deepOrange,
            child: const Icon(Icons.my_location),
            onPressed: () {},
          ),
          Gap(1.h),
          FloatingActionButton.extended(
            heroTag: "deliver",
            backgroundColor: Colors.green,
            icon: isDelivering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              isDelivering ? "Traitement..." : "Marquer livré",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: isDelivering ? null : markAsDelivered,
          ),
        ],
      ),
    );
  }

  /// ================== WIDGETS ==================
  Marker _customMarker(LatLng pos, String label, Color color) {
    return Marker(
      point: pos,
      width: 70,
      height: 70,
      child: Column(
        children: [
          Icon(Icons.location_on, color: color, size: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          Gap(4.w),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 12, backgroundColor: color),
        Gap(0.5.h),
        Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _lineBetween() => Container(width: 5.w, height: 3, color: Colors.grey.shade300);
}
