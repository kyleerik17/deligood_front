import 'package:deligood/features/auth/widgets/logout.dart';
import 'package:deligood/features/pages/info_perso.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key,});
  

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String initials = '?';

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    print('🧠 Chargement des infos utilisateur depuis SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();

    final fName = prefs.getString('first_name');
    final lName = prefs.getString('last_name');
    final phone = prefs.getString('phone_number');

    print('📌 first_name: $fName');
    print('📌 last_name: $lName');
    print('📌 phone_number: $phone');

    setState(() {
      firstName = fName ?? '';
      lastName = lName ?? '';
      phoneNumber = phone ?? '';
      initials = _buildInitials(firstName, lastName);
    });

    print(
      '✅ State mis à jour: $firstName, $lastName, $phoneNumber, initials: $initials',
    );
  }

  String _buildInitials(String fName, String lName) {
    if (fName.isNotEmpty && lName.isNotEmpty) {
      return '${fName[0]}${lName[0]}'.toUpperCase();
    }
    if (fName.isNotEmpty) return fName[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${firstName.isEmpty ? '' : firstName} ${lastName.isEmpty ? '' : lastName}'
            .trim();

    print(
      '🖥 Construction UI avec: fullName="$fullName", phone="$phoneNumber"',
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(height: 9.h, color: const Color(0xFFEA7C17)),
                  Text(
                    "Profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 19.sp,
                      fontFamily: "Poppins",
                      letterSpacing: 0.9,
                    ),
                  ),
                  Positioned(
                    right: 4.w,
                    bottom: 1.h,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        
                        padding: EdgeInsets.all(0.w),
                        child: Icon(
                          Icons.forward,
                          size: 12.w,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(6.h),
              CircleAvatar(
                radius: 10.w,
                backgroundColor: Colors.black,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              Gap(1.h),
              Text(
                fullName.isEmpty ? 'Utilisateur' : fullName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Gap(0.5.h),
              Text(
                phoneNumber.isEmpty ? '—' : phoneNumber,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7F7F7F),
                ),
              ),
              Gap(6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                    OptionRow(
                      title: "Modifier profil",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InfoPersoPage(), // Assure-toi que ta page InfoPerso existe
                          ),
                        );
                      },
                    ),

                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                    OptionRow(title: "Recettes", onTap: () {}),
                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                    OptionRow(title: "Conditions d'utilisation", onTap: () {}),
                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                    OptionRow(
                      title: "Politique de confidentialité",
                      onTap: () {},
                    ),
                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                    OptionRow(title: "Nous contacter", onTap: () {}),
                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
               OptionRow(
  title: "Déconnexion",
  onTap: () async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getInt('last_order_id'); // si tu veux garder la dernière commande
    await LogoutService.performLogout(context, orderId: orderId);
  },
),


                    Divider(color: Colors.grey.shade300, thickness: 2),
                    Gap(2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const OptionRow({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
