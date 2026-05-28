import 'package:deligood/core/network/api.dart';

class MenuItem {
  final int id; // ajouté
  final String name;
  final String imageUrl;
  final String price;
  final String? category;
  final String? description;

  MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.category,
    this.description,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'], // récupéré depuis l'API
      name: json['name'] ?? '',
      imageUrl: Api.resolveMediaUrl(
        (json['image_url'] ?? json['image'])?.toString(),
      ),
      price: json['price'].toString(),
      category: json['category_name'],
      description: json['description'],
    );
  }
}
