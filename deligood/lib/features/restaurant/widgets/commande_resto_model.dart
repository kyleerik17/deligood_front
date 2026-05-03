import 'package:flutter/foundation.dart';

// ── Logger silencieux — aucun spam sur Flutter Web ──
void _log(String msg) {
  if (kDebugMode) print(msg);
}

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
    final quantity = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;

    final unitPrice = double.tryParse(
          json['unit_price']?.toString() ??
              json['menu_item_price']?.toString() ??
              '0',
        ) ??
        0.0;

    final rawPrice = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    final resolvedPrice = rawPrice > 0 ? rawPrice : unitPrice * quantity;

    return CommandeItem(
      name: json['menu_item_name']?.toString() ?? 'Plat',
      quantity: quantity,
      unitPrice: unitPrice,
      price: resolvedPrice,
    );
  }
}

class CommandeResto {
  final int id;
  final String clientName;
  final String status;
  final DateTime? createdAt;
  final List<CommandeItem> items;
  final String address;
  final String phone;
  final double totalPrice;

  CommandeResto({
    required this.id,
    required this.clientName,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.phone,
    required this.totalPrice,
  });

  double get total {
    if (totalPrice > 0) return totalPrice;
    return items.fold(0.0, (sum, item) => sum + item.price);
  }

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CommandeItem> itemsList = [];

    if (rawItems is List) {
      for (final e in rawItems) {
        try {
          itemsList.add(CommandeItem.fromJson(Map<String, dynamic>.from(e)));
        } catch (err) {
          _log('⚠️ Item ignoré: $err');
        }
      }
    }

    DateTime? parsedDate;
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString());
      }
    } catch (_) {
      parsedDate = null;
    }

    final instance = CommandeResto(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      clientName: json['client_name']?.toString() ??
          json['customer_name']?.toString() ??
          json['user_name']?.toString() ??
          json['username']?.toString() ??
          'Client',
      phone: json['client_phone']?.toString() ??
          json['phone']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      address: json['client_address']?.toString() ??
          json['address']?.toString() ??
          json['delivery_address']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: parsedDate ?? DateTime.now(),
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ??
          double.tryParse(json['total']?.toString() ?? '0') ??
          0.0,
      items: itemsList,
    );

    // ✅ Un seul log léger par commande
    _log('📦 #${instance.id} | ${instance.clientName} | ${instance.status} | ${instance.total} FCFA | ${instance.items.length} item(s)');

    return instance;
  }
}