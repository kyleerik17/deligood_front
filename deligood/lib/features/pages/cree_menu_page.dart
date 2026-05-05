import 'package:deligood/core/api/menu_service.dart';
import 'package:deligood/features/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// ─────────────────────────────
// DESIGN SYSTEM
// ─────────────────────────────
const kOrange = Color(0xFFFF6B35);
const kBg = Color(0xFFF7F3EF);
const kWhite = Colors.white;
const kTextPrimary = Color(0xFF1A1A1A);
const kSuccess = Color(0xFF4CAF50);
const kError = Color(0xFFFF5A5F);
const kGrey = Color(0xFF9E9E9E);

// ─────────────────────────────
// WIDGETS
// ─────────────────────────────
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator,
    );
  }
}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool loading;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        minimumSize: Size(double.infinity, 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text),
    );
  }
}

class CreateMenuPage extends StatefulWidget {
  final String userRole;

  const CreateMenuPage({super.key, required this.userRole});

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  Uint8List? imageBytes;
  bool loading = false;
  bool loadingCategories = true;

  final picker = ImagePicker();

  final Map<String, IconData> categoryIcons = {
    'Nourriture': Icons.rice_bowl_rounded,
    'Boisson': Icons.local_drink_rounded,
    'Dessert': Icons.cake_rounded,
  };

  @override
  void initState() {
    super.initState();
      SharedPreferences.getInstance().then((p) => p.remove('categories_cache')); // ⚠️ temporaire
  
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => loadingCategories = true);

      final data = await MenuService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;
        loadingCategories = false;
      });

      debugPrint("✅ CATEGORIES LOADED => ${data.length}");
    } catch (e) {
      debugPrint("❌ LOAD CATEGORIES ERROR => $e");

      setState(() {
        categories = [];
        loadingCategories = false;
      });

      _show("Erreur lors du chargement des catégories", true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() => imageBytes = bytes);
      }
    } catch (e) {
      _show("Erreur lors de la sélection de l'image", true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      _show("Choisis une catégorie", true);
      return;
    }

    if (imageBytes == null) {
      _show("Ajoute une image", true);
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
        _show("Plat ajouté avec succès", false);

        nameCtrl.clear();
        descCtrl.clear();
        priceCtrl.clear();

        setState(() {
          imageBytes = null;
          selectedCategory = null;
        });

        Navigator.pop(context, true);
      } else {
        _show(result['message'] ?? "Erreur lors de la création", true);
      }
    } catch (e) {
      _show("Erreur réseau: ${e.toString()}", true);
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? kError : kSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Ajouter un plat",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // IMAGE
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 22.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kOrange),
                  ),
                  child: imageBytes == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: kGrey),
                              SizedBox(height: 10),
                              Text("Ajouter une image", style: TextStyle(color: kGrey)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        ),
                ),
              ),

              SizedBox(height: 3.h),

              // NOM
              CustomTextField(
                controller: nameCtrl,
                labelText: "Nom",
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),

              SizedBox(height: 2.h),

              // DESCRIPTION
              CustomTextField(
                controller: descCtrl,
                labelText: "Description",
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),

              SizedBox(height: 2.h),

              // PRIX
              CustomTextField(
                controller: priceCtrl,
                labelText: "Prix",
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return "Requis";
                  if (int.tryParse(v) == null) return "Prix invalide";
                  return null;
                },
              ),

              SizedBox(height: 3.h),

              // CATEGORIE
              loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? const Text("Aucune catégorie")
                      : DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Catégorie",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIcons[cat['name']] ?? Icons.label,
                                    color: kOrange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat['name']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedCategory = value);
                          },
                        ),

              SizedBox(height: 4.h),

              // SUBMIT
              CustomButton(
                onPressed: _submit,
                text: "Publier",
                loading: loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}