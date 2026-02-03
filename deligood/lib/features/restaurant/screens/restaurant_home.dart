import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeRestaurant extends StatefulWidget {
  final int orderId;

  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;

  Timer? timer;
  String errorMessage = '';
  bool isLoading = true;
  String deliveryStatus = 'En cours';

  @override
  void initState() {
    super.initState();
    if (widget.orderId > 0) {
      fetchPositions();
      timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => fetchPositions(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPositions() async {
    if (widget.orderId <= 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      if (token.isEmpty) {
        setState(() {
          errorMessage = 'Token manquant. Veuillez vous reconnecter.';
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        'http://127.0.0.1:8000/api/orders/${widget.orderId}/positions/',
      );

      final response = await http.get(url, headers: {
        'Authorization': token.startsWith('ey') ? 'Bearer $token' : 'Token $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          // Récupération des positions
          if (data['restaurant'] != null) {
            restaurantPos = LatLng(
              double.parse(data['restaurant']['lat'].toString()),
              double.parse(data['restaurant']['lng'].toString()),
            );
          }

          if (data['client'] != null) {
            clientPos = LatLng(
              double.parse(data['client']['lat'].toString()),
              double.parse(data['client']['lng'].toString()),
            );
          }

          if (data['livreur'] != null) {
            deliveryPos = LatLng(
              double.parse(data['livreur']['lat'].toString()),
              double.parse(data['livreur']['lng'].toString()),
            );
          }

          // Statut de la livraison
          deliveryStatus = data['status'] ?? 'En cours';

          errorMessage = '';
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Non autorisé. Token invalide.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur réseau: $e';
        isLoading = false;
      });
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId <= 0) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Suivi Livraison"),
          backgroundColor: const Color(0xFF00CCBC),
        ),
        body: const Center(
          child: Text(
            "🚫 Aucune commande sélectionnée",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF00CCBC),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Chargement de la livraison...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final livreurDistanceToClient = deliveryPos != null && clientPos != null
        ? calculateDistance(deliveryPos!, clientPos!)
        : 0.0;
    final livreurDistanceToRestaurant =
        deliveryPos != null && restaurantPos != null
            ? calculateDistance(deliveryPos!, restaurantPos!)
            : 0.0;

    // Centre de la carte
    final mapCenter = deliveryPos ?? restaurantPos ?? clientPos ?? const LatLng(5.3290, -4.0080);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header moderne
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00CCBC), Color(0xFF00A896)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00CCBC).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "Suivi en direct",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deliveryStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF5A5F),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Color(0xFFFF5A5F),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Carte
          Expanded(
            child: restaurantPos != null || clientPos != null || deliveryPos != null
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 15,
                      minZoom: 10,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.deligood',
                      ),
                      MarkerLayer(
                        markers: [
                          if (clientPos != null)
                            _customMarker(
                              clientPos!,
                              "Client",
                              const Color(0xFF4A90E2),
                              Icons.person_pin_circle_rounded,
                            ),
                          if (restaurantPos != null)
                            _customMarker(
                              restaurantPos!,
                              "Restaurant",
                              const Color(0xFF00CCBC),
                              Icons.restaurant_rounded,
                            ),
                          if (deliveryPos != null)
                            _customMarker(
                              deliveryPos!,
                              "Livreur",
                              const Color(0xFFFF9800),
                              Icons.delivery_dining_rounded,
                            ),
                        ],
                      ),
                      if (restaurantPos != null &&
                          deliveryPos != null &&
                          clientPos != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [restaurantPos!, deliveryPos!, clientPos!],
                              color: const Color(0xFF00CCBC),
                              strokeWidth: 4,
                              borderStrokeWidth: 8,
                              borderColor: const Color(0xFF00CCBC).withOpacity(0.3),
                            ),
                          ],
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.location_off_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Positions non disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Info distances
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Step tracker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stepIndicator(
                        "Restaurant",
                        const Color(0xFF00CCBC),
                        livreurDistanceToRestaurant <= 50,
                        Icons.restaurant_rounded,
                      ),
                      _stepLine(livreurDistanceToRestaurant <= 50),
                      _stepIndicator(
                        "En route",
                        const Color(0xFFFF9800),
                        livreurDistanceToClient > 50,
                        Icons.local_shipping_rounded,
                      ),
                      _stepLine(livreurDistanceToClient <= 50),
                      _stepIndicator(
                        "Livré",
                        const Color(0xFF4CAF50),
                        livreurDistanceToClient <= 50,
                        Icons.check_circle_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Cards distance
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          "Au restaurant",
                          "${livreurDistanceToRestaurant.toStringAsFixed(0)} m",
                          Icons.restaurant_rounded,
                          const Color(0xFF00CCBC),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          "Chez vous",
                          "${livreurDistanceToClient.toStringAsFixed(0)} m",
                          Icons.home_rounded,
                          const Color(0xFF4A90E2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _customMarker(LatLng pos, String label, Color color, IconData icon) {
    return Marker(
      point: pos,
      width: 80,
      height: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, Color color, bool completed, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: completed ? color : color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: completed ? Colors.white : color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: completed ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool completed) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFF00CCBC)
              : const Color(0xFF00CCBC).withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}