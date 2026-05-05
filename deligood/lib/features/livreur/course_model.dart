import 'package:latlong2/latlong.dart';

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
        (json['restaurant_lat'] ?? 0).toDouble(),
        (json['restaurant_lng'] ?? 0).toDouble(),
      ),
      customerPos: LatLng(
        (json['customer_lat'] ?? 0).toDouble(),
        (json['customer_lng'] ?? 0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
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