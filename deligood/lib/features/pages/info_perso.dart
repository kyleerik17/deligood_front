import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// ================== DESIGN SYSTEM ==================
const kOrange     = Color(0xFFFF6B35);
const kOrangeDark = Color(0xFFFF5722);
const kTeal       = Color(0xFF00CCBC);
const kTealDark   = Color(0xFF00A896);
const kBg         = Color(0xFFF7F3EF);
const kCard       = Colors.white;
const kText       = Color(0xFF1A1A1A);
const kSubText    = Color(0xFF757575);
const kError      = Color(0xFFFF5A5F);

class InfoPersoPage extends StatefulWidget {
  const InfoPersoPage({super.key});

  @override
  State<InfoPersoPage> createState() => _InfoPersoPageState();
}

class _InfoPersoPageState extends State<InfoPersoPage>
    with TickerProviderStateMixin {

  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  Uint8List? _avatar;
  Uint8List? _permit;
  bool _modified = false;
  bool _loading  = false;
  String _userType = '';

  final _picker = ImagePicker();

  late AnimationController _entryCtrl;
  late AnimationController _saveCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _saveFade;

  @override
  void initState() {
    super.initState();

    // Entrée page
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    // Bouton save
    _saveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _saveFade = CurvedAnimation(parent: _saveCtrl, curve: Curves.easeOut);

    _load();
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _saveCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ================== LOAD ==================
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _firstCtrl.text = prefs.getString('first_name')   ?? '';
      _lastCtrl.text  = prefs.getString('last_name')    ?? '';
      _phoneCtrl.text = prefs.getString('phone_number') ?? '';
      _emailCtrl.text = prefs.getString('email')        ?? '';
      _userType       = prefs.getString('user_type')    ?? '';

      final a = prefs.getString('avatar_base64');
      if (a != null && a.isNotEmpty) {
        try { _avatar = base64Decode(a); } catch (_) {}
      }
    });
  }

  void _mark() {
    if (!_modified) {
      setState(() => _modified = true);
      _saveCtrl.forward();
    }
  }

  // ================== PICK IMAGE ==================
  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _avatar   = bytes;
      _modified = true;
    });
    _saveCtrl.forward();
  }

  Future<void> _pickPermit() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _permit   = bytes;
      _modified = true;
    });
    _saveCtrl.forward();
  }

  // ================== SAVE ==================
  Future<void> _save() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name',   _firstCtrl.text.trim());
    await prefs.setString('last_name',    _lastCtrl.text.trim());
    await prefs.setString('phone_number', _phoneCtrl.text.trim());
    await prefs.setString('email',        _emailCtrl.text.trim());

    if (_avatar != null) {
      await prefs.setString('avatar_base64', base64Encode(_avatar!));
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _loading  = false;
      _modified = false;
    });
    _saveCtrl.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 2.w),
            Text(
              "Profil mis à jour ✨",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String get _initials {
    final f = _firstCtrl.text;
    final l = _lastCtrl.text;
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        SizedBox(height: 1.h),
                        _buildFormSection(),
                        if (_userType == 'livreur') ...[
                          SizedBox(height: 1.h),
                          _buildPermitSection(),
                        ],
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ================== APP BAR ==================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 22.h,
      pinned: true,
      elevation: 0,
      backgroundColor: kOrange,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kOrange, kOrangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Bulle décorative haut droite
              Positioned(
                top: -4.h,
                right: -8.w,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Bulle décorative bas gauche
              Positioned(
                bottom: -2.h,
                left: -4.w,
                child: Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Titre centré
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Mes informations",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        "Gérez votre profil personnel",
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== AVATAR ==================
  Widget _buildAvatarSection() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Anneau décoratif extérieur
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kOrange.withOpacity(0.3),
                  width: 3,
                ),
              ),
            ),

            // Avatar
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _avatar == null
                        ? const LinearGradient(
                            colors: [kOrange, Color(0xFFFF8A50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: kOrange.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _avatar != null
                      ? ClipOval(
                          child: Image.memory(_avatar!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            _initials,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Bouton caméra
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: kOrange, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: kOrange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== FORM ==================
  Widget _buildFormSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Informations personnelles"),
          SizedBox(height: 1.5.h),

          _buildCard([
            _buildField(
              controller: _firstCtrl,
              label: "Prénom",
              icon: Icons.person_outline,
            ),
            _divider(),
            _buildField(
              controller: _lastCtrl,
              label: "Nom",
              icon: Icons.badge_outlined,
            ),
          ]),

          SizedBox(height: 2.h),
          _sectionTitle("Coordonnées"),
          SizedBox(height: 1.5.h),

          _buildCard([
            _buildField(
              controller: _phoneCtrl,
              label: "Téléphone",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _divider(),
            _buildField(
              controller: _emailCtrl,
              label: "Email",
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 1.w),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: kOrange,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _mark(),
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          color: kText,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: kSubText,
          ),
          prefixIcon: Icon(icon, color: kOrange, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 14.w,
      endIndent: 4.w,
      color: Colors.grey.shade100,
    );
  }

  // ================== PERMIS ==================
  Widget _buildPermitSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Documents"),
          SizedBox(height: 1.5.h),
          GestureDetector(
            onTap: _pickPermit,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, color: kTeal, size: 22),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Permis / Document",
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                        Text(
                          _permit != null
                              ? "Document sélectionné ✓"
                              : "Appuyez pour sélectionner",
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: _permit != null ? kTeal : kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: kSubText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== SAVE BUTTON ==================
  Widget _buildSaveButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _saveFade,
        child: Container(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur drag
                Container(
                  width: 10.w,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      disabledBackgroundColor: kOrange.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, color: Colors.white),
                              SizedBox(width: 2.w),
                              Text(
                                "Enregistrer les modifications",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 1.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}