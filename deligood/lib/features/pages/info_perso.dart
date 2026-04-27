import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================== DESIGN SYSTEM ==================
const kOrange = Color(0xFFFF6B35);
const kTeal = Color(0xFF00CCBC);
const kBg = Color(0xFFF7F3EF);
const kCard = Colors.white;
const kText = Color(0xFF1A1A1A);
const kSubText = Colors.grey;

// ================== PAGE ==================
class InfoPersoPage extends StatefulWidget {
  const InfoPersoPage({super.key});

  @override
  State<InfoPersoPage> createState() => _InfoPersoPageState();
}

class _InfoPersoPageState extends State<InfoPersoPage>
    with SingleTickerProviderStateMixin {
  final first = TextEditingController();
  final last = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  Uint8List? avatar;
  Uint8List? permit;
  bool modified = false;
  bool loading = false;

  String userType = "";
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _mark() => setState(() => modified = true);

  // ================== LOAD ==================
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      first.text = prefs.getString("first_name") ?? "";
      last.text = prefs.getString("last_name") ?? "";
      phone.text = prefs.getString("phone") ?? "";
      email.text = prefs.getString("email") ?? "";
      userType = prefs.getString("user_type") ?? "";

      final a = prefs.getString("avatar");
      if (a != null) avatar = base64Decode(a);
    });
  }

  // ================== PICK IMAGE ==================
  Future<void> pickAvatar() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    avatar = await img.readAsBytes();
    setState(() => modified = true);
  }

  Future<void> pickPermit() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    permit = await img.readAsBytes();
    setState(() => modified = true);
  }

  // ================== SAVE ==================
  Future<void> save() async {
    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("first_name", first.text);
    await prefs.setString("last_name", last.text);
    await prefs.setString("phone", phone.text);

    if (avatar != null) {
      await prefs.setString("avatar", base64Encode(avatar!));
    }

    setState(() {
      loading = false;
      modified = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kTeal,
          content: const Text("Profil mis à jour ✨"),
        ),
      );
    }
  }

  String get initials {
    if (first.text.isNotEmpty && last.text.isNotEmpty) {
      return "${first.text[0]}${last.text[0]}".toUpperCase();
    }
    return "?";
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _header(),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _avatarSection(),
                    _formSection(),
                    if (userType == "livreur") _permitSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          if (modified) _bottomSave(),
        ],
      ),
    );
  }

  // ================== HEADER ==================
  Widget _header() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kTeal, kOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text("Profil",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ================== AVATAR ==================
  Widget _avatarSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: GestureDetector(
          onTap: pickAvatar,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: avatar == null
                  ? const LinearGradient(
                      colors: [kTeal, kOrange],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                )
              ],
            ),
            child: avatar != null
                ? ClipOval(child: Image.memory(avatar!, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ================== FORM ==================
  Widget _formSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _field(first, "Prénom"),
          _field(last, "Nom"),
          _field(phone, "Téléphone"),
          _field(email, "Email"),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        onChanged: (_) => _mark(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ================== PERMIT ==================
  Widget _permitSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: pickPermit,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.file_copy, color: kTeal),
              const SizedBox(width: 10),
              const Expanded(child: Text("Permis / Document")),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // ================== SAVE BUTTON ==================
  Widget _bottomSave() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: loading ? null : save,
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Enregistrer"),
          ),
        ),
      ),
    );
  }
}