import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTapIcon;
  final Function(String)? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onTapIcon,
    this.onChanged, required String placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher',
          hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          prefixIcon: GestureDetector(
            onTap: onTapIcon,
            child: Icon(Icons.search, color: Colors.grey.shade700),
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
