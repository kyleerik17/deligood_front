class CommandeItem {
  final String name;
  final int quantity;
  final double price;
  final double unitPrice;

  CommandeItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.unitPrice,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      name: json['menu_item_name'] ?? "Plat",
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
    );
  }
}

class CommandeResto {
  final int id;
  final String clientName;
  final String status;
  final DateTime createdAt;
  final List<CommandeItem> items;
  final String address;
  final String phone;

  CommandeResto({
    required this.id,
    required this.clientName,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.phone,
  });

  double get total => items.fold<double>(0.0, (sum, item) => sum + item.price) * 1.03;

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List).map((e) => CommandeItem.fromJson(e)).toList();
    return CommandeResto(
      id: json['id'],
      clientName: json['client_name'] ?? "Client",
      phone: json['client_phone'] ?? "",
      address: json['client_address'] ?? "",
      status: json['status'] ?? "pending",
      createdAt: DateTime.parse(json['created_at']),
      items: items,
    );
  }
}
