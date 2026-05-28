import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
  final LatLng? deliveryPosition;

  final String? deliveryName;

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
    this.deliveryPosition,
    this.deliveryName,
  });

  // ─────────────────────────────
  // 🎯 STATUS LABEL
  // ─────────────────────────────
  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'ACCEPTED':
        return 'Acceptée';
      case 'PREPARING':
        return 'Préparation';
      case 'ON_THE_WAY':
        return 'En route';
      case 'DELIVERED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  // ─────────────────────────────
  // 🎨 STATUS COLOR
  // ─────────────────────────────
  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.teal;
      case 'PREPARING':
        return Colors.blue;
      case 'ON_THE_WAY':
        return Colors.deepOrange;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ─────────────────────────────
  // 🧩 FACTORY FROM JSON
  // ─────────────────────────────
  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,

      restaurantName: json['restaurant_name'] ?? 'Restaurant',
      locality: json['locality'] ?? 'Adresse inconnue',

      clientName: json['client_name'] ?? 'Client',
      clientPhone: json['client_phone'] ?? '',
    );
  }
}
