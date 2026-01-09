import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HistoriquePage extends StatelessWidget {
  const HistoriquePage({super.key,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Historique",
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
    );
  }
}
