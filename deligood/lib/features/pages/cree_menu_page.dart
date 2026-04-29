// lib/pages/create_menu_page.dart
import 'dart:typed_data';
import 'package:deligood/core/api/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────────────────────
// Design System — DeliGood
// ─────────────────────────────────────────────
const kOrange        = Color(0xFFFF6B35);
const kBg            = Color(0xFFF7F3EF);
const kWhite         = Colors.white;
const kTextPrimary   = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF757575);
const kSuccess       = Color(0xFF4CAF50);
const kError         = Color(0xFFFF5A5F);

class CreateMenuPage extends StatefulWidget {
  final String userRole;
  final String token;     // ✅ token JWT de l'utilisateur connecté

  const CreateMenuPage({
    super.key,
    required this.userRole,
    required this.token,
  });

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage>
    with TickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final nameCtrl  = TextEditingController();
  final descCtrl  = TextEditingController();
  final priceCtrl = TextEditingController();

  // ✅ Catégories chargées depuis l'API
  List<Map<String, dynamic>> categories       = [];
  Map<String, dynamic>?      selectedCategory;
  Uint8List?                 imageBytes;
  bool                       loading          = false;
  bool                       loadingCategories = true;

  final picker = ImagePicker();

  final Map<String, IconData> categoryIcons = {
    'Nourriture': Icons.rice_bowl_rounded,
    'Boisson':    Icons.local_drink_rounded,
    'Dessert':    Icons.cake_rounded,
  };

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCategories();  // ✅ Charge les catégories au démarrage
  }

  void _initAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnimation  = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  // ✅ Chargement des catégories depuis l'API
  Future<void> _loadCategories() async {
    final data = await MenuService.getCategories();
    setState(() {
      categories        = data;
      loadingCategories = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
    }
  }

  // ✅ Soumission réelle vers l'API Django
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (selectedCategory == null) {
      _showSnackBar('Veuillez sélectionner une catégorie', isError: true);
      return;
    }
    if (imageBytes == null) {
      _showSnackBar('Veuillez ajouter une photo du plat', isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      final result = await MenuService.createMenuItem(
        token:       widget.token,
        name:        nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        price:       int.parse(priceCtrl.text),
        categoryId:  selectedCategory!['id'] as int,
        imageBytes:  imageBytes,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar('Plat publié avec succès !', isError: false);

        // ✅ Réinitialise le formulaire
        nameCtrl.clear();
        descCtrl.clear();
        priceCtrl.clear();
        setState(() {
          imageBytes       = null;
          selectedCategory = null;
        });

        // ✅ Retourne true pour déclencher un refresh sur la page précédente
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        // Affiche les erreurs de validation renvoyées par Django
        final errors = result['errors'] as Map<String, dynamic>;
        final message = errors.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        _showSnackBar(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur réseau : vérifiez votre connexion', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: kWhite, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(fontSize: 13, color: kWhite)),
          ),
        ]),
        backgroundColor: isError ? kError : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: kTextPrimary),
            ),
          ),
        ),
        title: Text(
          'Ajouter un plat',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePicker(),
                  SizedBox(height: 3.h),
                  _buildSectionTitle('Informations du plat', Icons.restaurant_menu_rounded),
                  SizedBox(height: 1.5.h),
                  _buildField(
                    controller: nameCtrl,
                    label: 'Nom du plat',
                    icon: Icons.fastfood_rounded,
                    hint: 'Ex: Attiéké poisson braisé',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ce champ est obligatoire' : null,
                  ),
                  SizedBox(height: 1.5.h),
                  _buildField(
                    controller: descCtrl,
                    label: 'Description',
                    icon: Icons.notes_rounded,
                    hint: 'Décrivez le plat en quelques mots…',
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ce champ est obligatoire' : null,
                  ),
                  SizedBox(height: 3.h),
                  _buildSectionTitle('Prix & Catégorie', Icons.sell_rounded),
                  SizedBox(height: 1.5.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          controller: priceCtrl,
                          label: 'Prix (FCFA)',
                          icon: Icons.payments_rounded,
                          hint: '1500',
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (int.tryParse(v) == null) return 'Invalide';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        flex: 3,
                        child: loadingCategories
                            ? const Center(child: CircularProgressIndicator(color: kOrange))
                            : _buildCategoryPicker(),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  _buildSubmitButton(),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 22.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: imageBytes != null ? kOrange : kOrange.withOpacity(0.25),
            width: imageBytes != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded,
                        size: 32, color: kOrange),
                  ),
                  SizedBox(height: 1.2.h),
                  Text('Ajouter une photo du plat',
                      style: GoogleFonts.poppins(
                          color: kOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp)),
                  SizedBox(height: 0.4.h),
                  Text('JPG, PNG — qualité recommandée',
                      style: GoogleFonts.poppins(
                          color: kTextSecondary, fontSize: 10.sp)),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity),
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, color: kWhite, size: 14),
                          const SizedBox(width: 4),
                          Text('Changer',
                              style: GoogleFonts.poppins(
                                  color: kWhite,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ Catégories chargées dynamiquement depuis l'API
  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catégorie',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, color: Colors.grey.shade500)),
        SizedBox(height: 0.6.h),
        Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedCategory != null
                  ? kOrange
                  : Colors.grey.shade200,
              width: selectedCategory != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kOrange),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.6.h),
                prefixIcon: Icon(
                  selectedCategory != null
                      ? (categoryIcons[selectedCategory!['name']] ??
                          Icons.category_rounded)
                      : Icons.category_rounded,
                  color: kOrange,
                  size: 20,
                ),
              ),
              hint: Text('Choisir',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp, color: Colors.grey.shade400)),
              style: GoogleFonts.poppins(
                  fontSize: 12.sp, color: kTextPrimary),
              items: categories.map((cat) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: cat,
                  child: Row(children: [
                    Icon(
                      categoryIcons[cat['name']] ?? Icons.category_rounded,
                      size: 16,
                      color: kOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(cat['name'] as String),
                  ]),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13.sp, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kOrange, size: 20),
        labelStyle:
            GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
        hintStyle:
            GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade400),
        errorStyle: GoogleFonts.poppins(fontSize: 10.sp, color: kError),
        filled: true,
        fillColor: kWhite,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kError, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.5.h,
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrange,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: kWhite, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: kWhite, size: 20),
                  SizedBox(width: 2.w),
                  Text(
                    'Publier le plat',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kOrange, size: 16),
      ),
      SizedBox(width: 2.w),
      Text(title,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          )),
    ]);
  }
}