import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kick_chronicle/models/user_profile.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/edit_profile_page.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/change_password_page.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? userProfile;
  bool isLoading = true;
  String? googlePhotoUrl;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    _checkGooglePhoto();
  }

  Future<void> _checkGooglePhoto() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId:
          '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
    try {
      if (await googleSignIn.isSignedIn()) {
        final user = googleSignIn.currentUser;
        if (user != null) {
          setState(() {
            googlePhotoUrl = user.photoUrl;
          });
        }
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> fetchProfile() async {
    final request = context.read<CookieRequest>();
    // Gunakan '10.0.2.2' untuk Android Emulator, '127.0.0.1' untuk Web
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String url = "$baseUrl/auth/mobile/profile/";

    try {
      final response = await request.get(url);
      if (mounted) {
        setState(() {
          if (response['status'] == true) {
            userProfile = UserProfile.fromJson(response['data']);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIKA PRIORITAS GAMBAR ---
  ImageProvider _getProfileImage() {
    // 1. Prioritas Utama: Foto upload dari Django
    if (userProfile?.imageUrl != null && userProfile!.imageUrl!.isNotEmpty) {
      String baseUrl = kIsWeb
          ? "http://127.0.0.1:8000"
          : "http://10.0.2.2:8000";
          String url =
          "$baseUrl${userProfile!.imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}";
      return NetworkImage(url);
    }

    // 2. Prioritas Kedua: Foto Google (jika login sosmed)
    if (googlePhotoUrl != null) {
      return NetworkImage(googlePhotoUrl!);
    }

    // 3. Terakhir: Foto Default Aset
    return const AssetImage('assets/images/default.png');
  }

  // Fungsi Delete Account
  Future<void> _deleteAccount() async {
    final request = context.read<CookieRequest>();
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String url = "$baseUrl/auth/mobile/delete-account/";

    final response = await request.postJson(url, jsonEncode({}));

    if (mounted) {
      if (response['status'] == true) {
        // Logout Google juga jika perlu
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId:
              '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }

        // Kembali ke Login Page dan hapus semua route
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background Gelap
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol Edit di AppBar
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (userProfile != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfilePage(userProfile: userProfile!),
                  ),
                );
                fetchProfile(); // Refresh data setelah kembali dari edit
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : userProfile == null
          ? const Center(
              child: Text(
                "Gagal memuat profil",
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // FOTO PROFIL BULAT
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepOrange,
                        width: 3,
                      ), // Border Oranye
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _getProfileImage(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NAMA & EMAIL
                  Text(
                    userProfile!.username,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProfile!.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 40),

                  // INFO CARDS
                  _buildInfoTile(
                    "Full Name",
                    "${userProfile!.firstName} ${userProfile!.lastName}",
                  ),
                  _buildInfoTile("Username", userProfile!.username),
                  _buildInfoTile("Email", userProfile!.email),
                  const SizedBox(height: 40),

                  // TOMBOL CHANGE PASSWORD
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF374151,
                        ), // Dark grey button
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TOMBOL DELETE ACCOUNT
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(
                        "Delete Account",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _showDeleteConfirmation,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Card agak terang dari background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
