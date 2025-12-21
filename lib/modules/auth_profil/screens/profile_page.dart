import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
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
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    _checkGoogleStatus();
  }

  Future<void> _checkGoogleStatus() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId:
          '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
    try {
      if (await googleSignIn.isSignedIn()) {
        final user = googleSignIn.currentUser;
        if (mounted) {
          setState(() {
            _isGoogleUser = true;
            if (user != null) {
              googlePhotoUrl = user.photoUrl;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchProfile() async {
    final request = context.read<CookieRequest>();
    String baseUrl = ApiConfig.baseUrl;
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

  ImageProvider _getProfileImage() {
    if (userProfile?.imageUrl != null && userProfile!.imageUrl!.isNotEmpty) {
      String baseUrl = ApiConfig.baseUrl;
      String url =
          "$baseUrl${userProfile!.imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}";
      return NetworkImage(url);
    }
    if (googlePhotoUrl != null) {
      return NetworkImage(googlePhotoUrl!);
    }
    return const AssetImage('assets/images/default.png');
  }

  Future<void> _deleteAccount() async {
    final request = context.read<CookieRequest>();
    String baseUrl = ApiConfig.baseUrl;
    String url = "$baseUrl/auth/mobile/delete-account/";

    try {
      final response = await request.postJson(url, jsonEncode({}));
      if (mounted) {
        if (response['status'] == true) {
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId:
                '935238606733-r2o3ii14m8ns65r9all4d0jcst0s3rld.apps.googleusercontent.com',
            scopes: ['email', 'profile'],
          );
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }

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
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.white),
              tooltip: "Edit Profile",
              onPressed: () async {
                if (userProfile != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(userProfile: userProfile!),
                    ),
                  );
                  fetchProfile();
                }
              },
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : userProfile == null
          ? const Center(
              child: Text(
                "Gagal memuat profil",
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4F46E5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _getProfileImage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${userProfile!.firstName} ${userProfile!.lastName}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@${userProfile!.username}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildSectionTitle("Personal Info"),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.person_outline,
                          "Username",
                          userProfile!.username,
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.email_outlined,
                          "Email",
                          userProfile!.email,
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          "Full Name",
                          "${userProfile!.firstName} ${userProfile!.lastName}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildSectionTitle("Account Settings"),
                  const SizedBox(height: 12),

                  if (!_isGoogleUser) ...[
                    _buildActionTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      color: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildActionTile(
                    icon: Icons.delete_forever_outlined,
                    title: "Delete Account",
                    color: Colors.redAccent,
                    isDestructive: true,
                    onTap: _showDeleteConfirmation,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? "-" : value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 58,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive
          ? Colors.red.withOpacity(0.1)
          : const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: isDestructive
              ? null
              : BoxDecoration(
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(16),
                ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
