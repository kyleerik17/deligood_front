import 'package:deligood/features/client/widgets/home/order_info.dart';
import 'package:flutter/material.dart';

class OrderHeader extends StatelessWidget {
  final OrderInfo order;

  const OrderHeader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Commande #${order.id}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: order.statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(order.statusLabel),
        ),
      ],
    );
  }
}
