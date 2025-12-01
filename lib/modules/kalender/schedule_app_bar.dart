import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kick_chronicle/modules/auth_profil/screens/login_page.dart';

class ScheduleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScheduleAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _handleLogout(
    BuildContext context,
    CookieRequest request,
  ) async {
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNavbarLink(BuildContext context, String title) {
    String routeName = title.toLowerCase() == 'schedule' ? '/schedule' : '/${title.toLowerCase().replaceAll(' ', '')}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, routeName);
        },
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return AppBar(
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
            _buildNavbarLink(context, "Highlight"),
            _buildNavbarLink(context, "Schedule"),
            _buildNavbarLink(context, "Top Rated"),
            _buildNavbarLink(context, "Team"),
          ],
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: const Color(0xFF1F2937),
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF2C3246),
              child: Icon(Icons.person, color: Colors.white),
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
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context, request);
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/profile'); 
              }
            },
          ),
        ),
      ],
    );
  }
}