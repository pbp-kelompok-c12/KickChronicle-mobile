import 'package:flutter/material.dart';
import 'package:kick_chronicle/modules/highlight/screens/home_page_highlight.dart';
// Import halaman-halaman lain nantinya di sini

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black, // Background Hitam sesuai tema
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo KC Kecil di Drawer
                Text(
                  "Kick Chronicle",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Watch highlights, follow teams",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // --- Menu Items ---
          _buildListTile(context, "Highlight", Icons.video_library, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageHighlight()));
          }),
          _buildListTile(context, "Schedule", Icons.calendar_today, () {
            Navigator.pop(context);
          }),
          _buildListTile(context, "Top Rated", Icons.star, () {
            Navigator.pop(context);
          }),
          _buildListTile(context, "Team", Icons.group, () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
