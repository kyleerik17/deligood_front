import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SoldePage extends StatelessWidget {
  const SoldePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Text(
                "RECETTES",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 3.h),

              // ===== SOLDE CARD =====
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Cash Balance",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          "Solde",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 1.5.h),

                    Text(
                      "\$684.61",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // ===== RETRAIT BUTTON =====
                    SizedBox(
                      width: double.infinity,
                      child: _actionButton("Retrait"),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // ===== TOTAL + BITCOIN =====
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Aller à la page Transactions
                      },
                      child: _smallCard(
                        title: "TOTAL",
                        amount: "",
                        subtitle: "Voir toutes les transactions",
                        icon: Icons.receipt_long,
                        iconColor: Colors.greenAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _smallCard(
                      title: "Bitcoin",
                      amount: "",
                      subtitle: "Learn and",
                      icon: Icons.currency_bitcoin,
                      iconColor: Colors.blue,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // ===== STOCKS =====
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Stocks",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white38,
                      size: 12.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== ACTION BUTTON =====
  Widget _actionButton(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(2.w),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ===== SMALL CARD =====
  Widget _smallCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white38, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
