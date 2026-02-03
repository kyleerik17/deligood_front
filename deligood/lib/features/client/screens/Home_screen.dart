import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final int? orderId;

  const HomeScreen({super.key, this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  LatLng clientPos = const LatLng(5.348, -4.027);
  LatLng restaurantPos = const LatLng(5.348, -4.027);
  LatLng deliveryPos = const LatLng(5.348, -4.027);

  Timer? timer;
  late AnimationController _pulseController;
  late AnimationController _slideUpController;
  
  bool isLoading = true;
  bool isBottomSheetExpanded = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    fetchPositions();
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      fetchPositions();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    _slideUpController.dispose();
    super.dispose();
  }

  Future<void> fetchPositions() async {
    if (widget.orderId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse(
        'http://127.0.0.1:8000/api/orders/${widget.orderId}/positions/',
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
          isLoading = false;
        });
      } else {
        debugPrint('Erreur API: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur fetchPositions: $e');
      setState(() => isLoading = false);
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  String _getDeliveryStatus() {
    final distToRestaurant = calculateDistance(deliveryPos, restaurantPos);
    final distToClient = calculateDistance(deliveryPos, clientPos);

    if (distToRestaurant < 50) {
      return "Récupération en cours";
    } else if (distToClient < 50) {
      return "Livraison imminente";
    } else if (distToRestaurant < distToClient) {
      return "En route vers le restaurant";
    } else {
      return "En cours de livraison";
    }
  }

  int _getCurrentStep() {
    final distToRestaurant = calculateDistance(deliveryPos, restaurantPos);
    final distToClient = calculateDistance(deliveryPos, clientPos);

    if (distToRestaurant < 50) return 1;
    if (distToRestaurant < distToClient) return 1;
    if (distToClient < 50) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final livreurDistanceToClient = calculateDistance(deliveryPos, clientPos);
    final livreurDistanceToRestaurant = calculateDistance(
      deliveryPos,
      restaurantPos,
    );

    final deliveryStatus = _getDeliveryStatus();
    final currentStep = _getCurrentStep();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            options: MapOptions(
              initialCenter: deliveryPos,
              initialZoom: 14.5,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.deligood',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [restaurantPos, deliveryPos, clientPos],
                    color: const Color(0xFF00D9B1),
                    strokeWidth: 4,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  _professionalMarker(
                    clientPos,
                    "A",
                    const Color(0xFF00D9B1),
                    isDestination: true,
                  ),
                  _professionalMarker(
                    restaurantPos,
                    "B",
                    const Color(0xFFFF6B6B),
                  ),
                  _deliveryMarker(deliveryPos),
                ],
              ),
            ],
          ),

          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _topButton(Icons.arrow_back, () {
                      Navigator.pop(context);
                    }),
                    _topButton(Icons.more_horiz, () {}),
                  ],
                ),
              ),
            ),
          ),

          // Recenter button
          Positioned(
            right: 4.w,
            bottom: isBottomSheetExpanded ? 55.h : 35.h,
            child: Container(
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
                  onTap: () {},
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: const Color(0xFF00D9B1),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
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
                    // Handle
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

                            // Status
                            Row(
                              children: [
                                ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.15)
                                      .animate(_pulseController),
                                  child: Container(
                                    padding: EdgeInsets.all(1.5.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D9B1)
                                          .withOpacity(0.15),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deliveryStatus,
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A1A1A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Gap(0.3.h),
                                      Text(
                                        "Commande #${widget.orderId ?? '---'}",
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 0.8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D9B1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _estimateTime(
                                      currentStep == 1
                                          ? livreurDistanceToRestaurant
                                          : livreurDistanceToClient,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00D9B1),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Gap(3.h),

                            // Progress steps
                            _buildProgressSteps(currentStep),

                            Gap(3.h),

                            // Distance info
                            Row(
                              children: [
                                Expanded(
                                  child: _compactInfoCard(
                                    icon: Icons.restaurant_outlined,
                                    label: "Restaurant",
                                    value: _formatDistance(
                                      livreurDistanceToRestaurant,
                                    ),
                                    color: const Color(0xFFFF6B6B),
                                  ),
                                ),
                                Gap(3.w),
                                Expanded(
                                  child: _compactInfoCard(
                                    icon: Icons.location_on_outlined,
                                    label: "Destination",
                                    value: _formatDistance(
                                      livreurDistanceToClient,
                                    ),
                                    color: const Color(0xFF00D9B1),
                                  ),
                                ),
                              ],
                            ),

                            if (isBottomSheetExpanded) ...[
                              Gap(3.h),

                              // Additional details
                              _sectionTitle("Détails de la livraison"),
                              Gap(1.5.h),

                              _detailRow(
                                Icons.person_outline,
                                "Livreur",
                                "Jean Kouassi",
                              ),
                              Gap(1.h),
                              _detailRow(
                                Icons.phone_outlined,
                                "Contact",
                                "+225 07 XX XX XX XX",
                              ),
                              Gap(1.h),
                              _detailRow(
                                Icons.delivery_dining_outlined,
                                "Véhicule",
                                "Moto - ABC 1234",
                              ),

                              Gap(3.h),

                              _sectionTitle("Adresses"),
                              Gap(1.5.h),

                              _addressCard(
                                icon: Icons.store_outlined,
                                title: "Restaurant",
                                address: "Rue du Commerce, Plateau",
                                color: const Color(0xFFFF6B6B),
                              ),
                              Gap(1.5.h),
                              _addressCard(
                                icon: Icons.home_outlined,
                                title: "Livraison",
                                address: "Avenue 7, Cocody",
                                color: const Color(0xFF00D9B1),
                              ),

                              Gap(3.h),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _actionButton(
                                      icon: Icons.phone,
                                      label: "Appeler",
                                      onTap: () {},
                                      isPrimary: false,
                                    ),
                                  ),
                                  Gap(3.w),
                                  Expanded(
                                    child: _actionButton(
                                      icon: Icons.chat_bubble_outline,
                                      label: "Message",
                                      onTap: () {},
                                      isPrimary: true,
                                    ),
                                  ),
                                ],
                              ),

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
          ),

          // Loading
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9B1)),
                  ),
                ),
              ),
            ),
        ],
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
            child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
          ),
        ),
      ),
    );
  }

  Marker _professionalMarker(
    LatLng pos,
    String label,
    Color color, {
    bool isDestination = false,
  }) {
    return Marker(
      point: pos,
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect
          if (isDestination)
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.5).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeOut,
                ),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Marker
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _deliveryMarker(LatLng pos) {
    return Marker(
      point: pos,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.delivery_dining,
          color: Colors.white,
          size: 24,
        ),
      ),
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
          _progressStep(
            number: 1,
            title: "Récupération",
            isActive: currentStep >= 1,
            isCompleted: currentStep > 1,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              color: currentStep > 1
                  ? const Color(0xFF00D9B1)
                  : Colors.grey.shade300,
            ),
          ),
          _progressStep(
            number: 2,
            title: "En route",
            isActive: currentStep >= 2,
            isCompleted: currentStep > 2,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              color: currentStep > 2
                  ? const Color(0xFF00D9B1)
                  : Colors.grey.shade300,
            ),
          ),
          _progressStep(
            number: 3,
            title: "Livraison",
            isActive: currentStep >= 3,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _progressStep({
    required int number,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00D9B1)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00D9B1)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
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
            color: isActive
                ? const Color(0xFF1A1A1A)
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _compactInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        Gap(3.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _addressCard({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Gap(3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Gap(0.3.h),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF1A1A1A),
                size: 20,
              ),
              Gap(2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.toStringAsFixed(0)} m";
  }

  String _estimateTime(double meters) {
    final minutes = (meters / 666).ceil();
    if (minutes < 1) return "< 1 min";
    if (minutes == 1) return "1 min";
    return "$minutes min";
  }
}