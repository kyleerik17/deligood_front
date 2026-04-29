import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
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

// 🗺️ Clé Maptiler — idéalement dans un constants.dart partagé
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
  String? _errorMsg;

  LatLng? _restaurantPos;
  LatLng? _clientPos;
  LatLng? _livreurPos;

  static const _baseUrl = 'https://deligood-backend.onrender.com';

  // ✅ FIX 1 : L'URL WebSocket doit inclure l'orderId
  String get _wsUrl =>
      'wss://deligood-backend.onrender.com/ws/orders/${widget.orderId}/';

  WebSocketChannel? _channel;

  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;
  late Animation<Offset> _slideAnim;

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

    // ✅ FIX 2 : Ne rien appeler si orderId invalide
    if (widget.orderId > 0) {
      _connectWebSocket();
      _fetchOrder();
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
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ================== TOKEN ==================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
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

        setState(() {
          _orderStatus = data['status'] ?? 'pending';

          _restaurantPos = data['restaurant_lat'] != null
              ? LatLng(
                  double.parse(data['restaurant_lat'].toString()),
                  double.parse(data['restaurant_lng'].toString()),
                )
              : const LatLng(5.3540, -4.0010);

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
      // ✅ FIX 1 : URL avec orderId dynamique
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (event) {
          if (!mounted) return;
          final data = jsonDecode(event);
          if (data['order_id'] == widget.orderId) {
            setState(() => _orderStatus = data['status']);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _wsConnected = false);
        },
        onDone: () {
          if (mounted) setState(() => _wsConnected = false);
        },
      );

      if (mounted) setState(() => _wsConnected = true);
    } catch (_) {
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    // ✅ FIX 2 : Afficher un état vide si orderId invalide
    if (widget.orderId <= 0) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                "Aucune commande sélectionnée",
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
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }

    final center = _restaurantPos ?? const LatLng(5.3540, -4.0010);

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(center),
          _buildTopBar(),

          // ✅ Bannière d'erreur en bas si besoin
          if (_errorMsg != null)
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
              ),
            ),
        ],
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
        // ✅ Maptiler — optimisé mobile, CDN rapide, pas de 404/403
        TileLayer(
          urlTemplate:
              "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$kMaptilerKey",
          userAgentPackageName: "com.deligood.app",
          maxZoom: 19,
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('Tile error: $error');
          },
        ),

        // Polyline restaurant → livreur → client
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
              _marker(_restaurantPos!, Icons.store, kOrange),
            if (_clientPos != null)
              _marker(_clientPos!, Icons.home, kTeal),
            if (_livreurPos != null)
              _marker(_livreurPos!, Icons.delivery_dining, kSuccess),
          ],
        ),
      ],
    );
  }

  // ================== MARKER ==================
  Marker _marker(LatLng pos, IconData icon, Color color) {
    return Marker(
      point: pos,
      width: 60,
      height: 60,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.1).animate(_pulseCtrl),
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

  // ================== TOP BAR ==================
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton retour
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: kText),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Titre commande
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

            // Indicateur WebSocket
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
                  color: _wsConnected ? kSuccess : kError,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}