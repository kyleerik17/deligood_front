import 'package:flutter/material.dart';
import 'drag_handle.dart';
import 'order_header.dart';
import 'client_card.dart';
import 'order_actions.dart';
import 'order_info.dart';

class OrderPanel extends StatelessWidget {
  final OrderInfo order;

  const OrderPanel({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DragHandle(),
          OrderHeader(order: order),
          const SizedBox(height: 10),
          ClientCard(order: order),
          const SizedBox(height: 10),
          OrderActions(order: order),
        ],
      ),
    );
  }
}
