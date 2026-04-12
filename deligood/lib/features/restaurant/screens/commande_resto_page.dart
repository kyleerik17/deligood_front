import 'dart:convert';
import 'package:deligood/features/restaurant/widgets/commande_detail_page.dart';
import 'package:deligood/features/restaurant/widgets/commande_resto_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommandeRestoPage extends StatefulWidget {
  const CommandeRestoPage({super.key});

  @override
  State<CommandeRestoPage> createState() => _CommandeRestoPageState();
}

class _CommandeRestoPageState extends State<CommandeRestoPage> {
  List<CommandeResto> commandes = [];
  bool isLoading = true;
  String errorMessage = '';
  String accessToken = '';

  @override
  void initState() {
    super.initState();
    fetchCommandes();
  }

  String getBaseUrl() => "http://127.0.0.1:8000";

  Future<List<CommandeResto>> fetchCommandesResto() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception("Token introuvable. Veuillez vous reconnecter.");
    }

    accessToken = token;

    final isJwt = token.startsWith("ey");
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': isJwt ? 'Bearer $token' : 'Token $token',
    };

    final response = await http.get(
      Uri.parse('${getBaseUrl()}/api/orders/orders/restaurant/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => CommandeResto.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      await prefs.remove('access_token');
      throw Exception("Token invalide ou expiré. Veuillez vous reconnecter.");
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }

  Future<void> fetchCommandes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await fetchCommandesResto();
      setState(() {
        commandes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "en attente":
      case "pending":
        return CupertinoColors.systemOrange;
      case "livrée":
      case "delivered":
        return CupertinoColors.systemGreen;
      case "annulée":
      case "cancelled":
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        middle: const Text(
          'Commandes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: fetchCommandes,
          child: const Icon(
            CupertinoIcons.refresh,
            size: 22,
          ),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage.isNotEmpty
                ? _buildErrorState()
                : commandes.isEmpty
                    ? _buildEmptyState()
                    : _buildCommandesList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CupertinoActivityIndicator(radius: 14),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: fetchCommandes,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 80,
            color: CupertinoColors.systemGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les commandes apparaîtront ici',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandesList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: fetchCommandes,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCommandeCard(commandes[index]),
              childCount: commandes.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommandeCard(CommandeResto commande) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => CommandeDetailPage(commande: commande),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar avec initiale
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor(commande.status).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        commande.clientName.isNotEmpty
                            ? commande.clientName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(commande.status),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.clientName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${commande.items.length} article${commande.items.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Container(
                height: 0.5,
                color: CupertinoColors.separator,
              ),
              const SizedBox(height: 12),
              // Status et montant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(commande.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      commande.status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(commande.status),
                      ),
                    ),
                  ),
                  Text(
                    '${commande.total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}