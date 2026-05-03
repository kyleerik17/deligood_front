// ─────────────────────────────────────────────
// Models — DeliGood Restaurant
// ─────────────────────────────────────────────
import 'package:flutter/foundation.dart';

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

    // ✅ Prix unitaire : unit_price en priorité, sinon menu_item_price
    final unitPrice = double.tryParse(
          (json['unit_price'] ?? json['menu_item_price'] ?? 0).toString(),
        ) ??
        0.0;

    // ✅ Prix total : price en priorité, sinon unitPrice × quantity
    final rawPrice = double.tryParse(
          (json['price'] ?? 0).toString(),
        ) ??
        0.0;
    final resolvedPrice = rawPrice > 0 ? rawPrice : unitPrice * quantity;

    // 🪵 LOG ITEM
    debugPrint('  ┣━ 🍽  Item                   : ${json['menu_item_name'] ?? 'Plat inconnu'}');
    debugPrint('  ┣━ 🔢 Quantité                : $quantity');
    debugPrint('  ┣━ 💰 unit_price (brut)       : ${json['unit_price']}');
    debugPrint('  ┣━ 💰 menu_item_price (brut)  : ${json['menu_item_price']}');
    debugPrint('  ┣━ 💰 price (brut)            : ${json['price']}');
    debugPrint('  ┣━ ✅ unitPrice résolu         : $unitPrice FCFA');
    debugPrint('  ┗━ ✅ price résolu             : $resolvedPrice FCFA');

    return CommandeItem(
      name: json['menu_item_name'] ?? "Plat",
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
  final DateTime createdAt;
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

  // ✅ Utilise totalPrice de l'API si dispo, sinon somme des items
  double get total {
    if (totalPrice > 0) return totalPrice;
    return items.fold<double>(0.0, (sum, item) => sum + item.price);
  }

  factory CommandeResto.fromJson(Map<String, dynamic> json) {
    // 🪵 LOG COMMANDE — header
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════');
    debugPrint('║ 📦 COMMANDE #${json['id']}');
    debugPrint('╠══════════════════════════════════════════');
    debugPrint('║ 👤 Client      : ${json['client_name'] ?? 'N/A'}');
    debugPrint('║ 📞 Téléphone   : ${json['client_phone'] ?? json['phone'] ?? 'N/A'}');
    debugPrint('║ 📍 Adresse     : ${json['client_address'] ?? json['address'] ?? 'N/A'}');
    debugPrint('║ 🔖 Statut      : ${json['status'] ?? 'N/A'}');
    debugPrint('║ 💵 total_price : ${json['total_price'] ?? 'N/A'}');
    debugPrint('║ 🕐 Créée le    : ${json['created_at'] ?? 'N/A'}');
    debugPrint('╠══════════════════════════════════════════');
    debugPrint('║ 🛒 ARTICLES (${(json['items'] as List? ?? []).length}) :');

    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .map((e) => CommandeItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final totalPrice = double.tryParse(
          (json['total_price'] ?? 0).toString(),
        ) ??
        0.0;

    final instance = CommandeResto(
      id: json['id'],
      clientName: json['client_name'] ?? "Client",
      phone: json['client_phone'] ?? json['phone'] ?? "",
      address: json['client_address'] ?? json['address'] ?? "",
      status: json['status'] ?? "pending",
      createdAt: DateTime.parse(json['created_at']),
      totalPrice: totalPrice,
      items: items,
    );

    // 🪵 LOG COMMANDE — footer
    debugPrint('╠══════════════════════════════════════════');
    debugPrint(
      '║ ✅ Total résolu : ${instance.total.toStringAsFixed(0)} FCFA'
      '${totalPrice > 0 ? " (depuis API)" : " (calculé depuis items)"}',
    );
    debugPrint('╚══════════════════════════════════════════');
    debugPrint('');

    return instance;
  }
}