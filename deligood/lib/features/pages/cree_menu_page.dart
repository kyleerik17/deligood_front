import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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

  int? categoryId;
  Uint8List? imageBytes;
  bool loading = false;
  List<Map<String, dynamic>> categories = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  // ---------------------- PICK IMAGE ----------------------
  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
    }
  }

  // ---------------------- FETCH CATEGORIES ----------------------
  Future<void> fetchCategories() async {
    final uri = Uri.parse('http://127.0.0.1:8000/api/menu/categories/');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          categories = data
              .map((c) => {'id': c['id'] as int, 'name': c['name'] as String})
              .toList();
        });
      } else {
        print('Erreur récupération catégories: ${response.body}');
      }
    } catch (e) {
      print('Erreur réseau categories: $e');
    }
  }

  // ---------------------- GET USER DATA ----------------------
  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('access_token'),
      'user_type': prefs.getString('user_type')?.toLowerCase(),
      'restaurant_id': prefs.getInt('restaurant_id'),
    };
  }

  // ---------------------- SUBMIT FORM ----------------------
  Future<void> submit() async {
  if (!_formKey.currentState!.validate() || categoryId == null) {
    print("⚠️ Formulaire incomplet !");
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Formulaire incomplet")));
    return;
  }

  setState(() => loading = true);

  final userData = await _getUserData();
  final token = userData['token'];
  final userType = userData['user_type'];
  final restaurantId = userData['restaurant_id'];

  print("🔹 Token: $token");
  print("🔹 UserType: $userType");
  print("🔹 RestaurantId: $restaurantId");

  if (token == null || userType != 'restaurant' || restaurantId == null) {
    setState(() => loading = false);
    String msg = token == null
        ? "Token manquant. Connectez-vous à nouveau."
        : (userType != 'restaurant'
            ? "Accès refusé pour ce compte."
            : "Restaurant non associé au compte.");
    print("⚠️ $msg");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    return;
  }

  print("🔹 Nom: ${nameCtrl.text}");
  print("🔹 Description: ${descCtrl.text}");
  print("🔹 Prix: ${priceCtrl.text}");
  print("🔹 Catégorie: $categoryId");
  print("🔹 Image sélectionnée: ${imageBytes != null ? 'Oui' : 'Non'}");

  final uri = Uri.parse('http://127.0.0.1:8000/api/menu/create/');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Token $token'
    ..fields['name'] = nameCtrl.text.trim()
    ..fields['description'] = descCtrl.text.trim()
    ..fields['price'] = priceCtrl.text.trim()
    ..fields['category'] = categoryId.toString()
    ..fields['restaurant'] = restaurantId.toString();

  if (imageBytes != null) {
    print("🔹 Ajout de l'image au request");
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes!,
      filename: 'plat.png',
    ));
  }

  try {
    final response = await request.send();
    final body = await response.stream.bytesToString();
    setState(() => loading = false);

    print("🔹 Status code: ${response.statusCode}");
    print("🔹 Response body: $body");

    if (response.statusCode == 201) {
      if (!mounted) return;
      print("✅ Plat créé avec succès !");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Plat créé avec succès")));
      Navigator.pop(context);
    } else {
      print("❌ Erreur serveur !");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur serveur : $body")));
    }
  } catch (e) {
    setState(() => loading = false);
    print("❌ Erreur réseau: $e");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Erreur réseau : $e")));
  }
}


  // ---------------------- BUILD ----------------------
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
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
                  decoration: inputDecoration.copyWith(labelText: 'Nom'),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: inputDecoration.copyWith(labelText: 'Description'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration.copyWith(labelText: 'Prix'),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: inputDecoration.copyWith(labelText: 'Catégorie'),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']!),
                        ),
                      )
                      .toList(),
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
                    ),
                    child: imageBytes == null
                        ? const Center(child: Text('Choisir une image'))
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
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Créer',
                            style: TextStyle(
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
