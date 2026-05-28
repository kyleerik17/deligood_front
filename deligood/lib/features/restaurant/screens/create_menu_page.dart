import 'package:deligood/core/api/menu_service.dart';
import 'package:deligood/features/auth/providers/auth_state.dart';
import 'package:deligood/features/restaurant/screens/commande_resto_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kOrangeSoft = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF7F3EF);
const _kWhite = Colors.white;
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF9E9E9E);
const _kSuccess = Color(0xFF27AE60);
const _kError = Color(0xFFFF5A5F);
const _kBorder = Color(0xFFEAE5E0);

class CreateMenuPage extends StatefulWidget {
  final String userRole;
  const CreateMenuPage({super.key, required this.userRole});

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;
  Uint8List? imageBytes;
  bool loading = false;
  bool loadingCategories = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final picker = ImagePicker();

  final Map<String, IconData> categoryIcons = {
    'Nourriture': Icons.rice_bowl_rounded,
    'Boisson': Icons.local_drink_rounded,
    'Dessert': Icons.cake_rounded,
  };

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _loadCategories();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await MenuService.getCategories();
      if (!mounted) return;
      setState(() {
        categories = data;
        loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingCategories = false);
      _show("Impossible de charger les catégories", isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() => imageBytes = bytes);
      }
    } catch (_) {
      _show("Erreur lors de la sélection", isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      _show("Sélectionne une catégorie", isError: true);
      return;
    }
    if (imageBytes == null) {
      _show("Ajoute une photo du plat", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      final result = await MenuService.createMenuItem(
        token: AuthState.instance.token,
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        price: int.tryParse(priceCtrl.text) ?? 0,
        categoryId: selectedCategory!['id'],
        imageBytes: imageBytes,
      );

      if (result['success'] == true) {
        _show("Plat publié avec succès ✓");
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => CommandeRestoPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
          (route) => false,
        );
      } else {
        _show(result['message'] ?? "Échec de la publication", isError: true);
      }
    } catch (e) {
      _show("Erreur réseau : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: _kWhite,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.dmSans(
                  color: _kWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _kError : _kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      ),
    );
  }

  // ─────────────────────────────
  // BUILD
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 3.h),
                        _buildImagePicker(),
                        SizedBox(height: 3.5.h),
                        _sectionLabel("Informations"),
                        SizedBox(height: 1.5.h),
                        _buildField(
                          controller: nameCtrl,
                          label: "Nom du plat",
                          hint: "Ex: Poulet braisé sauce tomate",
                          icon: Icons.restaurant_menu_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Requis" : null,
                        ),
                        SizedBox(height: 1.5.h),
                        _buildField(
                          controller: descCtrl,
                          label: "Description",
                          hint: "Décris le plat, les ingrédients...",
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Requis" : null,
                        ),
                        SizedBox(height: 1.5.h),
                        _buildField(
                          controller: priceCtrl,
                          label: "Prix (FCFA)",
                          hint: "Ex: 2500",
                          icon: Icons.payments_rounded,
                          keyboardType: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Requis";
                            if (int.tryParse(v) == null) return "Invalide";
                            return null;
                          },
                          suffix: _priceBadge(),
                        ),
                        SizedBox(height: 3.h),
                        _sectionLabel("Catégorie"),
                        SizedBox(height: 1.5.h),
                        _buildCategoryPicker(),
                        SizedBox(height: 4.h),
                        _buildSubmitButton(),
                        SizedBox(height: 5.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // APPBAR
  // ─────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _kBg,
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _kWhite,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _kTextPrimary,
            ),
          ),
        ),
      ),
      title: Text(
        "Nouveau plat",
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: _kTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─────────────────────────────
  // IMAGE PICKER
  // ─────────────────────────────
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 22.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: imageBytes != null ? Colors.transparent : _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: imageBytes != null ? _kOrange : _kBorder,
            width: imageBytes != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kOrangeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 28,
                      color: _kOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Ajouter une photo",
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "JPG, PNG — Qualité recommandée",
                    style: GoogleFonts.dmSans(
                      color: _kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(imageBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => imageBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _kWhite,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: _kWhite,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Changer",
                              style: GoogleFonts.dmSans(
                                color: _kWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────
  // TEXT FIELD
  // ─────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.dmSans(
        color: _kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          color: _kTextSecondary.withOpacity(0.6),
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.dmSans(color: _kTextSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: _kOrange, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _kWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: maxLines > 1 ? 2.h : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kError, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // PRICE BADGE
  // ─────────────────────────────
  Widget _priceBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kOrangeSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "FCFA",
            style: GoogleFonts.dmSans(
              color: _kOrange,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // CATEGORY PICKER
  // ─────────────────────────────
  Widget _buildCategoryPicker() {
    if (loadingCategories) {
      return Container(
        height: 7.h,
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: _kTextSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              "Aucune catégorie disponible",
              style: GoogleFonts.dmSans(color: _kTextSecondary, fontSize: 13),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loadCategories,
              child: Text(
                "Réessayer",
                style: GoogleFonts.dmSans(
                  color: _kOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: selectedCategory,
      isExpanded: true,
      style: GoogleFonts.dmSans(
        color: _kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kOrange),
      decoration: InputDecoration(
        labelText: "Catégorie",
        labelStyle: GoogleFonts.dmSans(color: _kTextSecondary, fontSize: 13),
        prefixIcon: const Icon(
          Icons.category_rounded,
          color: _kOrange,
          size: 20,
        ),
        filled: true,
        fillColor: _kWhite,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kOrangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryIcons[cat['name']] ?? Icons.label_rounded,
                  color: _kOrange,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(cat['name']),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedCategory = value),
      validator: (v) => v == null ? "Sélectionne une catégorie" : null,
    );
  }

  // ─────────────────────────────
  // SUBMIT
  // ─────────────────────────────
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: loading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 6.5.h,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: loading ? _kBorder : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: _kOrange.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _kOrange,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rocket_launch_rounded,
                      color: _kWhite,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Publier le plat",
                      style: GoogleFonts.dmSans(
                        color: _kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // SECTION LABEL
  // ─────────────────────────────
  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kTextSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
