import 'dart:async';
import 'package:deligood/core/network/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';

import '../../../services/api_service.dart';

// ========== MODELS ==========

enum WebSocketEventType {
  orderStatusChanged,
  orderAssigned,
  orderDelivered,
  locationUpdated,
}

class WebSocketEvent {
  final int orderId;
  final WebSocketEventType type;
  final String? newStatus;
  final String? message;
  final Map<String, dynamic>? eventData;

  WebSocketEvent({
    required this.orderId,
    required this.type,
    this.newStatus,
    this.message,
    this.eventData,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    WebSocketEventType eventType = WebSocketEventType.locationUpdated;
    try {
      eventType = WebSocketEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WebSocketEventType.locationUpdated,
      );
    } catch (_) {}

    return WebSocketEvent(
      orderId: json['order_id'] ?? 0,
      type: eventType,
      newStatus: json['new_status'],
      message: json['message'],
      eventData: (json['event_data'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

// ========== MAIN WIDGET ==========

class HomeScreen extends StatefulWidget {
  final int orderId;

  const HomeScreen({super.key, required this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ========== STATE VARIABLES ==========

  // Positions
  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;

  // État de l'écran
  String orderStatus = 'pending';
  bool isLoading = true;
  bool isBottomSheetExpanded = false;
  String? errorMessage;
  Map<String, dynamic>? orderData;

  // WebSocket & Tracking
  WebSocketService? _wsService;
  LocationTrackingService? _trackingService;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _trackingSubscription;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _slideUpController;

  // Map
  final MapController _mapController = MapController();

  // ========== LIFECYCLE ==========

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _safeInit();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    try {
      _wsSubscription?.cancel();
      _trackingSubscription?.cancel();
      _pulseController.dispose();
      _slideUpController.dispose();
      _wsService?.disconnect();
      _trackingService?.disconnect();
    } catch (e) {
      debugPrint('⚠️ Erreur nettoyage: $e');
    }
  }

  // ========== INITIALIZATION ==========

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _safeInit() async {
    try {
      await _fetchOrderDetails();
      await _initWebSocket();
    } catch (e) {
      debugPrint('❌ Erreur init: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur de chargement des données';
          isLoading = false;
        });
      }
    }
  }

  // ========== WEBSOCKET ==========

  Future<void> _initWebSocket() async {
    try {
      _wsService = WebSocketService();
      _trackingService = LocationTrackingService();

      // Connexion WebSocket
      await _wsService!.connect().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('WebSocket timeout'),
      );
      _wsService!.joinOrderRoom(widget.orderId);

      _wsSubscription = _wsService!.messageStream.listen(
        (data) {
          try {
            final event = WebSocketEvent.fromJson(data);
            _handleWebSocketEvent(event);
          } catch (e) {
            debugPrint('⚠️ Parsing event: $e');
          }
        },
        onError: (error) =>
            _showErrorNotification('Connexion temps réel interrompue'),
        cancelOnError: false,
      );

      // Tracking GPS
      await _trackingService!
          .connectToOrder(widget.orderId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Tracking timeout'),
          );

      _trackingSubscription = _trackingService!.locationStream.listen(
        (data) {
          try {
            if (data['type'] == 'location_update' &&
                data['user_role'] == 'livreur' &&
                data['latitude'] != null &&
                data['longitude'] != null) {
              if (mounted) {
                setState(() {
                  deliveryPos = LatLng(
                    (data['latitude'] as num).toDouble(),
                    (data['longitude'] as num).toDouble(),
                  );
                });
              }
            }
          } catch (e) {
            debugPrint('⚠️ Location update error: $e');
          }
        },
        onError: (error) => debugPrint('❌ Tracking stream error: $error'),
        cancelOnError: false,
      );

      debugPrint('✅ WebSocket initialisé pour #${widget.orderId}');
    } catch (e) {
      debugPrint('❌ WebSocket init error: $e');
      _showErrorNotification('Mode hors ligne - mise à jour limitée');
    }
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    if (event.orderId != widget.orderId) return;

    switch (event.type) {
      case WebSocketEventType.orderStatusChanged:
        if (event.newStatus != null) {
          setState(() => orderStatus = event.newStatus!);
          _showNotification(
            event.message ?? 'Statut mis à jour: ${_getStatusLabel()}',
          );
        }
        break;
      case WebSocketEventType.orderAssigned:
        setState(() => orderStatus = 'picked');
        final livreurName = event.eventData?['livreur_name'] as String?;
        _showNotification(
          livreurName != null
              ? '$livreurName va livrer votre commande'
              : 'Un livreur a pris en charge votre commande',
        );
        break;
      case WebSocketEventType.orderDelivered:
        setState(() => orderStatus = 'delivered');
        _showDeliveredDialog();
        break;
      case WebSocketEventType.locationUpdated:
        break;
    }
  }

  // ========== API CALLS ==========

  Future<void> _fetchOrderDetails() async {
    try {
      final positions = await ApiService.getOrderPositions(
        widget.orderId,
      ).timeout(const Duration(seconds: 15));

      final details = await ApiService.getOrderDetails(
        widget.orderId,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (positions['restaurant'] == null || positions['client'] == null) {
        throw Exception('Données de position incomplètes');
      }

      setState(() {
        restaurantPos = LatLng(
          (positions['restaurant']['lat'] as num).toDouble(),
          (positions['restaurant']['lng'] as num).toDouble(),
        );
        clientPos = LatLng(
          (positions['client']['lat'] as num).toDouble(),
          (positions['client']['lng'] as num).toDouble(),
        );
        if (positions['livreur'] != null) {
          deliveryPos = LatLng(
            (positions['livreur']['lat'] as num).toDouble(),
            (positions['livreur']['lng'] as num).toDouble(),
          );
        }
        orderData = details;
        orderStatus = details['status']?.toString() ?? 'pending';
        isLoading = false;
        errorMessage = null;
      });

      debugPrint('✅ Commande #${widget.orderId} chargée');
    } catch (e) {
      debugPrint('❌ Fetch order error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e is TimeoutException
              ? 'Délai de connexion dépassé'
              : 'Impossible de charger les données';
        });
      }
    }
  }

  // ========== NOTIFICATIONS ==========

  void _showNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00D9B1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(bottom: 35.h, left: 4.w, right: 4.w),
      ),
    );
  }

  void _showErrorNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        margin: EdgeInsets.only(bottom: 35.h, left: 4.w, right: 4.w),
      ),
    );
  }

  void _showDeliveredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF00D9B1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Commande livrée !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre commande a été livrée avec succès. Bon appétit ! 🎉',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9B1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  String _getStatusLabel() {
    const statusLabels = {
      'pending': 'En attente',
      'accepted': 'Acceptée',
      'preparing': 'En préparation',
      'ready': 'Prête',
      'picked': 'Prise en charge',
      'in_transit': 'En cours de livraison',
      'delivered': 'Livrée',
      'cancelled': 'Annulée',
    };
    return statusLabels[orderStatus] ?? 'En cours';
  }

  int _getCurrentStep() {
    const steps = {
      'pending': 0,
      'accepted': 0,
      'preparing': 1,
      'ready': 1,
      'picked': 2,
      'in_transit': 2,
      'delivered': 3,
    };
    return steps[orderStatus] ?? 0;
  }

  void _recenterMap() {
    final center = deliveryPos ?? restaurantPos ?? clientPos;
    if (center != null) {
      _mapController.move(center, 14.5);
      _showNotification('Carte recentrée');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    final distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return "${(meters / 1000).toStringAsFixed(1)} km";
    return "${meters.toStringAsFixed(0)} m";
  }

  String _estimateTime() {
    if (deliveryPos == null || clientPos == null) return "...";
    final distance = _calculateDistance(deliveryPos!, clientPos!);
    final minutes = (distance / 666).ceil();
    if (minutes < 1) return "< 1 min";
    if (minutes > 60) return "${(minutes / 60).floor()}h ${minutes % 60}min";
    return "$minutes min";
  }

  // ========== BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (errorMessage != null) return _buildError();
    return _buildMapScreen();
  }

  // ========== UI BUILDERS ==========

  Widget _buildLoading() => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF00D9B1),
            strokeWidth: 3,
          ),
          Gap(2.h),
          Text(
            'Chargement de votre commande...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildError() => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,

      title: const Text(
        'Suivi de commande',
        style: TextStyle(color: Colors.black),
      ),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            Gap(3.h),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(1.h),
            Text(
              'Veuillez vérifier votre connexion internet',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            Gap(4.h),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _safeInit();
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9B1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildMapScreen() {
    final mapCenter =
        deliveryPos ??
        restaurantPos ??
        clientPos ??
        const LatLng(5.3290, -4.0080);
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 14.5,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.deligood.app',
              ),
              if (restaurantPos != null &&
                  deliveryPos != null &&
                  clientPos != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [restaurantPos!, deliveryPos!, clientPos!],
                      color: const Color(0xFF00D9B1),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (clientPos != null)
                    _buildMarker(
                      clientPos!,
                      "Vous",
                      const Color(0xFF00D9B1),
                      Icons.home,
                      true,
                    ),
                  if (restaurantPos != null)
                    _buildMarker(
                      restaurantPos!,
                      "Restaurant",
                      const Color(0xFFFF6B6B),
                      Icons.restaurant,
                      false,
                    ),
                  if (deliveryPos != null) _buildDeliveryMarker(deliveryPos!),
                ],
              ),
            ],
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(
            right: 4.w,
            bottom: isBottomSheetExpanded ? 55.h : 35.h,
            child: _recenterButton(),
          ),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _topButton(Icons.arrow_back, () => Navigator.pop(context)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D9B1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gap(2.w),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _topButton(Icons.refresh, () {
              _fetchOrderDetails();
              _showNotification('Actualisation...');
            }),
          ],
        ),
      ),
    );
  }

  Widget _topButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(2.5.w),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _recenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _recenterMap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFF00D9B1),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    final currentStep = _getCurrentStep();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -5 && !isBottomSheetExpanded) {
            setState(() => isBottomSheetExpanded = true);
            _slideUpController.forward();
          } else if (details.primaryDelta! > 5 && isBottomSheetExpanded) {
            setState(() => isBottomSheetExpanded = false);
            _slideUpController.reverse();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isBottomSheetExpanded ? 90.h : 32.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Container(
                  width: 12.w,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: isBottomSheetExpanded
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Gap(2.h),
                      _buildStatusHeader(),
                      Gap(3.h),
                      _buildProgressSteps(currentStep),
                      Gap(3.h),
                      _buildDistanceInfo(),
                      if (isBottomSheetExpanded) ...[
                        Gap(3.h),
                        _buildOrderDetails(),
                        Gap(3.h),
                        _buildActionButtons(),
                        Gap(3.h),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.15).animate(_pulseController),
          child: Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9B1).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00D9B1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Gap(3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusLabel(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Commande #${widget.orderId}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9B1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _estimateTime(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00D9B1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps(int currentStep) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _progressStep(1, "Préparation", currentStep >= 1, currentStep > 1),
          Expanded(child: _stepLine(currentStep > 1)),
          _progressStep(2, "En route", currentStep >= 2, currentStep > 2),
          Expanded(child: _stepLine(currentStep > 2)),
          _progressStep(3, "Livraison", currentStep >= 3, false),
        ],
      ),
    );
  }

  Widget _progressStep(
    int number,
    String title,
    bool isActive,
    bool isCompleted,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00D9B1) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF00D9B1) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        Gap(0.8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF1A1A1A) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      color: isActive ? const Color(0xFF00D9B1) : Colors.grey.shade300,
    );
  }

  Widget _buildDistanceInfo() {
    if (deliveryPos == null || clientPos == null || restaurantPos == null)
      return const SizedBox.shrink();
    final distanceToClient = _calculateDistance(deliveryPos!, clientPos!);
    final distanceToRestaurant = _calculateDistance(
      deliveryPos!,
      restaurantPos!,
    );
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            Icons.restaurant_outlined,
            "Restaurant",
            _formatDistance(distanceToRestaurant),
            const Color(0xFFFF6B6B),
          ),
        ),
        Gap(3.w),
        Expanded(
          child: _infoCard(
            Icons.location_on_outlined,
            "Destination",
            _formatDistance(distanceToClient),
            const Color(0xFF00D9B1),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          Gap(2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (orderData == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de la commande',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Gap(1.5.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _detailRow(
                Icons.restaurant,
                'Restaurant',
                orderData!['restaurant_name']?.toString() ?? 'N/A',
              ),
              Gap(1.h),
              Divider(color: Colors.grey.shade300, height: 1),
              Gap(1.h),
              _detailRow(
                Icons.attach_money,
                'Total',
                '${orderData!['total_price'] ?? 0} FCFA',
              ),
              Gap(1.h),
              Divider(color: Colors.grey.shade300, height: 1),
              Gap(1.h),
              _detailRow(
                Icons.location_on,
                'Adresse',
                orderData!['address']?.toString() ?? 'N/A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        Gap(3.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            Icons.phone,
            'Appeler',
            () => _showNotification('Fonction appel bientôt disponible'),
            isPrimary: false,
          ),
        ),
        Gap(3.w),
        Expanded(
          child: _actionButton(
            Icons.chat_bubble_outline,
            'Message',
            () => _showNotification('Fonction message bientôt disponible'),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF00D9B1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.black,
                size: 20,
              ),
              Gap(2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _buildMarker(
    LatLng pos,
    String label,
    Color color,
    IconData icon,
    bool pulsate,
  ) {
    return Marker(
      width: 60,
      height: 60,
      point: pos,
      child: pulsate
          ? ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
              child: Icon(icon, color: color, size: 36),
            )
          : Icon(icon, color: color, size: 36),
    );
  }

  Marker _buildDeliveryMarker(LatLng pos) {
    return Marker(
      width: 60,
      height: 60,
      point: pos,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
        child: const Icon(
          Icons.delivery_dining_rounded,
          color: Colors.orange,
          size: 36,
        ),
      ),
    );
  }
}
