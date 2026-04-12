import 'dart:convert';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/livreur/screens/pages/Home_livreur.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// ========================== MODEL ==========================
class CourseModel {
  final int id;
  final String restaurantName;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final LatLng restaurantPos;
  final LatLng customerPos;

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
      id: json['id'],
      restaurantName: json['restaurant_name'] ?? 'Restaurant',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at']),
      restaurantPos: LatLng(
        (json['restaurant_lat'] ?? 14.692).toDouble(),
        (json['restaurant_lng'] ?? -17.445).toDouble(),
      ),
      customerPos: LatLng(
        (json['customer_lat'] ?? 14.6937).toDouble(),
        (json['customer_lng'] ?? -17.44406).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_name': restaurantName,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'restaurant_lat': restaurantPos.latitude,
      'restaurant_lng': restaurantPos.longitude,
      'customer_lat': customerPos.latitude,
      'customer_lng': customerPos.longitude,
    };
  }
}

// ========================== PAGE ==========================
class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  bool _isTaking = false;
  String? _errorMessage;
  CourseModel? _activeCourse;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Vérifier token
    try {
      await Api.getToken();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      });
      return;
    }

    // Charger course active depuis SharedPreferences
    await _loadActiveCourse();

    // Charger la liste
    await _fetchCourses();
  }

  Future<void> _loadActiveCourse() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_course');
    if (saved != null && mounted) {
      setState(() {
        _activeCourse = CourseModel.fromJson(jsonDecode(saved));
      });
    }
  }

  // ✅ Utilise LivreurApi au lieu de http.get manuel
  Future<void> _fetchCourses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await LivreurApi.fetchCoursesDisponibles();
      if (!mounted) return;
      setState(() {
        _courses = data.map((e) => CourseModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isLoading = false;
        _errorMessage = msg.contains('401')
            ? 'Session expirée. Veuillez vous reconnecter.'
            : msg.contains('timeout') || msg.contains('SocketException')
                ? 'Pas de connexion réseau. Réessayez.'
                : 'Erreur serveur. Réessayez.';
      });
    }
  }

  Future<void> _saveCourse(CourseModel course) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_course', jsonEncode(course.toJson()));
  }

  // ✅ Utilise LivreurApi.pickupCourse() au lieu de http.post manuel
  Future<void> _takeCourse(CourseModel course) async {
    if (_isTaking) return;

    if (_activeCourse != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vous avez déjà une course en cours !'),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() {
      _isTaking = true;
    });

    try {
      await LivreurApi.pickupCourse(course.id);
      if (!mounted) return;

      await _saveCourse(course);

      setState(() {
        _isTaking = false;
        _activeCourse = course;
      });

      await _fetchCourses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course prise avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(milliseconds: 800),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeLivreur(course: course),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTaking = false;
      });

      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('400')
                ? 'Cette course a déjà été prise par un autre livreur.'
                : msg.contains('timeout') || msg.contains('SocketException')
                    ? 'Pas de connexion réseau.'
                    : 'Impossible de prendre la course.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      // Recharger la liste si la course a été prise par un autre
      if (msg.contains('400')) await _fetchCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Courses disponibles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner course en cours
          if (_activeCourse != null)
            _ActiveCourseBar(
              course: _activeCourse!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeLivreur(course: _activeCourse),
                  ),
                );
              },
            ),

          // Contenu
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _fetchCourses);
    }

    if (_courses.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: _fetchCourses,
      color: Colors.deepOrange,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        itemCount: _courses.length,
        itemBuilder: (_, i) {
          final c = _courses[i];
          return _CourseCardElegant(
            course: c,
            onTap: () => _takeCourse(c),
            isLoading: _isTaking,
            isBlocked: _activeCourse != null,
          );
        },
      ),
    );
  }
}

// ========================== BANNER COURSE EN COURS ==========================
class _ActiveCourseBar extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _ActiveCourseBar({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bike, color: Colors.white, size: 24),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Course en cours",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      course.restaurantName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ========================== VUE ERREUR ==========================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            SizedBox(height: 3.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 6.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================== VUE VIDE ==========================
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bike_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 3.h),
            Text(
              'Aucune course disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Tirez vers le bas pour recharger',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================== WIDGET COURSE CARD ==========================
class _CourseCardElegant extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isBlocked;

  const _CourseCardElegant({
    required this.course,
    required this.onTap,
    required this.isLoading,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 28),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.restaurantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${course.totalPrice.toStringAsFixed(0)} FCFA • ${course.createdAt.hour.toString().padLeft(2, '0')}:${course.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: (isLoading || isBlocked) ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    disabledBackgroundColor: Colors.deepOrange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Prendre',
                          style: TextStyle(fontWeight: FontWeight.bold),
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