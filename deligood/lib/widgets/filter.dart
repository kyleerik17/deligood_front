import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FilterButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
