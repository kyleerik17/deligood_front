import 'dart:async';
import 'dart:convert';
import 'package:deligood/core/api/livreur_api.dart';
import 'package:deligood/features/livreur/screens/course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

const String kMaptilerKey = "aUpTxlfy9X9wGiCprfoR";

const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Colors.black54;

class HomeLivreur extends StatefulWidget {
  final CourseModel? course;
  const HomeLivreur({super.key, this.course});

  @override
  State<HomeLivreur> createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  LatLng? restaurantPos;
  LatLng? clientPos;
  LatLng? livreurPos;
  int orderId = 0;
  Timer? timer;
  bool _delivered = false;
  bool _loading = true;
  bool _locationError = false; // ✅ flag si GPS refusé

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  @override
  void dispose() {
    timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Récupérer la position GPS réelle du livreur ──────
  Future<LatLng?> _getLivreurPosition() async {
    try {
      // Vérifie si le service GPS est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ GPS désactivé');
        return null;
      }

      // Vérifie / demande la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permission GPS refusée');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permission GPS refusée définitivement');
        return null;
      }

      // Récupère la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Position livreur : ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Erreur GPS : $e');
      return null;
    }
  }

  // ── Chargement de la course ───────────────────────────
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

    if (!mounted) return;

    if (course != null) {
      // ✅ Récupérer la vraie position GPS du livreur
      final gpsPos = await _getLivreurPosition();

      if (!mounted) return;

      setState(() {
        restaurantPos = course!.restaurantPos;
        clientPos = course.customerPos;
        orderId = course.id;

        if (gpsPos != null) {
          // ✅ Position réelle du livreur
          livreurPos = gpsPos;
          _locationError = false;
        } else {
          // ⚠️ Fallback : légèrement avant le restaurant
          livreurPos = LatLng(
            restaurantPos!.latitude - 0.0007,
            restaurantPos!.longitude - 0.0007,
          );
          _locationError = true;
        }

        _loading = false;
      });

      // ✅ Mise à jour GPS toutes les 5 secondes (position réelle)
      timer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final pos = await _getLivreurPosition();
        if (pos != null && mounted) {
          setState(() => livreurPos = pos);
          try {
            _mapController.move(pos, _mapController.camera.zoom);
          } catch (_) {}
        }
      });

    } else {
      setState(() => _loading = false);
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return const Distance().as(LengthUnit.Meter, start, end);
  }

  Future<void> _clearSavedCourse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_course');
  }

  Future<void> _markAsDelivered() async {
    if (orderId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande invalide', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await LivreurApi.markOrderAsDelivered(orderId);
      if (!mounted) return;

      await _clearSavedCourse();
      setState(() => _delivered = true);
      timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande livrée avec succès !',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const CoursePage(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kOrange),
              Gap(2.h),
              Text(
                'Récupération de votre position…',
                style: GoogleFonts.poppins(color: kTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (orderId == 0) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade300),
              Gap(2.h),
              Text(
                'Aucune course en cours',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
              Gap(2.h),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CoursePage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                ),
                child: Text(
                  'Voir les courses',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final distanceClient = _calculateDistance(livreurPos!, clientPos!);
    final distanceRestaurant = _calculateDistance(livreurPos!, restaurantPos!);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── AppBar ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(4.w, 5.h, 4.w, 2.h),
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
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 22),
                ),
                Text(
                  'Suivi Livreur',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
              ],
            ),
          ),

          // ✅ Bannière avertissement si GPS indisponible
          if (_locationError)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: Colors.orange, size: 18),
                  Gap(2.w),
                  Expanded(
                    child: Text(
                      'Position GPS indisponible — position approximative utilisée',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Gap(2.h),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Column(
                  children: [
                    // ── Carte ──
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 35.h,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: livreurPos!,
                              initialZoom: 16,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
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
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      restaurantPos!,
                                      livreurPos!,
                                      clientPos!,
                                    ],
                                    color: kOrange,
                                    strokeWidth: 4,
                                    borderColor: Colors.white,
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  _customMarker(restaurantPos!, 'Restaurant',
                                      Colors.orange, Icons.restaurant),
                                  _customMarker(clientPos!, 'Client',
                                      Colors.blue, Icons.person_pin_circle),
                                  _customMarker(livreurPos!, 'Vous',
                                      Colors.red, Icons.delivery_dining),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Gap(2.h),

                    // ── Étapes ──
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 1.5.h, horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stepIndicator('Restaurant', Colors.orange,
                                Icons.restaurant),
                            _lineBetween(),
                            _stepIndicator(
                                'Vous', Colors.red, Icons.delivery_dining),
                            _lineBetween(),
                            _stepIndicator('Client', Colors.blue, Icons.person),
                          ],
                        ),
                      ),
                    ),

                    Gap(2.h),

                    // ── Distances ──
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        children: [
                          _infoCard(
                            title: 'Vous → Restaurant',
                            value: _formatDistance(distanceRestaurant),
                            color: Colors.orange,
                            icon: Icons.store,
                          ),
                          Gap(1.h),
                          _infoCard(
                            title: 'Vous → Client',
                            value: _formatDistance(distanceClient),
                            color: Colors.blue,
                            icon: Icons.person,
                          ),
                        ],
                      ),
                    ),

                    Gap(2.h),

                    // ── Bouton livré ──
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _delivered ? null : _markAsDelivered,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor:
                                Colors.green.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _delivered
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              Gap(2.w),
                              Text(
                                _delivered
                                    ? 'Déjà livré'
                                    : 'Marquer comme Livré',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (livreurPos != null) {
            _mapController.move(livreurPos!, 16);
          }
        },
        backgroundColor: kOrange,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  // ── Helpers ──
  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  Marker _customMarker(
      LatLng pos, String label, Color color, IconData icon) {
    return Marker(
      point: pos,
      width: 70,
      height: 70,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
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
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, Color color, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 16),
        ),
        Gap(0.5.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _lineBetween() => Expanded(
        child: Container(
          height: 2,
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.5),
                Colors.blue.withOpacity(0.5),
              ],
            ),
          ),
        ),
      );
}