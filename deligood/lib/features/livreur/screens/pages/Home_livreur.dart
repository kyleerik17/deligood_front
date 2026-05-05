import 'dart:async';
import 'dart:convert';
import 'package:deligood/core/api/livreur_api.dart';
import 'package:deligood/features/livreur/course_model.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────── DESIGN SYSTEM ─────────
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kText = Color(0xFF1A1A1A);
const kSuccess = Color(0xFF4CAF50);
const kAmber = Color(0xFFFF9800);

const String kMaptilerKey = "aUpTxlfy9X9wGiCprfoR";

// ───────── MODEL ─────────
// ───────── WIDGET ─────────
class HomeLivreur extends StatefulWidget {
  final CourseModel? course;
  const HomeLivreur({super.key, this.course});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur>
    with TickerProviderStateMixin {
  LatLng? restaurantPos;
  LatLng? clientPos;
  LatLng? livreurPos;

  int orderId = 0;
  bool _loading = true;
  bool _locationError = false;
  bool _delivered = false;

  Timer? timer;
  final MapController _mapController = MapController();

  late AnimationController _pulseCtrl;

  @override
  void initState() {

    
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _loadCourse();
  }

  @override
  void dispose() {
    timer?.cancel();
    _mapController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ───────── GPS ─────────
  Future<LatLng?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  // ───────── LOAD COURSE ─────────
  Future<void> _loadCourse() async {
    CourseModel? course = widget.course;
    final prefs = await SharedPreferences.getInstance();

    if (course != null) {
      await prefs.setString('active_course', jsonEncode(course.toJson()));
    } else {
      final saved = prefs.getString('active_course');
      if (saved != null) {
        course = CourseModel.fromJson(jsonDecode(saved));
      }
    }

    if (course == null) {
      setState(() => _loading = false);
      return;
    }

    final gps = await _getPosition();

    setState(() {
      orderId = course!.id;
      restaurantPos = course.restaurantPos;
      clientPos = course.customerPos;

      if (gps != null) {
        livreurPos = gps;
      } else {
        livreurPos = LatLng(
          restaurantPos!.latitude - 0.0007,
          restaurantPos!.longitude - 0.0007,
        );
        _locationError = true;
      }

      _loading = false;
    });

    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pos = await _getPosition();
      if (pos != null && mounted) {
        setState(() => livreurPos = pos);
        _mapController.move(pos, 16);
      }
    });
  }

  // ───────── ACTION ─────────
  Future<void> _markAsDelivered() async {
    await LivreurApi.markOrderAsDelivered(orderId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_course');

    setState(() => _delivered = true);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CoursePage()),
      (route) => false,
    );
  }

  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (orderId == 0) {
      return Scaffold(
        body: Center(child: Text("Aucune course")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          if (_locationError) _gpsBanner(),
          _buildBottomCard(),
        ],
      ),
    );
  }

  // ───────── MAP ─────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: livreurPos!,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$kMaptilerKey",
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [restaurantPos!, livreurPos!, clientPos!],
              color: kOrange,
              strokeWidth: 4,
            )
          ],
        ),
        MarkerLayer(
          markers: [
            _marker(restaurantPos!, Icons.store, kOrange, "Resto"),
            _marker(clientPos!, Icons.person, kTeal, "Client"),
            _marker(livreurPos!, Icons.delivery_dining, Colors.red, "Vous"),
          ],
        )
      ],
    );
  }

  // ───────── TOP BAR ─────────
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _glassBtn(Icons.arrow_back, () => Navigator.pop(context)),
            _glassText("Commande #$orderId"),
            _glassBtn(Icons.my_location, () {
              _mapController.move(livreurPos!, 16);
            }),
          ],
        ),
      ),
    );
  }

  // ───────── BOTTOM CARD ─────────
  Widget _buildBottomCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("En livraison",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _delivered ? null : _markAsDelivered,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccess,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Marquer livré"),
            )
          ],
        ),
      ),
    );
  }

  // ───────── UI HELPERS ─────────
  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: _glassDecoration(),
        child: Icon(icon),
      ),
    );
  }

  Widget _glassText(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: _glassDecoration(),
      child: Text(text, style: GoogleFonts.poppins()),
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
    );
  }

  Widget _gpsBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.all(4.w),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text("GPS indisponible",
              style: GoogleFonts.poppins(color: Colors.orange)),
        ),
      ),
    );
  }
  

  Marker _marker(
      LatLng pos, IconData icon, Color color, String label) {
    return Marker(
      point: pos,
      width: 80,
      height: 80,
      child: Column(
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.1).animate(_pulseCtrl),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 10)),
          )
        ],
      ),
    );
  }
}