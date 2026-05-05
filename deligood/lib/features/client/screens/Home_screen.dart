import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Clé SharedPreferences pour persister la commande active
const String _kActiveOrderId = 'active_order_id';

/// Intervalle de polling en secondes
const int _kPollingInterval = 10;

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
String fixImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) {
    return path.replaceFirst(
      RegExp(r'(https://deligood-backend\.onrender\.com)([^/])'),
      r'$1/$2',
    );
  }
  final clean = path.startsWith('/') ? path : '/media/$path';
  return '$_baseUrl$clean';
}

/// Parse une LatLng depuis différents formats JSON possibles
LatLng? parseLatLng(Map<String, dynamic>? src) {
  if (src == null) return null;

  // format GeoJSON { "coordinates": [lng, lat] }
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

  // format { "lat": ..., "lng": ... }
  if (src['lat'] != null && src['lng'] != null) {
    final lat = double.tryParse(src['lat'].toString());
    final lng = double.tryParse(src['lng'].toString());
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
  }

  // format { "latitude": ..., "longitude": ... }
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
// PERSISTENCE HELPER
// ─────────────────────────────────────────────
class _OrderPersistence {
  /// Sauvegarde l'id de la commande active en local
  static Future<void> saveActiveOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kActiveOrderId, orderId);
    debugPrint('💾 Commande active sauvegardée: #$orderId');
  }

  /// Récupère l'id de la commande active (null si aucune)
  static Future<int?> getActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kActiveOrderId);
    debugPrint('💾 Commande active chargée: $id');
    return id;
  }

  /// Efface la commande active (livrée ou annulée)
  static Future<void> clearActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveOrderId);
    debugPrint('🗑️ Commande active effacée');
  }
}

// ─────────────────────────────────────────────
// MODEL commande
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
  final LatLng? deliveryPosition;

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
    this.deliveryPosition,
  });

  /// Les statuts terminaux qui doivent effacer la commande persistée
  bool get isTerminal =>
      status == 'DELIVERED' || status == 'CANCELLED';

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    // ── Format A : objets imbriqués { restaurant: {...}, client: {...} }
    // ── Format B : champs plats    { client_name: "...", client_phone: "..." }
    // On supporte les deux simultanément.

    final resto    = json['restaurant'] as Map<String, dynamic>?;
    final client   = json['client']     as Map<String, dynamic>?;
    final delivery = json['delivery']   as Map<String, dynamic>?;

    debugPrint('======= ORDER DATA =======');
    debugPrint('🏪 restaurant raw: $resto');
    debugPrint('👤 client raw: $client');
    debugPrint('🚴 delivery raw: $delivery');
    debugPrint('📄 json keys: ${json.keys.toList()}');
    debugPrint('==========================');

    // ── Positions ──────────────────────────────────────────────────────────
    // Cherche dans l'objet imbriqué d'abord, puis dans les champs plats
    final restoPos = parseLatLng(resto) ??
        parseLatLng(resto?['position'] as Map<String, dynamic>?) ??
        parseLatLng(resto?['location'] as Map<String, dynamic>?) ??
        _parseFlatLatLng(json, latKey: 'restaurant_lat', lngKey: 'restaurant_lng');

    final clientPos = parseLatLng(client) ??
        parseLatLng(client?['position'] as Map<String, dynamic>?) ??
        parseLatLng(client?['location'] as Map<String, dynamic>?) ??
        _parseFlatLatLng(json, latKey: 'client_lat', lngKey: 'client_lng');

    final deliveryPos = parseLatLng(delivery) ??
        parseLatLng(delivery?['position'] as Map<String, dynamic>?) ??
        parseLatLng(delivery?['location'] as Map<String, dynamic>?) ??
        _parseFlatLatLng(json, latKey: 'livreur_lat', lngKey: 'livreur_lng');

    debugPrint('✅ restoPos: $restoPos');
    debugPrint('✅ clientPos: $clientPos');
    debugPrint('✅ deliveryPos: $deliveryPos');

    // ── Nom restaurant ──────────────────────────────────────────────────────
    String restoName = 'Restaurant';
    if (resto != null) {
      restoName = _extractName(resto, fallback: 'Restaurant');
    } else {
      // Champs plats possibles
      final flat = json['restaurant_name'] ??
          json['resto_name'] ??
          json['shop_name'];
      if (flat != null && flat.toString().isNotEmpty) restoName = flat.toString();
    }

    // ── Nom client ──────────────────────────────────────────────────────────
    String clientName = 'Client';
    if (client != null) {
      clientName = _extractName(client, fallback: 'Client');
    } else {
      // Champs plats : client_name, ou client_first_name + client_last_name
      final flatName = json['client_name'];
      if (flatName != null && flatName.toString().isNotEmpty) {
        clientName = flatName.toString();
      } else {
        final fn = json['client_first_name']?.toString() ?? '';
        final ln = json['client_last_name']?.toString() ?? '';
        final full = '$fn $ln'.trim();
        if (full.isNotEmpty) clientName = full;
      }
    }

    // ── Téléphone client ────────────────────────────────────────────────────
    final clientPhone = client?['phone']?.toString() ??
        client?['phone_number']?.toString() ??
        json['client_phone']?.toString() ??   // champ plat
        json['phone']?.toString() ??
        '';

    // ── Nom livreur ─────────────────────────────────────────────────────────
    String? deliveryName;
    if (delivery != null) {
      deliveryName = _extractName(delivery);
    } else {
      final flat = json['livreur_name'] ??
          json['delivery_name'] ??
          json['driver_name'];
      if (flat != null && flat.toString().isNotEmpty) {
        deliveryName = flat.toString();
      }
    }

    // ── Localité ────────────────────────────────────────────────────────────
    final locality = json['locality']?.toString() ??
        json['client_address']?.toString() ??
        json['address']?.toString() ??
        '';

    // ── Statut normalisé en MAJUSCULES ──────────────────────────────────────
    // Le backend peut retourner "pending", "PENDING", "Pending", etc.
    final status = (json['status'] ?? 'PENDING').toString().toUpperCase();

    return OrderInfo(
      id: json['id'] ?? 0,
      status: status,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      restaurantName: restoName,
      locality: locality,
      clientName: clientName,
      clientPhone: clientPhone,
      deliveryName: deliveryName,
      restaurantPosition: restoPos,
      clientPosition: clientPos,
      deliveryPosition: deliveryPos,
    );
  }

  /// Extrait un nom depuis un objet (name > first_name + last_name)
  static String _extractName(Map<String, dynamic> obj, {String fallback = ''}) {
    final name = obj['name']?.toString() ?? '';
    if (name.isNotEmpty) return name;
    final fn = obj['first_name']?.toString() ?? '';
    final ln = obj['last_name']?.toString() ?? '';
    final full = '$fn $ln'.trim();
    return full.isNotEmpty ? full : fallback;
  }

  /// Parse une position depuis deux clés plates dans le JSON racine
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

  String get statusLabel {
    switch (status) {
      case 'PENDING':     return 'En attente';
      case 'ACCEPTED':    return 'Acceptée';
      case 'PREPARING':   return 'En préparation';
      case 'ON_THE_WAY':  return 'En livraison';
      case 'DELIVERED':   return 'Livrée';
      case 'CANCELLED':   return 'Annulée';
      default:            return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':     return Colors.orange;
      case 'ACCEPTED':    return kTeal;
      case 'PREPARING':   return Colors.blue;
      case 'ON_THE_WAY':  return kOrange;
      case 'DELIVERED':   return kSuccess;
      case 'CANCELLED':   return Colors.red;
      default:            return kTextSecondary;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'PENDING':     return Icons.hourglass_empty_rounded;
      case 'ACCEPTED':    return Icons.thumb_up_rounded;
      case 'PREPARING':   return Icons.restaurant_rounded;
      case 'ON_THE_WAY':  return Icons.delivery_dining_rounded;
      case 'DELIVERED':   return Icons.check_circle_rounded;
      case 'CANCELLED':   return Icons.cancel_rounded;
      default:            return Icons.info_outline_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  /// orderId passé depuis la page de création de commande (optionnel)
  final int? orderId;
  const HomeScreen({super.key, this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SessionManager session = SessionManager();
  late final MapController _mapController;

  // ── State ──
  int? _activeOrderId;
  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;
  OrderInfo? orderInfo;
  bool isLoading = true;
  String? errorMessage;

  // ── Polling ──
  Timer? _pollingTimer;

  // ── Animations ──
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

    _bootstrap();
  }

  /// Point d'entrée : résout l'orderId (paramètre > persisté > rien)
  Future<void> _bootstrap() async {
    // Priorité : orderId passé en paramètre
    if (widget.orderId != null && widget.orderId! > 0) {
      _activeOrderId = widget.orderId;
      // Sauvegarder immédiatement pour les prochains lancements
      await _OrderPersistence.saveActiveOrder(_activeOrderId!);
    } else {
      // Charger depuis SharedPreferences
      _activeOrderId = await _OrderPersistence.getActiveOrder();
    }

    debugPrint('🎯 activeOrderId résolu: $_activeOrderId');
    await _init();
  }

  Future<void> _init() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // 1. Position GPS du client (silencieux si non disponible)
    final gps = await _getCurrentLocation();
    if (gps != null) {
      clientPos = gps;
      _safeMapMove(gps, 15);
    }

    // 2. Charger la commande active si on en a une
    if (_activeOrderId != null) {
      await _fetchOrderInfo();
    }

    setState(() => isLoading = false);

    // 3. Animer le panneau si commande présente
    if (orderInfo != null) {
      _slideController.forward();
      _fitMapToBounds();

      // 4. Démarrer le polling si la commande est active (non terminale)
      if (!orderInfo!.isTerminal) {
        _startPolling();
      }
    }
  }

  // ─────────────────────────────────────────────
  // POLLING
  // ─────────────────────────────────────────────

  void _startPolling() {
    _stopPolling(); // Annuler tout timer existant
    debugPrint('⏱️ Polling démarré (toutes les ${_kPollingInterval}s)');
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _kPollingInterval),
      (_) => _pollUpdate(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('⏱️ Polling arrêté');
  }

  /// Rafraîchit statut + positions sans bloquer l'UI
  Future<void> _pollUpdate() async {
    if (_activeOrderId == null) return;
    debugPrint('🔄 Poll: mise à jour commande #$_activeOrderId');

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/$_activeOrderId/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final info = OrderInfo.fromJson(data);

        if (!mounted) return;

        setState(() {
          orderInfo = info;
          if (info.restaurantPosition != null) {
            restaurantPos = info.restaurantPosition;
          }
          if (info.deliveryPosition != null) {
            deliveryPos = info.deliveryPosition;
          }
          // GPS réel prioritaire pour le client
          if (info.clientPosition != null && clientPos == null) {
            clientPos = info.clientPosition;
          }
        });

        // Essayer aussi /positions/ pour le livreur en temps réel
        await _fetchLivreurPosition();

        _fitMapToBounds();

        // Commande terminée → effacer et stopper le polling
        if (info.isTerminal) {
          debugPrint(
              '✅ Commande #$_activeOrderId terminée (${info.status}), nettoyage...');
          _stopPolling();
          await _OrderPersistence.clearActiveOrder();

          // Optionnel : notifier l'utilisateur visuellement
          if (mounted) {
            _showStatusBanner(info);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Poll error: $e');
      // Ne pas bloquer l'UI en cas d'erreur de polling
    }
  }

  /// Récupère uniquement la position du livreur depuis /positions/
  Future<void> _fetchLivreurPosition() async {
    if (_activeOrderId == null) return;
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/$_activeOrderId/positions/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('📍 Positions reçues: $data');

        if (!mounted) return;
        setState(() {
          // Mettre à jour restaurant si non encore dispo
          if (data['restaurant'] != null && restaurantPos == null) {
            restaurantPos = parseLatLng(
              Map<String, dynamic>.from(data['restaurant']),
            );
          }
          // Livreur — toujours mis à jour pour le temps réel
          if (data['livreur'] != null) {
            final pos = parseLatLng(
              Map<String, dynamic>.from(data['livreur']),
            );
            if (pos != null) deliveryPos = pos;
          }
          // Client depuis API si pas de GPS
          if (data['client'] != null && clientPos == null) {
            final pos = parseLatLng(
              Map<String, dynamic>.from(data['client']),
            );
            if (pos != null) clientPos = pos;
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ fetchLivreurPosition error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FETCH INITIAL
  // ─────────────────────────────────────────────

  Future<void> _fetchOrderInfo() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/orders/$_activeOrderId/'),
            headers: {
              HttpHeaders.authorizationHeader: 'Token $token',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📦 Status: ${response.statusCode}');
      debugPrint('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final info = OrderInfo.fromJson(data);

        if (!mounted) return;
        setState(() {
          orderInfo = info;
          if (info.restaurantPosition != null) {
            restaurantPos = info.restaurantPosition;
          }
          if (info.clientPosition != null && clientPos == null) {
            clientPos = info.clientPosition;
          }
          if (info.deliveryPosition != null) {
            deliveryPos = info.deliveryPosition;
          }
        });

        // Récupérer positions supplémentaires depuis /positions/
        await _fetchLivreurPosition();

        // Si commande déjà terminale au chargement → nettoyer
        if (info.isTerminal) {
          await _OrderPersistence.clearActiveOrder();
        }
      } else if (response.statusCode == 404) {
        // Commande introuvable → effacer la persistance
        debugPrint('⚠️ Commande #$_activeOrderId introuvable, nettoyage');
        await _OrderPersistence.clearActiveOrder();
        setState(() {
          _activeOrderId = null;
          errorMessage = 'Commande introuvable';
        });
      } else {
        setState(() => errorMessage = 'Erreur serveur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchOrderInfo: $e');
      setState(
          () => errorMessage = 'Erreur lors du chargement de la commande');
    }
  }

  // ─────────────────────────────────────────────
  // GPS
  // ─────────────────────────────────────────────

  Future<LatLng?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('⚠️ GPS non disponible: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CARTE
  // ─────────────────────────────────────────────

  void _safeMapMove(LatLng pos, double zoom) {
    try {
      _mapController.move(pos, zoom);
    } catch (_) {}
  }

  void _fitMapToBounds() {
    final points = [
      if (restaurantPos != null) restaurantPos!,
      if (clientPos != null) clientPos!,
      if (deliveryPos != null) deliveryPos!,
    ];

    if (points.isEmpty) return;

    if (points.length == 1) {
      _safeMapMove(points.first, 15);
      return;
    }

    final minLat =
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final minLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final maxLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    double zoom = 14;
    if (maxDiff > 0.1) {
      zoom = 11;
    } else if (maxDiff > 0.05) zoom = 12;
    else if (maxDiff > 0.02) zoom = 13;
    else if (maxDiff < 0.005) zoom = 15;

    _safeMapMove(LatLng(centerLat, centerLng), zoom);
  }

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<String?> _getToken() => session.getToken();

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
        _stopPolling();
        await _OrderPersistence.clearActiveOrder();
        setState(() {
          orderInfo = null;
          _activeOrderId = null;
          restaurantPos = null;
          deliveryPos = null;
        });
      } else {
        _showSnackBar('Échec de l\'annulation: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'annulation');
      debugPrint('❌ cancelOrder: $e');
    }
  }

  void _contactClient() {
    if (orderInfo?.clientPhone.isNotEmpty ?? false) {
      _showSnackBar('Appel vers ${orderInfo!.clientPhone}');
    } else {
      _showSnackBar('Numéro de téléphone non disponible');
    }
  }

  void _showStatusBanner(OrderInfo info) {
    if (!mounted) return;
    final isDelivered = info.status == 'DELIVERED';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isDelivered
                  ? 'Commande #${info.id} livrée !'
                  : 'Commande #${info.id} annulée',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isDelivered ? kSuccess : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 4),
      ),
    );
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
            borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _stopPolling();
    _pulseController.dispose();
    _slideController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

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

              // Polyline restaurant → livreur → client
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
                  if (restaurantPos != null)
                    _marker(
                      restaurantPos!,
                      Icons.store_rounded,
                      kOrange,
                      orderInfo?.restaurantName ?? 'Restaurant',
                    ),
                  if (deliveryPos != null)
                    _marker(
                      deliveryPos!,
                      Icons.delivery_dining_rounded,
                      kSuccess,
                      orderInfo?.deliveryName ?? 'Livreur',
                    ),
                  if (clientPos != null)
                    _marker(
                      clientPos!,
                      Icons.my_location,
                      kTeal,
                      orderInfo?.clientName ?? 'Vous',
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
                  _topBarButton(
                    icon: Icons.refresh,
                    onTap: () {
                      _stopPolling();
                      _init();
                    },
                  ),
                  // Badge commande + indicateur polling
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 1.h),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Point vert clignotant si polling actif
                        if (_pollingTimer?.isActive ?? false) ...[
                          _PollingDot(),
                          SizedBox(width: 2.w),
                        ],
                        Text(
                          _activeOrderId != null
                              ? 'Commande #$_activeOrderId'
                              : 'Ma position',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _topBarButton(
                    icon: Icons.my_location,
                    onTap: () {
                      if (clientPos != null) {
                        _safeMapMove(clientPos!, 15);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ════ PANNEAU COMMANDE ════
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

          // ════ ERREUR (sans commande) ════
          if (errorMessage != null && !isLoading && orderInfo == null)
            Positioned(
              bottom: 4.h,
              left: 6.w,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 4.w, vertical: 1.5.h),
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
                            color: Colors.red, fontSize: 11.sp),
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

  // ─────────────────────────────────────────────
  // PANNEAU COMMANDE
  // ─────────────────────────────────────────────

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

          // Titre + statut
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
                        fontSize: 11.sp, color: kTextSecondary),
                  ),
                ],
              ),
              // Badge statut
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: order.statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(order.statusIcon,
                        color: order.statusColor, size: 14),
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

          // Infos client
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
                  label: order.clientPhone.isNotEmpty
                      ? order.clientPhone
                      : 'N/A',
                  color: kTeal,
                  onTap: _contactClient,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.5.h),

          // Détails commande
          Row(
            children: [
              Expanded(
                child: _detailChip(
                  icon: Icons.location_on_rounded,
                  label: order.locality.isNotEmpty
                      ? order.locality
                      : 'N/A',
                  color: kOrange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _detailChip(
                  icon: Icons.payments_rounded,
                  label:
                      '${order.totalPrice.toStringAsFixed(0)} FCFA',
                  color: kSuccess,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Boutons d'action (PENDING uniquement)
          if (order.status == 'PENDING')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelOrder(order.id),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text('Annuler',
                        style: GoogleFonts.poppins(fontSize: 11.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contactClient,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text('Appeler',
                        style: GoogleFonts.poppins(fontSize: 11.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange.withOpacity(0.1),
                      foregroundColor: kOrange,
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

          // Message statut contextuel
          _statusMessage(order),
        ],
      ),
    );
  }

  Widget _statusMessage(OrderInfo order) {
    switch (order.status) {
      case 'PENDING':
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: _infoBanner(
            color: Colors.orange,
            icon: null,
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
        );

      case 'PREPARING':
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: _infoBanner(
            color: Colors.blue,
            icon: Icons.restaurant_rounded,
            text: 'Votre commande est en cours de préparation…',
          ),
        );

      case 'ON_THE_WAY':
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: _infoBanner(
            color: kOrange,
            icon: Icons.delivery_dining_rounded,
            text: order.deliveryName != null
                ? '${order.deliveryName} est en route !'
                : 'Votre livreur est en route !',
          ),
        );

      case 'DELIVERED':
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: _infoBanner(
            color: kSuccess,
            icon: Icons.check_circle_rounded,
            text: 'Commande livrée avec succès !',
          ),
        );

      case 'CANCELLED':
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: _infoBanner(
            color: Colors.red,
            icon: Icons.cancel_rounded,
            text: 'Commande annulée.',
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _infoBanner({
    required Color color,
    IconData? icon,
    String? text,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: child ??
          Row(
            children: [
              if (icon != null)
                Icon(icon, color: color, size: 22),
              if (icon != null) SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  text ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS RÉUTILISABLES
  // ─────────────────────────────────────────────

  Widget _detailChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
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

  Widget _topBarButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kWhite.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 8),
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
            scale:
                Tween(begin: 0.9, end: 1.1).animate(_pulseController),
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
            padding: EdgeInsets.symmetric(
                horizontal: 2.w, vertical: 0.5.h),
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

// ─────────────────────────────────────────────
// WIDGET : point vert clignotant (polling actif)
// ─────────────────────────────────────────────
class _PollingDot extends StatefulWidget {
  @override
  State<_PollingDot> createState() => _PollingDotState();
}

class _PollingDotState extends State<_PollingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: kSuccess,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}