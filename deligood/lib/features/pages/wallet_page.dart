import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart'; // <-- pour formater la date

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 0.0;
  List transactions = [];
  bool isLoading = true;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchWallet();
  }

  Future<void> _loadTokenAndFetchWallet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
    await fetchWallet();
  }

  Future<void> fetchWallet() async {
    if (accessToken == null) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('https://deligood-backend.onrender.com//api/wallet/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          balance = double.tryParse(data['balance'].toString()) ?? 0.0;
          transactions = data['transactions'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        title: Text(
          'Mon Wallet',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 5.w),
            child: CircleAvatar(
              radius: 5.w,
              backgroundImage: AssetImage('assets/images/n.png'),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= CARD SOLDE =================
                    CardWallet(
                      balance: balance,
                      onWithdraw: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Retrait lancé')),
                        );
                      },
                    ),

                    SizedBox(height: 4.h),

                    // ================= ACTIONS / CONTACTS =================
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(width: 1.w),
                          ActionCircle(
                            icon: Icons.send,
                            label: 'Envoyer',
                            selected: true,
                          ),
                          ActionCircle(
                            icon: Icons.request_page,
                            label: 'Demander',
                          ),
                          ContactCircle(label: 'Jennie'),
                          ContactCircle(label: 'Sawn'),
                          ContactCircle(label: 'Mittali'),
                          SizedBox(width: 1.w),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      'Transactions récentes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // ================= LISTE TRANSACTIONS =================
                    transactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.h),
                              child: Text(
                                'Aucune transaction pour le moment',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontFamily: 'poppins',
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => SizedBox(height: 2.h),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return TransactionTile(
                                amount: tx['amount'],
                                type: tx['transaction_type'],
                                source: tx['source'] ?? '—',
                                date: formatDate(tx['created_at']),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ================= CARD WALLET =================
class CardWallet extends StatelessWidget {
  final double balance;
  final VoidCallback onWithdraw;

  const CardWallet({
    super.key,
    required this.balance,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.w),
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANGE ERIK KYLE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              fontFamily: 'poppins',
            ),
          ),
          Spacer(),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
              fontFamily: 'poppins',
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: 35.w,
            height: 5.h,
            child: ElevatedButton(
              onPressed: onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                shadowColor: Colors.black26,
                elevation: 5,
              ),
              child: Text(
                'Retrait',
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= ACTION CIRCLE =================
class ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected
                  ? LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                    )
                  : null,
              color: selected ? null : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: selected ? Colors.white : Colors.grey),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontFamily: 'poppins'),
          ),
        ],
      ),
    );
  }
}

// ================= CONTACT CIRCLE =================
class ContactCircle extends StatelessWidget {
  final String label;

  const ContactCircle({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        children: [
          CircleAvatar(
            radius: 5.w,
            backgroundColor: Colors.purple.shade50,
            child: Text(
              label[0],
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontFamily: 'poppins'),
          ),
        ],
      ),
    );
  }
}

// ================= TRANSACTION TILE =================
class TransactionTile extends StatelessWidget {
  final String type;
  final dynamic amount;
  final String source;
  final String date;

  const TransactionTile({
    super.key,
    required this.type,
    required this.amount,
    required this.source,
    required this.date,
  });

  Color _getColor() =>
      type == 'credit' ? Colors.green.shade400 : Colors.red.shade400;
  IconData _getIcon() =>
      type == 'credit' ? Icons.arrow_downward : Icons.arrow_upward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 5.w,
            backgroundColor: _getColor().withOpacity(0.15),
            child: Icon(_getIcon(), color: _getColor(), size: 6.w),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$amount F CFA',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'poppins',
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
