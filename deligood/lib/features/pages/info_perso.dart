import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _emailController = TextEditingController();

  bool _isModified = false;
  bool _isSaving = false;
  static const String baseUrl = "http://127.0.0.1:8000";

  // Avatar
  Uint8List? _avatarBytes;
  XFile? _avatarFile;

  // Permit
  Uint8List? _permitBytes;
  XFile? _permitFile;

  String _userType = "";
  late AnimationController _animationController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();

    _loadUserInfoFromPrefs();
    _fetchUserInfoFromBackend();

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
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
      _emailController.text = prefs.getString('email') ?? '';
      _userType = prefs.getString('user_type') ?? "";

      // Charger l'avatar depuis prefs
      final avatarBase64 = prefs.getString('avatar_base64');
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          _avatarBytes = base64Decode(avatarBase64);
        } catch (e) {
          _avatarBytes = null;
        }
      }

      // Charger le permit depuis prefs (pour livreur)
      if (_userType == "livreur") {
        final permitBase64 = prefs.getString('permit_base64');
        if (permitBase64 != null && permitBase64.isNotEmpty) {
          try {
            _permitBytes = base64Decode(permitBase64);
          } catch (e) {
            _permitBytes = null;
          }
        }
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
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _emailController.text = data['email'] ?? '';
          _userType = data['user_type'] ?? "";
        });

        // Avatar : charger uniquement si pas déjà en cache
        if (_avatarBytes == null &&
            data['photo'] != null &&
            data['photo'].toString().isNotEmpty) {
          final bytes = await _fetchImageBytes('$baseUrl${data['photo']}');
          if (bytes != null) {
            setState(() => _avatarBytes = bytes);
            await prefs.setString('avatar_base64', base64Encode(bytes));
          }
        }

        // Permit : charger uniquement si livreur et pas déjà en cache
        if (_userType == "livreur") {
          if (_permitBytes == null &&
              data['permit'] != null &&
              data['permit'].toString().isNotEmpty) {
            final bytes = await _fetchImageBytes('$baseUrl${data['permit']}');
            if (bytes != null) {
              setState(() => _permitBytes = bytes);
              await prefs.setString('permit_base64', base64Encode(bytes));
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
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarFile = image;
      _isModified = true;
    });

    // Sauvegarder immédiatement dans prefs pour persistance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_base64', base64Encode(bytes));
  }

  Future<void> _pickPermit() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _permitBytes = bytes;
      _permitFile = file;
      _isModified = true;
    });

    // Sauvegarder immédiatement dans prefs pour persistance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('permit_base64', base64Encode(bytes));
  }

  String get _initials {
    final f = _firstNameController.text;
    final l = _lastNameController.text;
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return '?';
  }

  Future<void> _saveUserInfo() async {
    // Validation basique
    if (_firstNameController.text.trim().isEmpty) {
      _showError("Le prénom est requis");
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError("Le nom est requis");
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError("Le numéro de téléphone est requis");
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      setState(() => _isSaving = false);
      _showError("Token manquant");
      return;
    }

    final url = Uri.parse('$baseUrl/api/users/profile/');
    try {
      var request = http.MultipartRequest('PATCH', url)
        ..headers['Authorization'] = 'Token $token'
        ..fields['first_name'] = _firstNameController.text.trim()
        ..fields['last_name'] = _lastNameController.text.trim()
        ..fields['phone_number'] = _phoneController.text.trim();

      if (_emailController.text.trim().isNotEmpty) {
        request.fields['email'] = _emailController.text.trim();
      }

      // Avatar
      if (_avatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _avatarBytes!,
            filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      // Permit uniquement si livreur
      if (_userType == "livreur" && _permitBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'permit',
            _permitBytes!,
            filename: 'permit_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        // Sauvegarder dans SharedPreferences
        await prefs.setString('first_name', _firstNameController.text.trim());
        await prefs.setString('last_name', _lastNameController.text.trim());
        await prefs.setString('phone_number', _phoneController.text.trim());
        if (_emailController.text.trim().isNotEmpty) {
          await prefs.setString('email', _emailController.text.trim());
        }

        // Avatar et permit déjà sauvegardés lors de la sélection
        if (_avatarBytes != null) {
          await prefs.setString('avatar_base64', base64Encode(_avatarBytes!));
        }
        if (_userType == "livreur" && _permitBytes != null) {
          await prefs.setString('permit_base64', base64Encode(_permitBytes!));
        }

        setState(() => _isModified = false);

        if (mounted) {
          // Feedback de succès élégant
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Profil mis à jour avec succès',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00CCBC), // Turquoise Deliveroo
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );

          // Retour après un court délai
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pop(context);
        }
      } else {
        _showError("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError("Erreur réseau");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF5A5F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Contenu principal
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar avec effet moderne
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00CCBC).withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Vos informations',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complétez votre profil',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Contenu
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _animationController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Section
                        _buildAvatarSection(),

                        const SizedBox(height: 32),

                        // Formulaire
                        _buildFormSection(),

                        // Document livreur
                        if (_userType == "livreur") ...[
                          const SizedBox(height: 32),
                          _buildDocumentSection(),
                        ],

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bouton fixe en bas
          if (_isModified)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CCBC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                // Avatar principal
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _avatarBytes == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00CCBC).withOpacity(0.2),
                              const Color(0xFF00CCBC).withOpacity(0.1),
                            ],
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00CCBC).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _avatarBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            _avatarBytes!,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00CCBC),
                            ),
                          ),
                        ),
                ),
                // Badge camera
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CCBC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _avatarBytes == null
                ? 'Ajouter une photo de profil'
                : 'Modifier la photo',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _firstNameController,
          label: 'Prénom',
          hint: 'Votre prénom',
          icon: Icons.person_outline_rounded,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Nom',
          hint: 'Votre nom de famille',
          icon: Icons.person_outline_rounded,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          hint: '+225 XX XX XX XX XX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          required: true,
        ),
       
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5A5F),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF00CCBC),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document de livreur',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permis de conduire ou autorisation nécessaire',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickPermit,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _permitBytes != null
                  ? const Color(0xFF00CCBC).withOpacity(0.05)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _permitBytes != null
                    ? const Color(0xFF00CCBC)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _permitBytes != null
                        ? const Color(0xFF00CCBC)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _permitBytes != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _permitBytes != null
                            ? 'Document ajouté'
                            : 'Ajouter un document',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _permitBytes != null
                            ? 'Appuyez pour modifier'
                            : 'Formats acceptés: JPG, PNG',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}