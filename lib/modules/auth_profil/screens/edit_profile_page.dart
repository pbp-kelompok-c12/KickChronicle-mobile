import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:kick_chronicle/models/user_profile.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  const EditProfilePage({super.key, required this.userProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;

  // Variabel untuk Gambar
  File? _imageFile; // Untuk menyimpan file gambar di Mobile (Android/iOS)
  Uint8List? _webImage; // Untuk menyimpan bytes gambar di Web
  String? _base64Image; // String base64 yang akan dikirim ke Django
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.userProfile.username,
    );
    _firstNameController = TextEditingController(
      text: widget.userProfile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.userProfile.lastName,
    );
    _emailController = TextEditingController(text: widget.userProfile.email);
  }

  // --- Fungsi Pilih Gambar ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        // Logika Khusus Web
        var f = await pickedFile.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = null;
          // Konversi ke Base64 untuk dikirim
          _base64Image = base64Encode(f);
        });
      } else {
        // Logika Mobile
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = null;
          // Konversi ke Base64 untuk dikirim
          _base64Image = base64Encode(bytes);
        });
      }
    }
  }

  // --- Fungsi Simpan Profil ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    // Tentukan URL (Gunakan 10.0.2.2 untuk Android Emulator)
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String url = "$baseUrl/auth/mobile/profile/edit/";

    // Siapkan data JSON
    Map<String, dynamic> data = {
      'username': _usernameController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'email': _emailController.text,
    };

    // Jika ada gambar baru, masukkan ke JSON
    if (_base64Image != null) {
      data['image'] = _base64Image;
    }

    try {
      final response = await request.postJson(url, jsonEncode(data));

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog(response['message'] ?? "Gagal menyimpan.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog("Error: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Gagal", style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("OK", style: TextStyle(color: Colors.deepOrange)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- BAGIAN FOTO PROFIL DENGAN PREVIEW ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepOrange, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage:
                            _getPreviewImage(), // Fungsi Helper Gambar
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // Trigger pick image
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _pickImage,
                child: const Text(
                  "Change Profile Photo",
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),

              const SizedBox(height: 30),

              // --- FORM FIELDS ---
              _buildTextField(
                label: "Username",
                controller: _usernameController,
                icon: Icons.alternate_email,
              ),
              _buildTextField(
                label: "Email",
                controller: _emailController,
                icon: Icons.email_outlined,
                inputType: TextInputType.emailAddress,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "First Name",
                      controller: _firstNameController,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: "Last Name",
                      controller: _lastNameController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper: Menentukan Gambar Mana yang Ditampilkan ---
  ImageProvider _getPreviewImage() {
    // 1. Jika User baru saja memilih gambar (Mobile File)
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    // 2. Jika User baru saja memilih gambar (Web Bytes)
    if (_webImage != null) {
      return MemoryImage(_webImage!);
    }
    // 3. Jika tidak ada gambar baru, tampilkan gambar lama dari Django
    if (widget.userProfile.imageUrl != null &&
        widget.userProfile.imageUrl!.isNotEmpty) {
      String baseUrl = kIsWeb
          ? "http://127.0.0.1:8000"
          : "http://10.0.2.2:8000";
      String url =
          "$baseUrl${widget.userProfile.imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}";
      return NetworkImage(url);
    }
    // 4. Default Image
    return const AssetImage('assets/images/default.png');
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        validator: (value) =>
            (value == null || value.isEmpty) ? '$label cannot be empty' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
        ),
      ),
    );
  }
}
