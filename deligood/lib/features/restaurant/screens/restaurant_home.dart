import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================== DESIGN SYSTEM ==================
const kOrange     = Color(0xFFFF6B35);
const kOrangeDark = Color(0xFFFF5722);
const kTeal       = Color(0xFF00CCBC);
const kTealDark   = Color(0xFF00A896);
const kBg         = Color(0xFFF7F3EF);
const kWhite      = Colors.white;
const kText       = Color(0xFF1A1A1A);
const kSubText    = Color(0xFF757575);
const kSuccess    = Color(0xFF4CAF50);
const kError      = Color(0xFFFF5A5F);
const kAmber      = Color(0xFFFF9800);

const String kMaptilerKey = "aUpTxlfy9X9wGiCprfoR";

class HomeRestaurant extends StatefulWidget {
  final int orderId;
  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant>
    with TickerProviderStateMixin {

  String _orderStatus = 'pending';
  bool _isLoading = true;
  bool _wsConnected = false;
  bool _locationError = false; // ✅ GPS indisponible
  String? _errorMsg;
  int _navIndex = 0;

  LatLng? _restaurantPos; // ✅ position GPS réelle du restaurant
  LatLng? _clientPos;
  LatLng? _livreurPos;

  static const _baseUrl = 'https://deligood-backend.onrender.com';

  String get _wsUrl =>
      'wss://deligood-backend.onrender.com/ws/orders/${widget.orderId}/';

  WebSocketChannel? _channel;
  Timer? _pollTimer; // ✅ polling fallback si WS échoue

  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;
  late Animation<Offset> _slideAnim;

  static const _terminalStatuses = {'delivered', 'cancelled', 'livrée', 'annulée'};

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    if (widget.orderId > 0) {
      _initPage();
    } else {
      setState(() {
        _errorMsg = "Commande invalide (id = 0)";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _pollTimer?.cancel();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ================== INIT ==================
  Future<void> _initPage() async {
    // ✅ 1. Récupérer la position GPS du restaurant en parallèle du fetch
    await Future.wait([
      _fetchRestaurantPosition(),
      _fetchOrder(),
    ]);
    _connectWebSocket();
  }

  // ================== GPS RESTAURANT ==================
  Future<void> _fetchRestaurantPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationError = true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _locationError = true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationError = true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Position restaurant : ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          // ✅ On écrase la position restaurant avec le GPS réel
          _restaurantPos = LatLng(position.latitude, position.longitude);
          _locationError = false;
        });
      }
    } catch (e) {
      debugPrint('❌ GPS restaurant error : $e');
      if (mounted) setState(() => _locationError = true);
    }
  }

  // ================== TOKEN ==================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ================== CLEAR commande active si terminée ==================
  Future<void> _clearActiveOrderIfDone(String status) async {
    if (_terminalStatuses.contains(status.toLowerCase())) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_order_id');
    }
  }

  // ================== FETCH ORDER ==================
  Future<void> _fetchOrder() async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse('$_baseUrl/api/orders/${widget.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status'] ?? 'pending';

        await _clearActiveOrderIfDone(status);

        setState(() {
          _orderStatus = status;

          // ✅ Position restaurant : GPS réel prioritaire, API en fallback
          if (_restaurantPos == null) {
            _restaurantPos = data['restaurant_lat'] != null
                ? LatLng(
                    double.parse(data['restaurant_lat'].toString()),
                    double.parse(data['restaurant_lng'].toString()),
                  )
                : const LatLng(5.3540, -4.0010);
          }

          _clientPos = data['client_lat'] != null
              ? LatLng(
                  double.parse(data['client_lat'].toString()),
                  double.parse(data['client_lng'].toString()),
                )
              : const LatLng(5.3290, -4.0210);

          _livreurPos = data['livreur_lat'] != null
              ? LatLng(
                  double.parse(data['livreur_lat'].toString()),
                  double.parse(data['livreur_lng'].toString()),
                )
              : null;

          _isLoading = false;
        });

        _slideCtrl.forward();
      } else {
        setState(() {
          _errorMsg = "Erreur serveur ${res.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = "Erreur réseau";
        _isLoading = false;
      });
    }
  }

  // ================== WEBSOCKET ==================
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (event) async {
          if (!mounted) return;
          final data = jsonDecode(event);
          if (data['order_id'] == widget.orderId) {
            final newStatus = data['status'] as String;
            await _clearActiveOrderIfDone(newStatus);

            // ✅ Mise à jour position livreur via WS si disponible
            if (data['livreur_lat'] != null && data['livreur_lng'] != null) {
              setState(() {
                _livreurPos = LatLng(
                  double.parse(data['livreur_lat'].toString()),
                  double.parse(data['livreur_lng'].toString()),
                );
              });
            }

            setState(() => _orderStatus = newStatus);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _wsConnected = false);
            _startPolling(); // ✅ fallback polling si WS échoue
          }
        },
        onDone: () {
          if (mounted) setState(() => _wsConnected = false);
        },
      );

      if (mounted) setState(() => _wsConnected = true);
    } catch (_) {
      if (mounted) {
        setState(() => _wsConnected = false);
        _startPolling(); // ✅ fallback polling si WS indisponible
      }
    }
  }

  // ================== POLLING FALLBACK ==================
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchOrder();
    });
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    if (widget.orderId <= 0) {
      return Scaffold(
        backgroundColor: kBg,
        bottomNavigationBar: _buildNavBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Aucune commande en cours",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBg,
        bottomNavigationBar: _buildNavBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kOrange),
              const SizedBox(height: 16),
              Text(
                'Récupération de votre position…',
                style: GoogleFonts.poppins(color: kSubText),
              ),
            ],
          ),
        ),
      );
    }

    final center = _restaurantPos ?? const LatLng(5.3540, -4.0010);

    return Scaffold(
      bottomNavigationBar: _buildNavBar(),
      body: Stack(
        children: [
          _buildMap(center),
          _buildTopBar(),

          // ✅ Bannière GPS indisponible
          if (_locationError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Position GPS indisponible — position API utilisée',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          _buildStatusCard(),

          if (_errorMsg != null)
            Positioned(
              bottom: 14.h,
              left: 6.w,
              right: 6.w,
              child: _buildErrorBanner(),
            ),
        ],
      ),
    );
  }

  // ================== NAVBAR ==================
  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          backgroundColor: kWhite,
          selectedItemColor: kOrange,
          unselectedItemColor: kSubText,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10.sp),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Suivi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ================== CARTE STATUT ==================
  Widget _buildStatusCard() {
    final color = _statusColor(_orderStatus);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(_orderStatus), color: color, size: 26),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${widget.orderId}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: kSubText,
                      ),
                    ),
                    Text(
                      _statusLabel(_orderStatus),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicateur polling/WS
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _wsConnected ? kSuccess : kAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _wsConnected ? 'Live' : 'Polling',
                    style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      color: _wsConnected ? kSuccess : kAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== MAP ==================
  Widget _buildMap(LatLng center) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
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

        if (_restaurantPos != null && _clientPos != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _restaurantPos!,
                  if (_livreurPos != null) _livreurPos!,
                  _clientPos!,
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
            if (_restaurantPos != null)
              _marker(_restaurantPos!, Icons.store, kOrange,
                  label: 'Restaurant'),
            if (_clientPos != null)
              _marker(_clientPos!, Icons.home, kTeal, label: 'Client'),
            if (_livreurPos != null)
              _marker(_livreurPos!, Icons.delivery_dining, kSuccess,
                  label: 'Livreur'),
          ],
        ),
      ],
    );
  }

  // ================== MARKER ==================
  Marker _marker(LatLng pos, IconData icon, Color color, {String? label}) {
    return Marker(
      point: pos,
      width: 70,
      height: 70,
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
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: kWhite,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================== TOP BAR ==================
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
                "Commande #${widget.orderId}",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: kText,
                ),
              ),
            ),

            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _wsConnected ? Icons.wifi : Icons.wifi_off,
                  color: _wsConnected ? kSuccess : kAmber,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== ERROR BANNER ==================
  Widget _buildErrorBanner() {
    return Container(
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
              _errorMsg!,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 11.sp,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMsg = null);
              _fetchOrder();
            },
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
    );
  }

  // ================== HELPERS STATUT ==================
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'en attente':   return kAmber;
      case 'accepted':
      case 'preparing':
      case 'en préparation': return kTeal;
      case 'ready':
      case 'prête':        return const Color(0xFF185FA5);
      case 'delivered':
      case 'livrée':       return kSuccess;
      case 'cancelled':
      case 'annulée':      return kError;
      default:             return kSubText;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':    return 'En attente';
      case 'accepted':   return 'Acceptée';
      case 'preparing':  return 'En préparation';
      case 'ready':      return 'Prête';
      case 'delivered':  return 'Livrée ✓';
      case 'cancelled':  return 'Annulée';
      default:           return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'pending':    return Icons.hourglass_top_rounded;
      case 'accepted':   return Icons.thumb_up_alt_rounded;
      case 'preparing':  return Icons.restaurant_rounded;
      case 'ready':      return Icons.done_all_rounded;
      case 'delivered':  return Icons.check_circle_rounded;
      case 'cancelled':  return Icons.cancel_rounded;
      default:           return Icons.info_rounded;
    }
  }
}