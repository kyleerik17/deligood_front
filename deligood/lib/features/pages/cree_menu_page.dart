import 'dart:typed_data';
import 'package:deligood/features/client/screens/Home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ===========================================
// GÉRER LE TOKEN ET USER_TYPE
// ===========================================
Future<void> saveUserData(
  String token,
  String userType,
  int restaurantId,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', token);
  await prefs.setString('user_type', userType);
  await prefs.setInt('restaurant_id', restaurantId);
  print(
    'Token, user_type et restaurant_id sauvegardés: $token, $userType, $restaurantId',
  );
}

Future<Map<String, dynamic>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final userType = prefs.getString('user_type');
  final restaurantId = prefs.getInt('restaurant_id');
  print('Token récupéré: $token');
  print('User type récupéré: $userType');
  print('Restaurant ID récupéré: $restaurantId');
  return {
    'access_token': token,
    'user_type': userType,
    'restaurant_id': restaurantId,
  };
}

// ===========================================
// CREATE MENU PAGE
// ===========================================
class CreateMenuPage extends StatefulWidget {
  final String userRole;
  final int orderId; // Id de la commande
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

  // ===========================================
  // PICK IMAGE
  // ===========================================
  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
      print('Image choisie, taille: ${bytes.lengthInBytes} octets');
    } else {
      print('Aucune image choisie');
    }
  }

  // ===========================================
  // SUBMIT MENU
  // ===========================================
  Future<void> submit() async {
    print('--- SUBMIT CLICK ---');
    if (!_formKey.currentState!.validate() || categoryId == null) {
      print('Formulaire invalide ou catégorie non choisie');
      return;
    }

    setState(() => loading = true);

    // Récupération du token, user_type et restaurant_id
    final userData = await getUserData();
    final token = userData['access_token'];
    final userType = userData['user_type'];
    final restaurantId = userData['restaurant_id'];

    if (token == null || restaurantId == null) {
      print('Erreur: token ou restaurant_id null');
      setState(() => loading = false);
      return;
    }

    if (userType != 'restaurant') {
      print('Erreur: utilisateur non autorisé');
      setState(() => loading = false);
      return;
    }

    final uri = Uri.parse('http://deligood-production.up.railway.app/create/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Token $token';

    request.fields['name'] = nameCtrl.text;
    request.fields['description'] = descCtrl.text;
    request.fields['price'] =
        priceCtrl.text; // string pour correspondre au backend
    request.fields['category'] = categoryId.toString();
    request.fields['restaurant'] = restaurantId.toString(); // dynamique

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes!,
          filename: 'plat.png',
        ),
      );
      print('Image ajoutée au formulaire');
    }

    try {
      final response = await request.send();
      setState(() => loading = false);

      final respStr = await response.stream.bytesToString();
      print('Status code: ${response.statusCode}');
      print('Réponse serveur: $respStr');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plat créé avec succès')));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(orderId: widget.orderId),
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $respStr')));
      }
    } catch (e) {
      print('Exception: $e');
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
    }
  }

  // ===========================================
  // BUILD
  // ===========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Créer un plat'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.fastfood),
                      filled: true,
                      fillColor: Color(0xFFFFF3E0),
                    ),
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Color(0xFFFFF3E0),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prix',
                      prefixIcon: Icon(Icons.price_check),
                      filled: true,
                      fillColor: Color(0xFFFFF3E0),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    hint: const Text('Catégorie'),
                    initialValue: categoryId,
                    items: categories.map((c) {
                      final id = c['id'] as int;
                      final name = c['name'] as String;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => categoryId = v);
                      print('Catégorie sélectionnée: $v');
                    },
                    validator: (v) =>
                        v == null ? 'Choisir une catégorie' : null,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange[50],
                      ),
                      child: imageBytes == null
                          ? const Center(child: Text('Choisir une image'))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 48,
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Créer', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
