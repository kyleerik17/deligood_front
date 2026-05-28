import 'dart:async';
import 'dart:convert';

import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';

/// ─────────────────────────────────────────────────────────────
/// STATE MACHINE (IMPORTANT)
/// ─────────────────────────────────────────────────────────────
enum TrackingState {
  noOrder,
  waitingDriver,
  tracking,
  delivered,
  error,
}

class HomeScreen extends StatefulWidget {
  final int? orderId;
  const HomeScreen({super.key, this.orderId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  /// ─── POSITIONS
  LatLng? clientPos;
  LatLng? restaurantPos;
  LatLng? deliveryPos;

  /// ─── STATE
  TrackingState _state = TrackingState.noOrder;

  double _progress = 0;
  String _eta = "—";

  Timer? _timer;

  final MapController _mapController = MapController();

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();

    if (widget.orderId != null) {
      _state = TrackingState.waitingDriver;
      _fetch();
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => _fetch());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// ─────────────────────────────────────────────
  /// FETCH SAFE (production-grade)
  /// ─────────────────────────────────────────────
  Future<void> _fetch() async {
    if (widget.orderId == null) return;

    final url = Uri.parse(
      "${Api.baseUrl}/api/orders/${widget.orderId}/positions/",
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        setState(() => _state = TrackingState.error);
        return;
      }

      final data = json.decode(res.body);

      LatLng? safeParse(dynamic d) {
        if (d == null) return null;
        if (d["lat"] == null || d["lng"] == null) return null;
        return LatLng(
          (d["lat"] as num).toDouble(),
          (d["lng"] as num).toDouble(),
        );
      }

      setState(() {
        clientPos = safeParse(data["client"]);
        restaurantPos = safeParse(data["restaurant"]);
        deliveryPos = safeParse(data["livreur"]);

        final status = data["status"] ?? "preparing";

        _state = _mapState(status);

        _progress = _progressValue(status);

        if (deliveryPos != null && clientPos != null) {
          _eta = _computeETA(deliveryPos!, clientPos!);
        }

        /// only move map if valid driver position
        if (deliveryPos != null) {
          _mapController.move(deliveryPos!, 15.2);
        }
      });
    } catch (_) {
      setState(() => _state = TrackingState.error);
    }
  }

  /// ─────────────────────────────────────────────
  /// STATE MAPPING
  /// ─────────────────────────────────────────────
  TrackingState _mapState(String s) {
    switch (s) {
      case "preparing":
        return TrackingState.waitingDriver;
      case "picked_up":
      case "on_the_way":
        return TrackingState.tracking;
      case "delivered":
        return TrackingState.delivered;
      default:
        return TrackingState.waitingDriver;
    }
  }

  double _progressValue(String s) => switch (s) {
        "preparing" => 0.25,
        "picked_up" => 0.5,
        "on_the_way" => 0.75,
        "delivered" => 1.0,
        _ => 0
      };

  String _computeETA(LatLng a, LatLng b) {
    const d = Distance();
    final km = d.as(LengthUnit.Kilometer, a, b);
    final min = (km / 30 * 60 + 4).round();
    return min < 5 ? "Arrivée imminente" : "$min min";
  }

  Color _statusColor() => switch (_state) {
        TrackingState.tracking => AppColors.greenDark,
        TrackingState.delivered => AppColors.green,
        TrackingState.waitingDriver => AppColors.orange,
        _ => AppColors.textMuted,
      };

  /// ─────────────────────────────────────────────
  /// BUILD
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return _emptyOrderView();
    }

    return PremiumScaffold(
      child: Stack(
        children: [
          /// ─── MAP ONLY WHEN TRACKING EXISTS
          if (_state != TrackingState.noOrder)
            Positioned.fill(child: _buildMap()),

          /// ─── UI OVERLAY
          SafeArea(
            child: Column(
              children: [
                _header(),

                const Spacer(),

                if (_state == TrackingState.tracking ||
                    _state == TrackingState.waitingDriver)
                  _bottomSheet(),

                if (_state == TrackingState.delivered)
                  _deliveredCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// MAP
  /// ─────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: deliveryPos ?? clientPos ?? const LatLng(5.3, -4.0),
        initialZoom: 14.5,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),

        if (restaurantPos != null &&
            deliveryPos != null &&
            clientPos != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [restaurantPos!, deliveryPos!, clientPos!],
                color: AppColors.orange,
                strokeWidth: 4,
              )
            ],
          ),

        MarkerLayer(
          markers: [
            if (clientPos != null)
              _marker(clientPos!, "Client", AppColors.greenDark,
                  Icons.person),

            if (restaurantPos != null)
              _marker(restaurantPos!, "Restaurant",
                  AppColors.orange, Icons.store),

            if (deliveryPos != null) _driver(deliveryPos!),
          ],
        ),
      ],
    );
  }

  /// ─────────────────────────────────────────────
  /// HEADER
  /// ─────────────────────────────────────────────
  Widget _header() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.page),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(.95),
        borderRadius: AppSpacing.lgRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.delivery_dining, color: _statusColor()),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _state == TrackingState.tracking
                      ? "Votre commande arrive"
                      : "Commande en cours",
                  style: AppText.h3(),
                ),
                Text(
                  "ETA $_eta",
                  style: AppText.bodySm(color: _statusColor()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// BOTTOM SHEET (ONLY WHEN NEEDED)
  /// ─────────────────────────────────────────────
  Widget _bottomSheet() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.page),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress,
            color: AppColors.orange,
            backgroundColor: AppColors.surfaceLow,
          ),
          Gap(2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Préparation"),
              Text("Pris"),
              Text("Route"),
              Text("Livré"),
            ],
          )
        ],
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// DELIVERED STATE
  /// ─────────────────────────────────────────────
  Widget _deliveredCard() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.page),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(.1),
        borderRadius: AppSpacing.lgRadius,
      ),
      child: Text(
        "Commande livrée 🎉",
        style: AppText.h3(color: AppColors.green),
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// EMPTY STATE
  /// ─────────────────────────────────────────────
  Widget _emptyOrderView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.local_shipping_outlined, size: 60),
              SizedBox(height: 20),
              Text("Aucune commande en cours"),
            ],
          ),
        ),
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// MARKERS
  /// ─────────────────────────────────────────────
  Marker _marker(LatLng p, String t, Color c, IconData i) {
    return Marker(
      point: p,
      width: 80,
      height: 80,
      child: Column(
        children: [
          Text(t, style: AppText.caption(color: c)),
          Icon(i, color: c),
        ],
      ),
    );
  }

  Marker _driver(LatLng p) {
    return Marker(
      point: p,
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: 1 + _pulse.value * .2,
          child: Icon(Icons.two_wheeler,
              size: 34, color: AppColors.orange),
        ),
      ),
    );
  }
}