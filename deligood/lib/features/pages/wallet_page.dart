import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deligood/core/network/api.dart';

const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kText = Color(0xFF1A1A1A);

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 0;
  List transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    setState(() => loading = true);
    final data = await ApiService.get('/api/wallet/');

    if (data != null) {
      setState(() {
        balance = double.tryParse(data['balance'].toString()) ?? 0;
        transactions = data['transactions'] ?? [];
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _appBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _BalanceCard(balance: balance),
                      const SizedBox(height: 25),
                      _TransactionHeader(),
                      _TransactionList(transactions: transactions),
                      const SizedBox(height: 30),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _appBar() {
    return SliverAppBar(
      backgroundColor: kBg,
      elevation: 0,
      pinned: true,
      title: Text(
        "Mon portefeuille",
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          color: kText,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kText),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: kText),
          onPressed: fetchWallet,
        )
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [kOrange, kTeal],
        ),
        boxShadow: [
          BoxShadow(
            color: kTeal.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Solde disponible",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${balance.toStringAsFixed(0)} FCFA",
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.money),
              label: const Text("Retirer"),
            ),
          )
        ],
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "Transactions",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (_, i) {
        final tx = transactions[i];
        return _TransactionItem(tx: tx);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: const [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Aucune transaction"),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map tx;

  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type = tx['transaction_type'] ?? 'debit';
    final isCredit = type == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? kTeal : Colors.red)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? kTeal : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['source'] ?? "Transaction",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _format(tx['created_at']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isCredit ? '+' : '-'}${tx['amount']} F",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isCredit ? kTeal : Colors.red,
            ),
          )
        ],
      ),
    );
  }

  String _format(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat("dd MMM yyyy - HH:mm").format(dt);
    } catch (_) {
      return date;
    }
  }
}