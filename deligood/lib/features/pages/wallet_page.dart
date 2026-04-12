import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:deligood/core/network/api.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 0.0;
  List transactions = [];
  bool isLoading = true;
  bool isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    setState(() => isLoading = true);

    try {
      final data = await Api.get('/api/wallet/');
      if (data != null) {
        setState(() {
          balance = double.tryParse(data['balance'].toString()) ?? 0.0;
          transactions = data['transactions'] ?? [];
        });
      }
    } catch (e) {
      _showError('Impossible de charger les données');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
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

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Retrait'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solde disponible: ${balance.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Montant à retirer',
                keyboardType: TextInputType.number,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('FCFA'),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0 && amount <= balance) {
                Navigator.pop(context);
                _processWithdrawal(amount);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    setState(() => isWithdrawing = true);
    
    // Simuler l'appel API
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => isWithdrawing = false);
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Succès'),
          content: Text('Retrait de ${amount.toStringAsFixed(0)} FCFA en cours de traitement'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                fetchWallet();
              },
            ),
          ],
        ),
      );
    }
  }

  String formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inDays == 0) {
        return "Aujourd'hui ${DateFormat('HH:mm').format(dt)}";
      } else if (diff.inDays == 1) {
        return "Hier ${DateFormat('HH:mm').format(dt)}";
      } else if (diff.inDays < 7) {
        return DateFormat('EEE HH:mm', 'fr').format(dt);
      } else {
        return DateFormat('dd/MM/yy').format(dt);
      }
    } catch (_) {
      return date;
    }
  }

  Color _getTransactionColor(String type) {
    return type == 'credit' 
        ? CupertinoColors.systemGreen 
        : CupertinoColors.systemRed;
  }

  IconData _getTransactionIcon(String type) {
    return type == 'credit' 
        ? CupertinoIcons.arrow_down_circle_fill
        : CupertinoIcons.arrow_up_circle_fill;
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
          'Portefeuille',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: fetchWallet,
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        
                        // Balance Card
                        _buildBalanceCard(),
                        
                        const SizedBox(height: 32),
                        
                        // Transactions Section
                        _buildTransactionsSection(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Bleu marine profond
            Color(0xFF3B82F6), // Bleu vif
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FCFA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            balance.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              onPressed: isWithdrawing ? null : _showWithdrawDialog,
              child: isWithdrawing
                  ? const CupertinoActivityIndicator(
                      color: Color(0xFF3B82F6),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.money_dollar_circle,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Effectuer un retrait',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'HISTORIQUE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          transactions.isEmpty
              ? _buildEmptyTransactions()
              : Column(
                  children: transactions.map((tx) {
                    return _buildTransactionItem(tx);
                  }).toList(),
                ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 56,
              color: CupertinoColors.systemGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune transaction',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vos transactions apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final type = tx['transaction_type'] ?? 'debit';
    final amount = tx['amount'];
    final source = tx['source'] ?? 'Transaction';
    final date = formatDate(tx['created_at'] ?? '');
    final color = _getTransactionColor(type);
    final icon = _getTransactionIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Amount
          Text(
            '${type == 'credit' ? '+' : '-'}$amount F',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}