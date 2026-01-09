import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoPersoPage extends StatefulWidget {
  const InfoPersoPage({super.key});

  @override
  State<InfoPersoPage> createState() => _InfoPersoPageState();
}

class _InfoPersoPageState extends State<InfoPersoPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _phoneController.text = prefs.getString('phone_number') ?? '';
      // On peut stocker séparément jour, mois, année si tu l'as déjà sauvegardé
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(2.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEBEBEB),
                  ),
                  padding: EdgeInsets.all(0.w),
                  child: Icon(Icons.close, size: 12.w, color: Colors.black),
                ),
              ),
              Gap(2.h),
              Text('Parlez-nous de vous', style: TextStyle(fontSize: 23.sp)),
              Gap(3.h),
              Text(
                'Information personnelle',
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
              ),
              Divider(color: Colors.grey[600]),
              Gap(1.h),

              // Prénom
              Text(
                'Prénom *',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
              Gap(1.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(1.h),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(2.w),
                  ),
                ),
              ),
              Gap(2.h),

              // Nom
              Text(
                'Nom *',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
              Gap(1.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(1.h),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(2.w),
                  ),
                ),
              ),
              Gap(2.h),
              // Téléphone
              Text(
                'Numéro de téléphone *',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
              Gap(1.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(1.h),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: '+225 05 65 838 385',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(3.w),
                  ),
                ),
              ),
              Gap(4.h),
            ],
          ),
        ),
      ),
    );
  }
}
