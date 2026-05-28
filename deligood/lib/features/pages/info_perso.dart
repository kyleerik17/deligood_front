import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deligood/core/network/api.dart';

class InfoPersoPage extends StatefulWidget {
  const InfoPersoPage({super.key});

  @override
  State<InfoPersoPage> createState() => _InfoPersoPageState();
}

class _InfoPersoPageState extends State<InfoPersoPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isModified = false;
  static String get baseUrl => Api.baseUrl;

  // Avatar
  Uint8List? _avatarBytes;
  XFile? _avatarFile;

  // Permit
  Uint8List? _permitBytes;
  XFile? _permitFile;

  String _userType = ""; // pour savoir si c'est livreur

  final ImagePicker _picker = ImagePicker();

  late AnimationController _haloController;

  @override
  void initState() {
    super.initState();

    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUserInfoFromPrefs();
    _fetchUserInfoFromBackend();

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_isModified) setState(() => _isModified = true);
  }

  Future<void> _loadUserInfoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _phoneController.text = prefs.getString('phone_number') ?? '';
      _userType = prefs.getString('user_type') ?? "";

      // Charger l'avatar depuis prefs si déjà sauvegardé
      final avatarBase64 = prefs.getString('avatar_base64');
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        _avatarBytes = base64Decode(avatarBase64);
      } else {
        _avatarBytes = null; // pas d'image
      }

      _isModified = false;
    });
  }

  Future<void> _fetchUserInfoFromBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final url = Uri.parse('$baseUrl/api/users/profile/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': Api.authHeaderValue(token)},
      );
      print(
        "DEBUG: fetchUserInfoFromBackend statusCode=${response.statusCode}",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final profile = data is Map && data['data'] is Map
            ? Map<String, dynamic>.from(data['data'])
            : Map<String, dynamic>.from(data);

        _firstNameController.text = profile['first_name'] ?? '';
        _lastNameController.text = profile['last_name'] ?? '';
        _phoneController.text = profile['phone_number'] ?? '';
        _userType = profile['user_type'] ?? "";
        print("DEBUG: userType=$_userType");

        // Avatar : récupère depuis API si pas déjà dans prefs
        final photoUrl = Api.resolveMediaUrl(
          (profile['photo_url'] ?? profile['photo'])?.toString(),
        );
        if (photoUrl.isNotEmpty && _avatarBytes == null) {
          final bytes = await _fetchImageBytes(photoUrl);
          if (bytes != null) {
            _avatarBytes = bytes;
            await prefs.setString('avatar_base64', base64Encode(bytes));
            print("DEBUG: Avatar chargé depuis backend");
          }
        }

        // Permit uniquement pour livreur
        if (_userType == "livreur") {
          final permitUrl = Api.resolveMediaUrl(
            (profile['permit_photo_url'] ?? profile['permit_photo'])
                ?.toString(),
          );
          if (permitUrl.isNotEmpty) {
            final bytes = await _fetchImageBytes(permitUrl);
            if (bytes != null) {
              _permitBytes = bytes;
              print("DEBUG: Permit chargé depuis backend");
            }
          }
        }

        setState(() => _isModified = false);
      }
    } catch (e) {
      print("Erreur fetch backend: $e");
    }
  }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (e) {
      print("Erreur fetch image: $e");
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarFile = null;
        _isModified = true;
      });
    } else {
      setState(() {
        _avatarFile = image;
        _avatarBytes = null;
        _isModified = true;
      });
    }
  }

  Future<void> _pickPermit() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
    ); // peut changer si PDF
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _permitBytes = bytes;
        _permitFile = null;
        _isModified = true;
      });
    } else {
      setState(() {
        _permitFile = file;
        _permitBytes = null;
        _isModified = true;
      });
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_avatarBytes != null) return MemoryImage(_avatarBytes!);
    if (_avatarFile != null && File(_avatarFile!.path).existsSync()) {
      return FileImage(File(_avatarFile!.path));
    }
    return null;
  }

  ImageProvider? _getPermitImage() {
    if (_permitBytes != null) return MemoryImage(_permitBytes!);
    if (_permitFile != null && File(_permitFile!.path).existsSync()) {
      return FileImage(File(_permitFile!.path));
    }
    return null;
  }

  String get _initials {
    final f = _firstNameController.text;
    final l = _lastNameController.text;
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  Future<void> _saveUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final url = Uri.parse('$baseUrl/api/users/profile/');
    try {
      var request = http.MultipartRequest('PATCH', url)
        ..headers['Authorization'] = Api.authHeaderValue(token)
        ..fields['first_name'] = _firstNameController.text
        ..fields['last_name'] = _lastNameController.text
        ..fields['phone_number'] = _phoneController.text;

      // Avatar
      if (_avatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _avatarBytes!,
            filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
        );
        print("DEBUG: Avatar ajouté pour upload");
      } else if (_avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _avatarFile!.path),
        );
        print("DEBUG: Avatar fichier ajouté pour upload");
      }

      // Permit uniquement si livreur
      if (_userType == "livreur") {
        if (_permitBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'permit_photo',
              _permitBytes!,
              filename: 'permit_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          );
          print("DEBUG: Permit envoyé depuis bytes");
        } else if (_permitFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'permit_photo',
              _permitFile!.path,
            ),
          );
          print("DEBUG: Permit envoyé depuis fichier local");
        } else {
          print("DEBUG: Aucun permit à envoyer pour ce livreur");
        }
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      print("DEBUG: saveUserInfo response=$respStr");

      if (response.statusCode == 200) {
        await prefs.setString('first_name', _firstNameController.text);
        await prefs.setString('last_name', _lastNameController.text);
        await prefs.setString('phone_number', _phoneController.text);
        await prefs.setString('user_type', _userType);

        if (_avatarBytes != null) {
          await prefs.setString('avatar_base64', base64Encode(_avatarBytes!));
        } else if (_avatarFile != null) {
          final bytes = await File(_avatarFile!.path).readAsBytes();
          _avatarBytes = bytes;
          await prefs.setString('avatar_base64', base64Encode(bytes));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Infos sauvegardées ✅"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isModified = false);
      } else {
        throw Exception(respStr);
      }
    } catch (e) {
      print("Erreur saveUserInfo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur sauvegarde ❌ $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 2.h,
            left: 4.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(1.5.h),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 6.w),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _haloController,
                        builder: (_, __) => Container(
                          width: 28.w + _haloController.value * 10,
                          height: 28.w + _haloController.value * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurpleAccent.withOpacity(
                              0.2 + _haloController.value * 0.3,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 14.w,
                          backgroundColor: Colors.grey[900],
                          backgroundImage: _getAvatarImage(),
                          child: _getAvatarImage() == null
                              ? Text(
                                  _initials,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(3.h),
                Center(
                  child: Text(
                    "Parlez-nous de vous",
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
                Gap(3.h),
                _buildLabel('Prénom *'),
                _buildTextField(_firstNameController),
                Gap(2.h),
                _buildLabel('Nom *'),
                _buildTextField(_lastNameController),
                Gap(2.h),
                _buildLabel('Numéro de téléphone *'),
                _buildTextField(_phoneController, hint: '+225 05 65 83 83 85'),
                Gap(2.h),

                // Permit seulement si livreur
                if (_userType == "livreur") ...[
                  _buildLabel('Permis / Document'),
                  ElevatedButton(
                    onPressed: _pickPermit,
                    child: Text(
                      _permitFile != null || _permitBytes != null
                          ? "Modifier le fichier"
                          : "Ajouter un fichier",
                    ),
                  ),
                  Gap(2.h),
                ],

                Gap(4.h),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50.w,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _isModified ? _saveUserInfo : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isModified
                            ? Colors.deepPurpleAccent
                            : Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Colors.deepPurpleAccent,
                      ),
                      child: Text(
                        'Sauvegarder',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Gap(4.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      color: Colors.deepPurpleAccent,
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _buildTextField(TextEditingController controller, {String? hint}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(1.h),
        border: Border.all(color: Colors.deepPurpleAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 3.w,
            vertical: 1.5.h,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
