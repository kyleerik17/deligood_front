import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/features/client/screens/Home_screen.dart';

class CreateMenuPage extends StatefulWidget {
  final String userRole;
  final int orderId;

  const CreateMenuPage({
    super.key,
    required this.userRole,
    required this.orderId,
  });

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  int? categoryId;
  Uint8List? imageBytes;
  bool loading = false;

  final picker = ImagePicker();

  final categories = [
    {'id': 1, 'name': 'Boisson'},
    {'id': 2, 'name': 'Nourriture'},
    {'id': 3, 'name': 'Dessert'},
  ];

  @override
  void initState() {
    super.initState();
    print("=== CreateMenuPage ouverte ===");
  }

  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
      print(
        "Image choisie: ${img.name}, taille: ${bytes.lengthInBytes} octets",
      );
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'access_token': prefs.getString('access_token'),
      'user_type': prefs.getString('user_type'),
      'restaurant_id': prefs.getInt('restaurant_id'),
    };
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() || categoryId == null) return;

    setState(() => loading = true);

    final userData = await getUserData();
    final token = userData['access_token'];
    final userType = userData['user_type'];

    if (token == null || userType != 'restaurant') {
      setState(() => loading = false);
      return;
    }

    final uri = Uri.parse('${Api.baseUrl}/api/menu/create/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = Api.authHeaderValue(token)
      ..fields['name'] = nameCtrl.text
      ..fields['description'] = descCtrl.text
      ..fields['price'] = priceCtrl.text
      ..fields['category'] = categoryId.toString();

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes!,
          filename: 'plat.png',
        ),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      setState(() => loading = false);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plat créé avec succès')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(orderId: widget.orderId),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $respStr')));
      }
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.orange[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Créer un plat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameCtrl,
                  style: GoogleFonts.poppins(),
                  decoration: inputDecoration.copyWith(labelText: 'Nom'),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(),
                  decoration: inputDecoration.copyWith(labelText: 'Prix'),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(
                            c['name'] as String,
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      )
                      .toList(),
                  decoration: inputDecoration.copyWith(labelText: 'Catégorie'),
                  onChanged: (v) => setState(() => categoryId = v),
                  validator: (v) => v == null ? 'Choisir une catégorie' : null,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.deepOrange),
                      color: Colors.orange[50],
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: imageBytes == null
                        ? Center(
                            child: Text(
                              'Choisir une image',
                              style: GoogleFonts.poppins(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: Colors.deepOrangeAccent,
                      elevation: 6,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Créer',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
