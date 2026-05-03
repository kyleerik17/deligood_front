import 'dart:convert';
import 'dart:io';

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

// ─────────────────────────────────────────────
// MODEL commande (récupérée depuis l'API)
// ─────────────────────────────────────────────
class OrderInfo {
  final int id;
  final String status;
  final double totalPrice;
  final String restaurantName;
  final String locality;
  final String clientName;
  final String clientPhone;
  final LatLng? restaurantPosition;
  final LatLng? clientPosition;
  final String? deliveryName;

  OrderInfo({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.restaurantName,
    required this.locality,
    required this.clientName,
    required this.clientPhone,
    this.restaurantPosition,
    this.clientPosition,
    this.deliveryName,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'PENDING',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      restaurantName: json['restaurant']?['name'] ?? 'Restaurant',
      locality: json['locality'] ?? '',
      clientName: json['client']?['name'] ?? 'Client',
      clientPhone: json['client']?['phone'] ?? '',
      deliveryName: json['delivery']?['name'],
      restaurantPosition: json['restaurant']?['position'] != null
          ? LatLng(
              json['restaurant']['position']['lat'],
              json['restaurant']['position']['lng'],
            )
          : null,
      clientPosition: json['client']?['position'] != null
          ? LatLng(
              json['client']['position']['lat'],
              json['client']['position']['lng'],
            )
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'ACCEPTED':
        return 'Acceptée';
      case 'PREPARING':
        return 'En préparation';
      case 'ON_THE_WAY':
        return 'En livraison';
      case 'DELIVERED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return kTeal;
      case 'PREPARING':
        return Colors.blue;
      case 'ON_THE_WAY':
        return kOrange;
      case 'DELIVERED':
        return kSuccess;
      case 'CANCELLED':
        return Colors.red;
      default:
        return kTextSecondary;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'ACCEPTED':
        return Icons.thumb_up_rounded;
      case 'PREPARING':
        return Icons.restaurant_rounded;
      case 'ON_THE_WAY':
        return Icons.delivery_dining_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
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
  OrderInfo? orderInfo;
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_slideController);

    _init();
  }

  Future<void> _init() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // 1. Position GPS du client
    final gps = await _getCurrentLocation();
    if (gps != null) {
      clientPos = gps;
      try {
        _mapController.move(gps, 15);
      } catch (_) {}
    }

    // 2. Données commande + positions si orderId fourni
    if (widget.orderId != null && widget.orderId! > 0) {
      await _fetchOrderInfo();
      if (restaurantPos == null || deliveryPos == null) {
        await _fetchPositions();
      }
    }

    setState(() => isLoading = false);

    // 3. Animer le panneau commande
    if (orderInfo != null) {
      _slideController.forward();
    }
  }

  Future<String?> _getToken() => session.getToken();

  Future<LatLng?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => errorMessage = 'GPS désactivé');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => errorMessage = 'Permission GPS refusée');
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      setState(() => errorMessage = "Impossible d'obtenir la position");
      return null;
    }
  }

  Future<void> _fetchOrderInfo() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/orders/${widget.orderId}/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint("📦 Order data received: $data");

        setState(() {
          orderInfo = OrderInfo.fromJson(data);

          // Mettre à jour les positions si disponibles dans les données
          if (orderInfo?.restaurantPosition != null) {
            restaurantPos = orderInfo!.restaurantPosition;
          }
          if (orderInfo?.clientPosition != null) {
            clientPos = orderInfo!.clientPosition;
          }
        });
      } else {
        setState(() => errorMessage = 'Erreur serveur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchOrderInfo: $e');
      setState(() => errorMessage = 'Erreur lors du chargement de la commande');
    }
  }

  Future<void> _fetchPositions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => errorMessage = 'Session expirée');
        return;
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/${widget.orderId}/positions/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint("📍 Positions received: $data");

        setState(() {
          restaurantPos = data['restaurant'] != null
              ? LatLng(data['restaurant']['lat'], data['restaurant']['lng'])
              : null;
          deliveryPos = data['livreur'] != null
              ? LatLng(data['livreur']['lat'], data['livreur']['lng'])
              : null;
        });
      } else {
        setState(() => errorMessage = 'Erreur serveur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchPositions: $e');
      setState(() => errorMessage = 'Erreur réseau');
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders/$orderId/cancel/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _showSnackBar('Commande annulée avec succès');
        _init();
      } else {
        _showSnackBar('Échec de l\'annulation: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'annulation');
      debugPrint('❌ cancelOrder: $e');
    }
  }

  void _contactRestaurant() {
    // Implémentez la logique pour contacter le restaurant
    if (orderInfo?.clientPhone.isNotEmpty ?? false) {
      _showSnackBar('Appel vers ${orderInfo!.clientPhone}');
    } else {
      _showSnackBar('Numéro de téléphone non disponible');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: kOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ════ MAP ════
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: clientPos ?? const LatLng(5.32, -4.01),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$kMaptilerKey',
                userAgentPackageName: 'com.deligood.app',
                maxZoom: 19,
                errorTileCallback: (tile, error, _) =>
                    debugPrint('Tile error: $error'),
              ),

              // Polyline
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

              // Markers
              MarkerLayer(
                markers: [
                  if (clientPos != null)
                    _marker(
                      clientPos!,
                      Icons.my_location,
                      kTeal,
                      orderInfo?.clientName ?? 'Vous',
                    ),
                  if (restaurantPos != null)
                    _marker(
                      restaurantPos!,
                      Icons.store,
                      kOrange,
                      orderInfo?.restaurantName ?? 'Restaurant',
                    ),
                  if (deliveryPos != null)
                    _marker(
                      deliveryPos!,
                      Icons.delivery_dining,
                      kSuccess,
                      orderInfo?.deliveryName ?? 'Livreur',
                    ),
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
                  _topBarButton(icon: Icons.refresh, onTap: _init),
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
                          ? 'Commande #${widget.orderId}'
                          : 'Ma position',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
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

          // ════ PANNEAU COMMANDE (slide depuis le bas) ════
          if (orderInfo != null && !isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: _orderPanel(orderInfo!),
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
          if (errorMessage != null && !isLoading && orderInfo == null)
            Positioned(
              bottom: 4.h,
              left: 6.w,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
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
                        'Réessayer',
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

  Widget _orderPanel(OrderInfo order) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
      decoration: const BoxDecoration(
          color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Titre + statut ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commande #${order.id}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    order.restaurantName,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
              // Badge statut
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: order.statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(order.statusIcon, color: order.statusColor, size: 14),
                    SizedBox(width: 1.w),
                    Text(
                      order.statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: order.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
          Divider(color: Colors.grey.shade100, thickness: 1),
          SizedBox(height: 1.5.h),

          // ── Informations client ──
          Row(
            children: [
              Expanded(
                child: _detailChip(
                  icon: Icons.person,
                  label: order.clientName,
                  color: kTeal,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _detailChip(
                  icon: Icons.phone,
                  label: order.clientPhone,
                  color: kTeal,
                  onTap: _contactRestaurant,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.5.h),

          // ── Détails commande ──
          Row(
            children: [
              Expanded(
                child: _detailChip(
                  icon: Icons.location_on_rounded,
                  label: order.locality,
                  color: kOrange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _detailChip(
                  icon: Icons.payments_rounded,
                  label: '${order.totalPrice.toStringAsFixed(0)} FCFA',
                  color: kSuccess,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // ── Boutons d'action ──
          if (order.status == 'PENDING')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelOrder(order.id),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contactRestaurant,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(
                      'Appeler',
                      style: GoogleFonts.poppins(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange.withOpacity(0.1),
                      foregroundColor: kOrange,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // ── Message d'attente si PENDING ──
          if (order.status == 'PENDING')
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'En attente de confirmation par le restaurant…',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Message livraison ──
          if (order.status == 'ON_THE_WAY')
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining_rounded,
                      color: kOrange,
                      size: 22,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Votre ${order.deliveryName != null ? '${order.deliveryName} est' : 'livreur est'} en route !',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: kOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Message livré ──
          if (order.status == 'DELIVERED')
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kSuccess.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: kSuccess,
                      size: 22,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Commande livrée avec succès !',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: kSuccess,
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

  Widget _detailChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 1.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 1.w),
              Icon(Icons.call, color: color, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kWhite.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: kTextPrimary, size: 22),
      ),
    );
  }

  Marker _marker(LatLng pos, IconData icon, Color color, String label) {
    return Marker(
      point: pos,
      width: 80,
      height: 80,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
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
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: kWhite,
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
              style: GoogleFonts.poppins(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}