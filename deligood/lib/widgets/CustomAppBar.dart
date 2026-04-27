import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';

// ================= LOGOUT =================
Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Supprime toutes les données utilisateur

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) =>  LoginScreen(onLoginSuccess: (String type) {  },)),
    (route) => false,
  );
}

// ================= CUSTOM APPBAR =================
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(7.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Ouvre le drawer
            },
          );
        },
      ),
      title: Center(
        child: Text(
          "DeliGood",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ================= DRAWER =================
Drawer buildAppDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.deepOrange,
          ),
          child: Center(
            child: Text(
              "DeliGood",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Déconnexion"),
          onTap: () => logout(context),
        ),
      ],
    ),
  );
}


