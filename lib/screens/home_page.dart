import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In
import 'package:kick_chronicle/modules/auth_profil/screens/login_page.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/profile_page.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _profileImageUrl;
  String? _googlePhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
    _checkGooglePhoto();
  }

  // Ambil data profil dari Django untuk mendapatkan URL foto
  Future<void> _fetchProfileImage() async {
    final request = context.read<CookieRequest>();
    String baseUrl = ApiConfig.baseUrl;
    String url = "$baseUrl/auth/mobile/profile/";

    try {
      final response = await request.get(url);
      if (mounted && response['status'] == true) {
        setState(() {
          _profileImageUrl = response['data']['image_url'];
        });
      }
    } catch (_) {}
  }

  // Cek foto Google jika login via Google
  Future<void> _checkGooglePhoto() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId:
          '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
    if (await googleSignIn.isSignedIn()) {
      final user = googleSignIn.currentUser;
      if (user != null) {
        setState(() {
          _googlePhotoUrl = user.photoUrl;
        });
      }
    }
  }

  // Logika Pemilihan Gambar Navbar (Sama dengan ProfilePage)
  ImageProvider _getNavbarImage() {
    // 1. Prioritas: Foto dari Django
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      String baseUrl = ApiConfig.baseUrl;
      return NetworkImage("$baseUrl/media/$_profileImageUrl");
    }
    // 2. Foto Google
    if (_googlePhotoUrl != null) {
      return NetworkImage(_googlePhotoUrl!);
    }
    // 3. Default Asset (PERBAIKAN BUG)
    return const AssetImage('assets/images/default.png');
  }

  Future<void> _handleLogout(
    BuildContext context,
    CookieRequest request,
  ) async {
    String baseUrl = ApiConfig.baseUrl;
    String logoutUrl = "$baseUrl/auth/mobile/logout/";

    try {
      final response = await request.logout(logoutUrl);
      if (context.mounted) {
        if (response['status']) {
          String uname = response['username'] ?? "User";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sampai jumpa, $uname!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logout: $e"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const LeftDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "KC",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Kick Chronicle",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 40),
            if (isDesktop) ...[
              _buildNavbarLink("Highlight"),
              _buildNavbarLink("Schedule"),
              _buildNavbarLink("Top Rated"),
              _buildNavbarLink("Team"),
            ],
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              color: const Color(0xFF1F2937),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2C3246),
                backgroundImage:
                    _getNavbarImage(), // MENGGUNAKAN GAMBAR YANG BENAR
              ),
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text("My Profile", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Logout", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  _handleLogout(context, request);
                } else if (value == 'profile') {
                  // Refresh navbar image when returning from profile page (in case user updated it)
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  _fetchProfileImage();
                }
              },
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text("Main Content", style: TextStyle(color: Colors.white)),
      ), // Placeholder
    );
  }

  Widget _buildNavbarLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
