import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/register_page.dart';
import 'package:url_launcher/url_launcher.dart'; // Import URL Launcher
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Inisialisasi Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Fungsi Helper untuk membuka URL (Forgot Password)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Fungsi Helper untuk Google Login
  Future<void> _handleGoogleSignIn(CookieRequest request) async {
    setState(() => _isLoading = true);
    try {
      // 1. Proses Login di sisi Flutter (memunculkan popup Google)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan login
        setState(() => _isLoading = false);
        return;
      }

      // 2. Ambil Authentication Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception("Gagal mendapatkan Access Token dari Google");
      }

      // 3. Kirim Token ke Backend Django
      final response = await request.postJson(
        "http://localhost:8000/auth/auth/google-login/",
        // Pastikan URL sesuai dengan auth_profil/urls.py Anda
        // Format JSON body
        {"access_token": accessToken},
      );

      // 4. Handle Respon Django
      if (request.loggedIn) {
        String message = response['message'];
        String uname = response['username'];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text("KickChronicle")),
                body: const Center(child: Text("Welcome Home from Google!")),
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Welcome back $uname!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Login Google Gagal"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      print(error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... Header Code (Sama seperti sebelumnya) ...
              const Center(
                child: Icon(Icons.sports_soccer, size: 60, color: Colors.black),
              ),
              const SizedBox(height: 30),
              const Text(
                "Welcome back",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // ... TextFields Username & Password (Sama seperti sebelumnya) ...
              const Text(
                "Username",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- UPDATE 1: LOGIC FORGOT PASSWORD ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Mengarahkan ke URL Django reset password
                    // Ganti localhost dengan IP server jika di device fisik
                    _launchURL("http://localhost:8000/auth/password_reset/");
                  },
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ... Tombol Sign In Biasa (Sama seperti sebelumnya) ...
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // ... Logic Login Biasa Anda ...
                          setState(() => _isLoading = true);
                          String username = _usernameController.text;
                          String password = _passwordController.text;

                          final response = await request.login(
                            "http://localhost:8000/auth/auth/login/",
                            {'username': username, 'password': password},
                          );

                          setState(() => _isLoading = false);

                          if (request.loggedIn) {
                            // Navigate to home
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Login Berhasil")),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    body: Center(child: Text("Home")),
                                  ),
                                ),
                              );
                            }
                          } else {
                            // Show Error
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response['message'])),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign in',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // --- UPDATE 2: LOGIC GOOGLE SIGN IN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _handleGoogleSignIn(request);
                        },
                  icon: const Icon(Icons.android, color: Colors.black),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              // ... Footer Register Link ...
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
                      "Sign up",
                      style: TextStyle(
                        color: Colors.black,
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
}
