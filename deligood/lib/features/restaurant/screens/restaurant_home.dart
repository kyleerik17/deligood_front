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
const String _baseUrl     = 'https://deligood-backend.onrender.com';

// ─────────────────────────────────────────────
// HELPERS IMAGE
// ─────────────────────────────────────────────

/// Construit une URL d'image correcte depuis un chemin relatif ou absolu.
String fixImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  // Déjà une URL complète → corriger le slash éventuel manquant
  if (path.startsWith('http')) {
    return path.replaceFirst(
      RegExp(r'(https://deligood-backend\.onrender\.com)([^/])'),
      r'$1/$2',
    );
  }
  // Chemin relatif : ajouter /media/ si absent
  final clean = path.startsWith('/') ? path : '/media/$path';
  return '$_baseUrl$clean';
}

// ─────────────────────────────────────────────
// HELPER POSITION
// ─────────────────────────────────────────────

/// Parse une LatLng depuis différents formats JSON possibles.
LatLng? parseLatLng(Map<String, dynamic>? src) {
  if (src == null) return null;

  // GeoJSON { "coordinates": [lng, lat] }
  if (src['coordinates'] is List) {
    final coords = src['coordinates'] as List;
    if (coords.length >= 2) {
      final lng = double.tryParse(coords[0].toString());
      final lat = double.tryParse(coords[1].toString());
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        return LatLng(lat, lng);
      }
    }
  }

  // { "lat": ..., "lng": ... }
  if (src['lat'] != null && src['lng'] != null) {
    final lat = double.tryParse(src['lat'].toString());
    final lng = double.tryParse(src['lng'].toString());
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
  }

  // { "latitude": ..., "longitude": ... }
  if (src['latitude'] != null && src['longitude'] != null) {
    final lat = double.tryParse(src['latitude'].toString());
    final lng = double.tryParse(src['longitude'].toString());
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
  }

  return null;
}

// ─────────────────────────────────────────────
// WIDGET PRINCIPAL
// ─────────────────────────────────────────────

class HomeRestaurant extends StatefulWidget {
  final int orderId;
  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant>
    with TickerProviderStateMixin {

  // ── State ──
  String  _orderStatus  = 'pending';
  bool    _isLoading    = true;
  bool    _wsConnected  = false;
  bool    _locationError = false;
  String? _errorMsg;
  int     _navIndex     = 0;

  // Données commande (champs plats du backend)
  String? _clientName;
  String? _clientPhone;
  String? _restaurantName;
  String? _locality;
  double  _totalPrice   = 0;

  LatLng? _restaurantPos;
  LatLng? _clientPos;
  LatLng? _livreurPos;

  String get _wsUrl =>
      'wss://deligood-backend.onrender.com/ws/orders/${widget.orderId}/';

  WebSocketChannel? _channel;
  Timer?            _pollTimer;

  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;
  late Animation<Offset>   _slideAnim;

  // Statuts terminaux (minuscules pour comparaison normalisée)
  static const _terminalStatuses = {'delivered', 'cancelled', 'livrée', 'annulée'};

  // ────────────────────────────────────────────
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
        _errorMsg  = "Commande invalide (id = 0)";
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

  // ────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────
  Future<void> _initPage() async {
    await Future.wait([
      _fetchRestaurantPosition(),
      _fetchOrder(),
    ]);
    _connectWebSocket();
  }

  // ────────────────────────────────────────────
  // GPS RESTAURANT
  // ────────────────────────────────────────────
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

      debugPrint('✅ GPS restaurant : ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _restaurantPos = LatLng(position.latitude, position.longitude);
          _locationError = false;
        });
      }
    } catch (e) {
      debugPrint('❌ GPS restaurant error : $e');
      if (mounted) setState(() => _locationError = true);
    }
  }

  // ────────────────────────────────────────────
  // TOKEN
  // ────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ────────────────────────────────────────────
  // CLEAR commande active si terminée
  // ────────────────────────────────────────────
  Future<void> _clearActiveOrderIfDone(String status) async {
    if (_terminalStatuses.contains(status.toLowerCase())) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_order_id');
      debugPrint('🗑️ Commande #${widget.orderId} terminée — active_order_id effacé');
    }
  }

  // ────────────────────────────────────────────
  // FETCH ORDER
  // Supporte les deux formats :
  //   A) objets imbriqués { restaurant: {...}, client: {...} }
  //   B) champs plats     { client_name: "...", client_phone: "..." }
  // ────────────────────────────────────────────
  Future<void> _fetchOrder() async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse('$_baseUrl/api/orders/${widget.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      debugPrint('📦 fetchOrder status: ${res.statusCode}');
      debugPrint('📦 fetchOrder body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // ── Statut normalisé en minuscules pour correspondre aux helpers ──
        final rawStatus = (data['status'] ?? 'pending').toString().toLowerCase();
        await _clearActiveOrderIfDone(rawStatus);

        // ── Objets imbriqués (Format A) ──
        final resto    = data['restaurant'] as Map<String, dynamic>?;
        final client   = data['client']     as Map<String, dynamic>?;
        final delivery = data['delivery']   as Map<String, dynamic>?;

        // ── Nom restaurant ──
        String restoName = 'Restaurant';
        if (resto != null) {
          restoName = _extractName(resto, fallback: 'Restaurant');
        } else {
          restoName = data['restaurant_name']?.toString() ??
              data['resto_name']?.toString() ??
              'Restaurant';
        }

        // ── Nom client ──
        String clientName = 'Client';
        if (client != null) {
          clientName = _extractName(client, fallback: 'Client');
        } else {
          final flat = data['client_name']?.toString() ?? '';
          if (flat.isNotEmpty) {
            clientName = flat;
          } else {
            final fn = data['client_first_name']?.toString() ?? '';
            final ln = data['client_last_name']?.toString() ?? '';
            final full = '$fn $ln'.trim();
            if (full.isNotEmpty) clientName = full;
          }
        }

        // ── Téléphone client ──
        final clientPhone = client?['phone']?.toString() ??
            client?['phone_number']?.toString() ??
            data['client_phone']?.toString() ??
            data['phone']?.toString() ??
            '';

        // ── Localité ──
        final locality = data['locality']?.toString() ??
            data['client_address']?.toString() ??
            data['address']?.toString() ??
            '';

        // ── Prix total ──
        final totalPrice = double.tryParse(
              data['total_price']?.toString() ?? '0',
            ) ??
            0.0;

        // ── Position restaurant : GPS réel prioritaire ──
        LatLng? restoPos = _restaurantPos; // déjà récupéré via GPS
        restoPos ??= parseLatLng(resto) ??
              parseLatLng(resto?['position'] as Map<String, dynamic>?) ??
              _parseFlatLatLng(data, latKey: 'restaurant_lat', lngKey: 'restaurant_lng');

        // ── Position client ──
        final clientPos = parseLatLng(client) ??
            parseLatLng(client?['position'] as Map<String, dynamic>?) ??
            _parseFlatLatLng(data, latKey: 'client_lat', lngKey: 'client_lng');

        // ── Position livreur ──
        final livreurPos = parseLatLng(delivery) ??
            parseLatLng(delivery?['position'] as Map<String, dynamic>?) ??
            _parseFlatLatLng(data, latKey: 'livreur_lat', lngKey: 'livreur_lng');

        debugPrint('🏪 restoName: $restoName | restoPos: $restoPos');
        debugPrint('👤 clientName: $clientName | clientPos: $clientPos');
        debugPrint('🚴 livreurPos: $livreurPos');

        setState(() {
          _orderStatus    = rawStatus;
          _restaurantName = restoName;
          _clientName     = clientName;
          _clientPhone    = clientPhone;
          _locality       = locality;
          _totalPrice     = totalPrice;

          if (restoPos != null)   _restaurantPos = restoPos;
          if (clientPos != null)  _clientPos     = clientPos;
          if (livreurPos != null) _livreurPos    = livreurPos;

          _isLoading = false;
        });

        _slideCtrl.forward();

      } else if (res.statusCode == 404) {
        // Commande introuvable → nettoyer
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_order_id');
        setState(() {
          _errorMsg  = "Commande introuvable";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg  = "Erreur serveur ${res.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ fetchOrder error: $e');
      if (!mounted) return;
      setState(() {
        _errorMsg  = "Erreur réseau";
        _isLoading = false;
      });
    }
  }

  // ────────────────────────────────────────────
  // WEBSOCKET
  // ────────────────────────────────────────────
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (event) async {
          if (!mounted) return;
          final data = jsonDecode(event) as Map<String, dynamic>;
          if (data['order_id'] == widget.orderId) {
            final newStatus = (data['status'] as String).toLowerCase();
            await _clearActiveOrderIfDone(newStatus);

            // Mise à jour position livreur via WS
            final livreurPos = _parseFlatLatLng(
              data,
              latKey: 'livreur_lat',
              lngKey: 'livreur_lng',
            );

            setState(() {
              _orderStatus = newStatus;
              if (livreurPos != null) _livreurPos = livreurPos;
            });
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _wsConnected = false);
            _startPolling();
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
        _startPolling();
      }
    }
  }

  // ────────────────────────────────────────────
  // POLLING FALLBACK
  // ────────────────────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchOrder();
    });
  }

  // ────────────────────────────────────────────
  // HELPERS PARSING
  // ────────────────────────────────────────────
  static String _extractName(Map<String, dynamic> obj, {String fallback = ''}) {
    final name = obj['name']?.toString() ?? '';
    if (name.isNotEmpty) return name;
    final fn   = obj['first_name']?.toString() ?? '';
    final ln   = obj['last_name']?.toString() ?? '';
    final full = '$fn $ln'.trim();
    return full.isNotEmpty ? full : fallback;
  }

  static LatLng? _parseFlatLatLng(
    Map<String, dynamic> json, {
    required String latKey,
    required String lngKey,
  }) {
    final lat = double.tryParse(json[latKey]?.toString() ?? '');
    final lng = double.tryParse(json[lngKey]?.toString() ?? '');
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return null;
  }

  // ────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.orderId <= 0) {
      return Scaffold(
        backgroundColor: kBg,
        
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
      
      body: Stack(
        children: [
          _buildMap(center),
          _buildTopBar(),

          // Bannière GPS indisponible
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

  // ────────────────────────────────────────────
  // NAVBAR
  // ────────────────────────────────────────────
  
  // ────────────────────────────────────────────
  // CARTE STATUT
  // ────────────────────────────────────────────
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                  // Indicateur WS / Polling
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

              // ── Infos commande ──
              if (_clientName != null || _locality != null || _totalPrice > 0) ...[
                SizedBox(height: 1.5.h),
                Divider(color: Colors.grey.shade100, thickness: 1),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    if (_clientName != null)
                      Expanded(
                        child: _infoChip(
                          icon: Icons.person_rounded,
                          label: _clientName!,
                          color: kTeal,
                        ),
                      ),
                    if (_clientName != null && _clientPhone != null)
                      SizedBox(width: 2.w),
                    if (_clientPhone != null && _clientPhone!.isNotEmpty)
                      Expanded(
                        child: _infoChip(
                          icon: Icons.phone_rounded,
                          label: _clientPhone!,
                          color: kTeal,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    if (_locality != null && _locality!.isNotEmpty)
                      Expanded(
                        child: _infoChip(
                          icon: Icons.location_on_rounded,
                          label: _locality!,
                          color: kOrange,
                        ),
                      ),
                    if (_locality != null && _totalPrice > 0)
                      SizedBox(width: 2.w),
                    if (_totalPrice > 0)
                      Expanded(
                        child: _infoChip(
                          icon: Icons.payments_rounded,
                          label: '${_totalPrice.toStringAsFixed(0)} FCFA',
                          color: kSuccess,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
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
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // MAP
  // ────────────────────────────────────────────
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
              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$kMaptilerKey',
          userAgentPackageName: 'com.deligood.app',
          maxZoom: 19,
          errorTileCallback: (tile, error, _) =>
              debugPrint('Tile error: $error'),
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
              _marker(_restaurantPos!, Icons.store_rounded, kOrange,
                  label: _restaurantName ?? 'Restaurant'),
            if (_clientPos != null)
              _marker(_clientPos!, Icons.home_rounded, kTeal,
                  label: _clientName ?? 'Client'),
            if (_livreurPos != null)
              _marker(_livreurPos!, Icons.delivery_dining_rounded, kSuccess,
                  label: 'Livreur'),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // MARKER
  // ────────────────────────────────────────────
  Marker _marker(LatLng pos, IconData icon, Color color, {String? label}) {
    return Marker(
      point: pos,
      width: 80,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              child: Icon(icon, color: color, size: 20),
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // TOP BAR
  // ────────────────────────────────────────────
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
                _restaurantName != null
                    ? '$_restaurantName · #${widget.orderId}'
                    : 'Commande #${widget.orderId}',
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
                  _wsConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
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

  // ────────────────────────────────────────────
  // ERROR BANNER
  // ────────────────────────────────────────────
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
    );
  }

  // ────────────────────────────────────────────
  // HELPERS STATUT  (minuscules — backend retourne "pending" etc.)
  // ────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'en attente':      return kAmber;
      case 'accepted':
      case 'preparing':
      case 'en préparation':  return kTeal;
      case 'ready':
      case 'prête':           return const Color(0xFF185FA5);
      case 'on_the_way':
      case 'en livraison':    return kOrange;
      case 'delivered':
      case 'livrée':          return kSuccess;
      case 'cancelled':
      case 'annulée':         return kError;
      default:                return kSubText;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':    return 'En attente';
      case 'accepted':   return 'Acceptée';
      case 'preparing':  return 'En préparation';
      case 'ready':      return 'Prête';
      case 'on_the_way': return 'En livraison';
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
      case 'on_the_way': return Icons.delivery_dining_rounded;
      case 'delivered':  return Icons.check_circle_rounded;
      case 'cancelled':  return Icons.cancel_rounded;
      default:           return Icons.info_rounded;
    }
  }
}