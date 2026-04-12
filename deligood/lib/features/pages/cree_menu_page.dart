import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateMenuPage extends StatefulWidget {
  final String userRole;
  final int? orderId;

  const CreateMenuPage({super.key, required this.userRole, this.orderId});

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  String? selectedCategory;
  Uint8List? imageBytes;
  bool loading = false;
  final picker = ImagePicker();

  final List<String> categories = ['Nourriture', 'Boisson', 'Dessert'];

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
    }
  }

  void submit() {
  if (!_formKey.currentState!.validate() || selectedCategory == null || imageBytes == null) {
    _showSnackBar("Veuillez remplir tous les champs et l'image", Colors.redAccent);
    return;
  }

  setState(() => loading = true);

  // Ici ton code API pour envoyer le plat
  Future.delayed(const Duration(seconds: 2), () {
    setState(() => loading = false);
    _showSnackBar("Plat publié avec succès !", Colors.green);

    // 🔹 Nouveau : afficher un print et rester sur la page
    print("Plat publié : ${nameCtrl.text}, Catégorie : $selectedCategory, Prix : ${priceCtrl.text} FCFA");
    
    // Pas de Navigator.pop, on reste sur la page
  });
}


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5)),
          ),
          validator: (v) => v!.isEmpty ? 'Ce champ est obligatoire' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ajouter au Menu',
          style: GoogleFonts.poppins(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Image
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.deepOrange),
                              const SizedBox(height: 8),
                              Text("Ajouter une photo du plat",
                                  style: GoogleFonts.poppins(
                                      color: Colors.deepOrange, fontWeight: FontWeight.w500)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Formulaire
              _buildTextField(controller: nameCtrl, label: "Nom du plat", icon: Icons.restaurant_menu),
              const SizedBox(height: 20),

              _buildTextField(
                controller: descCtrl,
                label: "Description",
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Prix + Dropdown catégorie
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: priceCtrl,
                      label: "Prix (FCFA)",
                      icon: Icons.payments_outlined,
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Catégorie",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!)),
                          ),
                          items: categories
                              .map((c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedCategory = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.deepOrange.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('PUBLIER LE PLAT',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
