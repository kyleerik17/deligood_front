import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import 'package:deligood/core/session/session_manager.dart';

// ─────────────────────────────────────────────
// DESIGN SYSTEM
// ─────────────────────────────────────────────
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess = Color(0xFF4CAF50);

const String _baseUrl = 'https://deligood-backend.onrender.com';
const String kMaptilerKey = "aUpTxlfy9X9wGiCprfoR";

class HomeScreen extends StatefulWidget {
  final int? orderId;
  const HomeScreen({super.key, this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SessionManager session = SessionManager();

  late final MapController _mapController;

  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;

  bool isLoading = true;
  String? errorMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _init();
  }

  // ════════════════════════════════════════════
  // INIT
  // ════════════════════════════════════════════
  Future<void> _init() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final gps = await _getCurrentLocation();
    if (gps != null) {
      clientPos = gps;
      // Centre la carte sur la position réelle dès qu'on l'a
      _mapController.move(gps, 15);
    }

    if (widget.orderId != null && widget.orderId! > 0) {
      await _fetchPositions();
    }

    setState(() => isLoading = false);
  }

  // ════════════════════════════════════════════
  // TOKEN
  // ════════════════════════════════════════════
  Future<String?> _getToken() async {
    return await session.getToken();
  }

  // ════════════════════════════════════════════
  // GPS
  // ════════════════════════════════════════════
  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => errorMessage = "GPS désactivé");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => errorMessage = "Permission GPS refusée");
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => errorMessage = "Impossible d'obtenir la position");
      return null;
    }
  }

  // ════════════════════════════════════════════
  // API
  // ════════════════════════════════════════════
  Future<void> _fetchPositions() async {
    try {
      final token = await _getToken();

      if (token == null) {
        setState(() => errorMessage = "Session expirée");
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/orders/${widget.orderId}/positions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          restaurantPos = data['restaurant'] != null
              ? LatLng(data['restaurant']['lat'], data['restaurant']['lng'])
              : null;

          deliveryPos = data['livreur'] != null
              ? LatLng(data['livreur']['lat'], data['livreur']['lng'])
              : null;
        });
      } else {
        setState(() => errorMessage = "Erreur serveur ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Erreur réseau");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // UI
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ════ MAP ════
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(5.32, -4.01), // fallback Abidjan
              initialZoom: 15,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$kMaptilerKey",
                userAgentPackageName: "com.deligood.app",
                maxZoom: 19,
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Tile error: $error');
                },
              ),

              // Polyline trajet si positions disponibles
              if (restaurantPos != null && clientPos != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        restaurantPos!,
                        if (deliveryPos != null) deliveryPos!,
                        clientPos!,
                      ],
                      color: kOrange,
                      strokeWidth: 4,
                      borderColor: kWhite,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (clientPos != null)
                    _marker(clientPos!, Icons.my_location, kTeal),
                  if (restaurantPos != null)
                    _marker(restaurantPos!, Icons.store, kOrange),
                  if (deliveryPos != null)
                    _marker(deliveryPos!, Icons.delivery_dining, kSuccess),
                ],
              ),
            ],
          ),

          // ════ TOP BAR ════
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton refresh
                  _topBarButton(icon: Icons.refresh, onTap: _init),

                  // Titre
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: kWhite.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.orderId != null && widget.orderId! > 0
                          ? "Commande #${widget.orderId}"
                          : "Ma position",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                  ),

                  // Bouton recentrer
                  _topBarButton(
                    icon: Icons.my_location,
                    onTap: () {
                      if (clientPos != null) {
                        _mapController.move(clientPos!, 15);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ════ LOADER ════
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: kOrange),
              ),
            ),

          // ════ ERREUR ════
          if (errorMessage != null && !isLoading)
            Positioned(
              bottom: 4.h,
              left: 6.w,
              right: 6.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _init,
                      child: Text(
                        "Réessayer",
                        style: GoogleFonts.poppins(
                          color: kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════
  Widget _topBarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kWhite.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: kTextPrimary, size: 22),
      ),
    );
  }

  Marker _marker(LatLng pos, IconData icon, Color color) {
    return Marker(
      point: pos,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
        child: Container(
          decoration: BoxDecoration(
            color: kWhite,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}