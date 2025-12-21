import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kick_chronicle/modules/auth_profil/screens/profile_page.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/login_page.dart';
import 'package:kick_chronicle/modules/komen_like_rate/favorited_page.dart';

class NavbarUserProfile extends StatefulWidget {
  const NavbarUserProfile({super.key});

  @override
  State<NavbarUserProfile> createState() => _NavbarUserProfileState();
}

class _NavbarUserProfileState extends State<NavbarUserProfile> {
  String? _djangoProfileImageUrl;
  String? _googlePhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchDjangoProfileImage();
    _checkGooglePhoto();
  }

  Future<void> _fetchDjangoProfileImage() async {
    if (!mounted) return;

    final request = context.read<CookieRequest>();
    String baseUrl = ApiConfig.baseUrl;
    String url = "$baseUrl/auth/mobile/profile/";

    try {
      final response = await request.get(url);
      if (mounted && response['status'] == true) {
        setState(() {
          _djangoProfileImageUrl = response['data']['image_url'];
        });
      }
    } catch (_) {}
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
        if (user != null && mounted) {
          setState(() {
            _googlePhotoUrl = user.photoUrl;
          });
        }
      }
    } catch (_) {}
  }

  ImageProvider _getNavbarImage() {
    if (_djangoProfileImageUrl != null && _djangoProfileImageUrl!.isNotEmpty) {
      String baseUrl = ApiConfig.baseUrl;
      return NetworkImage(
        "$baseUrl$_djangoProfileImageUrl?v=${DateTime.now().millisecondsSinceEpoch}",
      );
    }
    if (_googlePhotoUrl != null) {
      return NetworkImage(_googlePhotoUrl!);
    }
    return const AssetImage('assets/images/default.png');
  }

  void _handleLogout(BuildContext context) async {
    final request = context.read<CookieRequest>();
    String baseUrl = ApiConfig.baseUrl;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    try {
      final response = await request.logout("$baseUrl/auth/mobile/logout/");
      String message = response['message'];
      if (context.mounted) {
        if (response['status']) {
          String uname = response['username'] ?? "User";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$message Sampai jumpa, $uname."),
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
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF1F2937),
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
      child: PopupMenuButton(
        offset: const Offset(0, 50),
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // [UBAH WARNA DISINI]
            border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2C3246),
            backgroundImage: _getNavbarImage(),
          ),
        ),
        onSelected: (value) async {
          if (value == 'profile') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            _fetchDjangoProfileImage();
          } else if (value == 'favorite') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritedPage()),
            );
          } else if (value == 'logout') {
            _handleLogout(context);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('My Profile', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Favorit', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
