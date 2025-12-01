import 'package:flutter/material.dart';
import 'package:kick_chronicle/screens/home_page.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context); 
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
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

          _buildListTile(context, "Home", Icons.dashboard, () {
            _navigateTo(context, '/');
          }),

          _buildListTile(context, "Highlight", Icons.video_library, () {
            _navigateTo(context, '/highlight');
          }),

          _buildListTile(context, "Schedule", Icons.calendar_today, () {
            _navigateTo(context, '/schedule');
          }),

          _buildListTile(context, "Top Rated", Icons.star, () {
            _navigateTo(context, '/toprated');
          }),
          
          _buildListTile(context, "Team", Icons.group, () {
            _navigateTo(context, '/team');
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