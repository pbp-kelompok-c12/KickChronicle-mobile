import 'package:flutter/material.dart';
import 'package:kick_chronicle/modules/highlight/screens/home_page_highlight.dart';
import 'package:kick_chronicle/modules/kalender/calendar_screen.dart';
import 'package:kick_chronicle/modules/tim/standing_page.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  void _navigateToWidget(BuildContext context, Widget targetWidget) {
    Navigator.pop(context);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetWidget),
    );
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

          _buildListTile(context, "Highlight", Icons.video_library, () {
            _navigateToWidget(context, const HomePageHighlight());
          }),
          
          _buildListTile(context, "Schedule", Icons.calendar_today, () {
            _navigateToWidget(context, const CalendarScreen());
          }),
          
          _buildListTile(context, "Top Rated", Icons.star, () {
            Navigator.pop(context);
          }),
          
          _buildListTile(context, "Team", Icons.group, () {
            _navigateToWidget(context, const HomePageTim());
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
