import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class HomeRestaurant extends StatefulWidget {
  final int orderId;

  const HomeRestaurant({super.key, required this.orderId});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  late WebSocketChannel channel;

  String orderStatus = 'pending';
  bool isLoading = true;

  final String baseUrl = 'https://deligood-backend.onrender.com'; // LOCAL ONLY
  final String wsUrl = 'ws://127.0.0.1:8000/ws/orders/';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchOrder();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // =========================
  // FETCH ORDER
  // =========================
  Future<void> _fetchOrder() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/${widget.orderId}/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderStatus = data['status'];
          isLoading = false;
        });
      }
    } catch (_) {
      isLoading = false;
    }
  }

  // =========================
  // UPDATE STATUS (API)
  // =========================
  Future<void> _updateStatus(String newStatus) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/orders/${widget.orderId}/status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      _showNotification('Statut mis à jour');
      // PAS DE setState → WebSocket fera le boulot
    } catch (_) {
      _showNotification('Erreur lors de la mise à jour');
    }
  }

  // =========================
  // WEBSOCKET
  // =========================
  void _connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      _handleWebSocketEvent(data);
    });
  }

  void _handleWebSocketEvent(Map<String, dynamic> data) {
    if (data['order_id'] == widget.orderId) {
      setState(() {
        orderStatus = data['status'];
      });
    }
  }

  // =========================
  // UI HELPERS
  // =========================
  void _showNotification(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor() {
    switch (orderStatus) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commande restaurant'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long),
                  const SizedBox(width: 12),
                  Text(
                    'Statut : $orderStatus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (orderStatus == 'pending')
              _actionButton(
                label: 'Confirmer la commande',
                color: Colors.blue,
                onTap: () => _updateStatus('confirmed'),
              ),

            if (orderStatus == 'confirmed')
              _actionButton(
                label: 'Commencer la préparation',
                color: Colors.orange,
                onTap: () => _updateStatus('preparing'),
              ),

            if (orderStatus == 'preparing')
              _actionButton(
                label: 'Commande prête',
                color: Colors.green,
                onTap: () => _updateStatus('ready'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
