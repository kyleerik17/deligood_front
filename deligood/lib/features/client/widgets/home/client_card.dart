import 'package:deligood/features/client/widgets/home/order_info.dart';
import 'package:flutter/material.dart';

class ClientCard extends StatelessWidget {
  final OrderInfo order;

  const ClientCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(order.clientName),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.phone),
              const SizedBox(width: 8),
              Text(order.clientPhone),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 8),
              Text(order.locality),
            ],
          ),
        ],
      ),
    );
  }
}
