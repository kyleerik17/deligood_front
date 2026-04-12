class MenuItemProduct {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  
  // Nouvelles propriétés
  final bool? isNew;
  final int? discount;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final int? preparationTime;
  final int? calories;
  final List<String>? allergens;
  final bool? isAvailable;
  final String? restaurantName;
  final int? stockQuantity;

  MenuItemProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isNew,
    this.discount,
    this.category,
    this.rating,
    this.reviewCount,
    this.preparationTime,
    this.calories,
    this.allergens,
    this.isAvailable,
    this.restaurantName,
    this.stockQuantity,
  });

  // Factory pour créer depuis JSON
  factory MenuItemProduct.fromJson(Map<String, dynamic> json) {
    return MenuItemProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : (json['price'] ?? 0.0),
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      
      // Nouvelles propriétés (avec valeurs par défaut)
      isNew: json['is_new'] ?? json['isNew'],
      discount: json['discount'],
      category: json['category'],
      rating: (json['rating'] is int) 
          ? (json['rating'] as int).toDouble() 
          : json['rating'],
      reviewCount: json['review_count'] ?? json['reviewCount'],
      preparationTime: json['preparation_time'] ?? json['preparationTime'],
      calories: json['calories'],
      allergens: json['allergens'] != null 
          ? List<String>.from(json['allergens']) 
          : null,
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      restaurantName: json['restaurant_name'] ?? json['restaurantName'],
      stockQuantity: json['stock_quantity'] ?? json['stockQuantity'],
    );
  }

  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_new': isNew,
      'discount': discount,
      'category': category,
      'rating': rating,
      'review_count': reviewCount,
      'preparation_time': preparationTime,
      'calories': calories,
      'allergens': allergens,
      'is_available': isAvailable,
      'restaurant_name': restaurantName,
      'stock_quantity': stockQuantity,
    };
  }

  // Méthode pour créer une copie avec modifications
  MenuItemProduct copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isNew,
    int? discount,
    String? category,
    double? rating,
    int? reviewCount,
    int? preparationTime,
    int? calories,
    List<String>? allergens,
    bool? isAvailable,
    String? restaurantName,
    int? stockQuantity,
  }) {
    return MenuItemProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isNew: isNew ?? this.isNew,
      discount: discount ?? this.discount,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      preparationTime: preparationTime ?? this.preparationTime,
      calories: calories ?? this.calories,
      allergens: allergens ?? this.allergens,
      isAvailable: isAvailable ?? this.isAvailable,
      restaurantName: restaurantName ?? this.restaurantName,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }

  // Prix avec réduction calculé
  double get discountedPrice {
    if (discount != null && discount! > 0) {
      return price * (1 - discount! / 100);
    }
    return price;
  }

  // Vérifier si le produit a une promotion
  bool get hasDiscount => discount != null && discount! > 0;

  // Obtenir le texte de disponibilité
  String get availabilityText {
    if (isAvailable == false) {
      return "Temporairement indisponible";
    }
    if (stockQuantity != null && stockQuantity! < 5) {
      return "Plus que $stockQuantity en stock";
    }
    return "Disponible";
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, price: $price FCFA, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItemProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}