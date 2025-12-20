import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kick_chronicle/modules/highlight/screens/home_page_highlight.dart';
import 'package:kick_chronicle/screens/home_page.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import khusus Web
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        if (account != null) {
          _handleGoogleLoginResult(account);
        }
      });
      _googleSignIn.signInSilently();
    }
  }

  // --- LOGIKA: Handle Hasil Login Google ---
  Future<void> _handleGoogleLoginResult(GoogleSignInAccount account) async {
    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    try {
      final GoogleSignInAuthentication auth = await account.authentication;
      String baseUrl = kIsWeb
          ? "http://127.0.0.1:8000"
          : "http://10.0.2.2:8000";
      String url = "$baseUrl/auth/mobile/google-login/";

      final response = await request.postJson(
        url,
        jsonEncode(<String, String>{
          'email': account.email,
          'id_token': auth.idToken ?? "",
          'access_token': auth.accessToken ?? "",
        }),
      );

      if (mounted) {
        if (response['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selamat datang, ${response['username']}!")),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageHighlight()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal login: ${response['message']}")),
          );
          _googleSignIn.disconnect();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Handle Google
  // --- LOGIKA: Handle Klik Google Mobile ---
  Future<void> _handleMobileSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        await _handleGoogleLoginResult(account);
      }
    } catch (error) {
      print("Error Google Sign In Mobile: $error");
    }
  }

  // --- LOGIKA: Handle Login Manual ---
  Future<void> _handleManualLogin() async {
    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String url = "$baseUrl/auth/mobile/login/";

    try {
      final response = await request.login(url, {
        'username': _usernameController.text,
        'password': _passwordController.text,
      });

      if (request.loggedIn) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Login berhasil!")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageHighlight()));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Login gagal")),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat terhubung ke server")),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGoogleWebButton() {
    return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
        .renderButton();
  }

  // --- UI DESIGN UTAMA ---
  @override
  Widget build(BuildContext context) {
    // Warna custom sesuai desain KickChronicle
    const Color inputFillColor = Color(0xFF2C3246); // Abu-abu gelap/biru
    const Color buttonColor = Color(0xFF4F46E5); // Ungu/Biru terang

    return Scaffold(
      backgroundColor: Colors.black, // Background Hitam
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Logo / Judul
              // Jika Anda punya gambar logo, ganti Icon di bawah dengan Image.asset(...)
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFA855F7),
                      Color(0xFFEC4899),
                    ], // Gradient ungu-pink
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "KC",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Kick Chronicle",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Watch highlights, follow your teams",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // 2. Form Input
              _buildTextField(
                controller: _usernameController,
                label: "Username",
                fillColor: inputFillColor,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                isPassword: true,
                fillColor: inputFillColor,
              ),

              // 3. Tombol Forgot Password (Opsional, visual only)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // Tambahkan logika jika perlu
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Tombol Login Utama
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleManualLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              // 5. Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[800])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR CONTINUE WITH",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ],
              ),
              const SizedBox(height: 30),

              // 6. Tombol Google
              if (kIsWeb)
                Container(
                  height: 50,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: _buildGoogleWebButton(),
                )
              else
                OutlinedButton.icon(
                  onPressed: _handleMobileSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[800]!),
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Ganti Icon ini dengan Image.asset('assets/google.png') jika punya
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 32,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Google",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 40),

              // 7. Footer Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Create one",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Text Field yang rapi
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color fillColor,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: isPassword
                ? '........'
                : '', // Placeholder dot untuk password
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
