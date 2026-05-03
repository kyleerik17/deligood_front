import 'dart:convert';
import 'package:deligood/core/api/livreur_api.dart';
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange        = Color(0xFFFF6B35);
const kBg            = Color(0xFFF7F3EF);
const kWhite         = Colors.white;
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess       = Color(0xFF4CAF50);
const kError         = Color(0xFFFF5A5F);

// ========================== MODEL ==========================
class CourseModel {
  final int      id;
  final String   restaurantName;
  final double   totalPrice;
  final String   status;
  final DateTime createdAt;
  final LatLng   restaurantPos;
  final LatLng   customerPos;

  CourseModel({
    required this.id,
    required this.restaurantName,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.restaurantPos,
    required this.customerPos,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id:             json['id'],
      restaurantName: json['restaurant_name'] ?? 'Restaurant',
      totalPrice:     double.tryParse(json['total_price'].toString()) ?? 0.0,
      status:         json['status'] ?? 'PENDING',
      createdAt:      DateTime.parse(json['created_at']),
      restaurantPos:  LatLng(
        (json['restaurant_lat'] ?? 14.692).toDouble(),
        (json['restaurant_lng'] ?? -17.445).toDouble(),
      ),
      customerPos: LatLng(
        (json['customer_lat'] ?? 14.6937).toDouble(),
        (json['customer_lng'] ?? -17.44406).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':              id,
        'restaurant_name': restaurantName,
        'total_price':     totalPrice,
        'status':          status,
        'created_at':      createdAt.toIso8601String(),
        'restaurant_lat':  restaurantPos.latitude,
        'restaurant_lng':  restaurantPos.longitude,
        'customer_lat':    customerPos.latitude,
        'customer_lng':    customerPos.longitude,
      };
}

// ========================== PAGE ==========================
class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage>
    with SingleTickerProviderStateMixin {
  List<CourseModel> _courses      = [];
  bool              _isLoading    = true;
  bool              _isTaking     = false;
  String?           _errorMessage;
  CourseModel?      _activeCourse;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Init ─────────────────────────────────────────────
  Future<void> _init() async {
    // 1. Vérifier le token
    try {
      await LivreurApi.getToken(); // ✅ corrigé : plus de double ()()
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      });
      return;
    }

    // 2. Charger la course active depuis le stockage local
    await _loadActiveCourse();

    // 3. Si une course est déjà en cours → rediriger directement vers HomeLivreur
    if (_activeCourse != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeLivreur(course: _activeCourse),
        ),
      );
      return; // ✅ Stop ici, pas besoin de charger la liste
    }

    // 4. Sinon, charger la liste des courses disponibles
    await _fetchCourses();
  }

  // ── Charger la course sauvegardée localement ─────────
  Future<void> _loadActiveCourse() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_course');
    if (saved != null && mounted) {
      setState(() => _activeCourse = CourseModel.fromJson(jsonDecode(saved)));
    }
  }

  // ── Sauvegarder la course active localement ──────────
  Future<void> _saveCourse(CourseModel course) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_course', jsonEncode(course.toJson()));
  }

  // ── Fetch les courses disponibles ────────────────────
  Future<void> _fetchCourses() async {
    if (!mounted) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final data = await LivreurApi.fetchCoursesDisponibles();
      if (!mounted) return;
      setState(() {
        _courses   = data.map((e) => CourseModel.fromJson(e)).toList();
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isLoading    = false;
        _errorMessage = msg.contains('401')
            ? 'Session expirée. Veuillez vous reconnecter.'
            : msg.contains('timeout') || msg.contains('SocketException')
                ? 'Pas de connexion réseau. Réessayez.'
                : 'Erreur serveur. Réessayez.';
      });
    }
  }

  // ── Prendre une course ───────────────────────────────
  Future<void> _takeCourse(CourseModel course) async {
    if (_isTaking) return;

    if (_activeCourse != null) {
      _showSnackBar('Vous avez déjà une course en cours !', isError: true);
      return;
    }

    setState(() => _isTaking = true);

    try {
      // 1. Appel API
      await LivreurApi.pickupCourse(course.id);
      if (!mounted) return;

      // 2. Sauvegarder en local (persist jusqu'à livraison)
      await _saveCourse(course);

      // 3. Mettre à jour l'état local
      setState(() {
        _isTaking     = false;
        _activeCourse = course;
      });

      _showSnackBar('Course prise avec succès !', isError: false);

      // 4. Courte pause pour que le snackbar soit visible
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      // 5. Navigation vers HomeLivreur avec transition slide
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeLivreur(course: course),
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isTaking = false);

      final msg = e.toString();

      _showSnackBar(
        msg.contains('400')
            ? 'Cette course a déjà été prise par un autre livreur.'
            : msg.contains('timeout') || msg.contains('SocketException')
                ? 'Pas de connexion réseau.'
                : 'Impossible de prendre la course.',
        isError: true,
      );

      // Rafraîchir la liste si la course n'est plus disponible
      if (msg.contains('400')) {
        await _fetchCourses();
      }
    }
  }

  // ── SnackBar ─────────────────────────────────────────
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: kWhite,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 13, color: kWhite),
            ),
          ),
        ]),
        backgroundColor: isError ? kError : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Courses disponibles',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: GestureDetector(
              onTap: _fetchCourses,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: kTextPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner course active ──
          if (_activeCourse != null)
            _ActiveCourseBar(
              course: _activeCourse!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeLivreur(course: _activeCourse),
                ),
              ),
            ),

          // ── Contenu ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_courses.isEmpty) return _buildEmpty();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchCourses,
        color: kOrange,
        backgroundColor: kWhite,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          itemCount: _courses.length,
          itemBuilder: (_, i) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + i * 70),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - v)),
                child: child,
              ),
            ),
            child: _CourseCard(
              course: _courses[i],
              onTap: () => _takeCourse(_courses[i]),
              isLoading: _isTaking,
              isBlocked: _activeCourse != null,
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: kOrange, strokeWidth: 2.5),
          SizedBox(height: 2.h),
          Text(
            'Chargement des courses…',
            style: GoogleFonts.poppins(fontSize: 12.sp, color: kTextSecondary),
          ),
        ]),
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kError.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: kError, size: 44),
            ),
            SizedBox(height: 2.h),
            Text(
              'Oups !',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.5.h),
            SizedBox(
              width: double.infinity,
              height: 5.5.h,
              child: ElevatedButton(
                onPressed: _fetchCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, color: kWhite, size: 18),
                    SizedBox(width: 2.w),
                    Text(
                      'Réessayer',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: kWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kOrange.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_bike_rounded,
              color: kOrange, size: 52),
        ),
        SizedBox(height: 2.5.h),
        Text(
          'Aucune course disponible',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        SizedBox(height: 0.8.h),
        Text(
          'Tirez vers le bas pour recharger',
          style: GoogleFonts.poppins(fontSize: 11.sp, color: kTextSecondary),
        ),
      ]),
    );
  }
}

// ========================== BANNER COURSE ACTIVE ==========================
class _ActiveCourseBar extends StatelessWidget {
  final CourseModel  course;
  final VoidCallback onTap;

  const _ActiveCourseBar({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 5.w),
        decoration: BoxDecoration(
          color: kSuccess,
          boxShadow: [
            BoxShadow(
              color: kSuccess.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bike_rounded,
                  color: kWhite, size: 22),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course en cours',
                    style: GoogleFonts.poppins(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    course.restaurantName,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Voir',
                  style: GoogleFonts.poppins(
                    color: kWhite,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: kWhite, size: 12),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================== CARD COURSE ==========================
class _CourseCard extends StatelessWidget {
  final CourseModel  course;
  final VoidCallback onTap;
  final bool         isLoading;
  final bool         isBlocked;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.isLoading,
    required this.isBlocked,
  });

  String get _time =>
      '${course.createdAt.hour.toString().padLeft(2, '0')}:${course.createdAt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isLoading || isBlocked) ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // ── Icône restaurant ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: kOrange, size: 26),
                ),

                SizedBox(width: 3.w),

                // ── Infos ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.restaurantName,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(children: [
                        // Prix pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kOrange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${course.totalPrice.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: kOrange,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        // Heure
                        Text(
                          '• $_time',
                          style: GoogleFonts.poppins(
                              fontSize: 10.sp, color: kTextSecondary),
                        ),
                      ]),
                    ],
                  ),
                ),

                SizedBox(width: 2.w),

                // ── Bouton prendre ──
                SizedBox(
                  height: 5.h,
                  child: ElevatedButton(
                    onPressed: (isLoading || isBlocked) ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kWhite,
                            ),
                          )
                        : Text(
                            'Prendre',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: kWhite,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}