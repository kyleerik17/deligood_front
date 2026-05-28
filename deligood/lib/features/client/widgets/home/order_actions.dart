import 'package:flutter/material.dart';

import 'order_info.dart';

class OrderActions extends StatelessWidget {
  final OrderInfo order;

  const OrderActions({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(onPressed: () {}, child: const Text("Annuler")),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(onPressed: () {}, child: const Text("Appeler")),
        ),
      ],
    );
  }
}
