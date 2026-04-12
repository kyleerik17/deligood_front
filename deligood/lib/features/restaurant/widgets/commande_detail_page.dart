import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'commande_resto_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deligood/features/restaurant/screens/restaurant_home.dart';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'en attente':
      return CupertinoColors.systemOrange;
    case 'accepted':
      return CupertinoColors.activeBlue;
    case 'livrée':
      return CupertinoColors.systemGreen;
    case 'annulée':
      return CupertinoColors.systemRed;
    default:
      return CupertinoColors.systemGrey;
  }
}

class CommandeDetailPage extends StatefulWidget {
  final CommandeResto commande;
  const CommandeDetailPage({super.key, required this.commande});

  @override
  State<CommandeDetailPage> createState() => _CommandeDetailPageState();
}

class _CommandeDetailPageState extends State<CommandeDetailPage> {
  bool _isProcessing = false;

  Future<void> accepterCommande(BuildContext context, CommandeResto commande) async {
    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      setState(() => _isProcessing = false);
      _showError(context, "Token manquant");
      return;
    }

    final url =
    'http://127.0.0.1:8000/api/orders/orders/restaurant/${commande.id}/status/';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.startsWith('ey') ? 'Bearer $token' : 'Token $token',
        },
        body: jsonEncode({"status": "accepted"}),
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (_) => HomeRestaurant(orderId: commande.id),
            ),
          );
        }
      } else {
        _showError(context, "Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(context, "Erreur réseau");
    }
  }

  void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Voulez-vous accepter cette commande ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              accepterCommande(context, widget.commande);
            },
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dejaPrise = widget.commande.status.toLowerCase() != 'pending' &&
        widget.commande.status.toLowerCase() != 'en attente';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.9),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        middle: Text(
          'Commande #${widget.commande.id}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor(widget.commande.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor(widget.commande.status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(widget.commande.status),
                    size: 44,
                    color: statusColor(widget.commande.status),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.commande.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: statusColor(widget.commande.status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Client
            _buildSection(
              title: 'Client',
              child: Column(
                children: [
                  // Nom
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.commande.clientName.isNotEmpty
                                  ? widget.commande.clientName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.commande.clientName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Téléphone
                  _buildInfoRow(
                    CupertinoIcons.phone,
                    widget.commande.phone,
                  ),
                  const SizedBox(height: 8),
                  // Adresse
                  _buildInfoRow(
                    CupertinoIcons.location,
                    widget.commande.address,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Articles
            _buildSection(
              title: 'Articles (${widget.commande.items.length})',
              child: Column(
                children: widget.commande.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Icône
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.square_list,
                            size: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Prix
                        Text(
                          '${(item.unitPrice * item.quantity).toStringAsFixed(0)} F',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.activeBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  Text(
                    '${widget.commande.total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton accepter
            if (!dejaPrise) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _isProcessing ? null : _showConfirmDialog,
                disabledColor: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(12),
                child: _isProcessing
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Accepter la commande',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
              letterSpacing: 0.5,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'en attente':
        return CupertinoIcons.clock;
      case 'accepted':
        return CupertinoIcons.checkmark_circle;
      case 'livrée':
        return CupertinoIcons.checkmark_seal;
      case 'annulée':
        return CupertinoIcons.xmark_circle;
      default:
        return CupertinoIcons.info_circle;
    }
  }
}