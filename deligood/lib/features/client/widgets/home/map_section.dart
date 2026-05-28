import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:deligood/core/styles/app_theme.dart';
import 'map_marker.dart';

class MapSection extends StatelessWidget {
  final LatLng? clientPos;
  final LatLng? restaurantPos;
  final LatLng? deliveryPos;

  const MapSection({
    super.key,
    this.clientPos,
    this.restaurantPos,
    this.deliveryPos,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: clientPos ?? const LatLng(5.32, -4.01),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTilerKey.isEmpty
              ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
              : 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${AppConfig.mapTilerKey}',
          userAgentPackageName: 'com.example.deligood',
        ),

        PolylineLayer(
          polylines: [
            if (restaurantPos != null && clientPos != null)
              Polyline(
                points: [
                  restaurantPos!,
                  if (deliveryPos != null) deliveryPos!,
                  clientPos!,
                ],
                color: Colors.orange,
                strokeWidth: 4,
              ),
          ],
        ),

        MarkerLayer(
          markers: [
            if (restaurantPos != null)
              MapMarker(
                position: restaurantPos!,
                icon: Icons.store,
                color: Colors.orange,
                label: "Resto",
              ).build(),

            if (deliveryPos != null)
              MapMarker(
                position: deliveryPos!,
                icon: Icons.delivery_dining,
                color: Colors.green,
                label: "Livreur",
              ).build(),

            if (clientPos != null)
              MapMarker(
                position: clientPos!,
                icon: Icons.person,
                color: Colors.blue,
                label: "Client",
              ).build(),
          ],
        ),
      ],
    );
  }
}
