import 'package:flutter/material.dart';

class LeftDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isAdmin; // NEW: Receive admin status
  final Function(bool) onAdminChanged; // NEW: Callback to toggle admin status

  const LeftDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isAdmin,
    required this.onAdminChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: const Color(0xFF111827),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF374151))),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF06292), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "KC",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Kick Chronicle",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, Icons.play_circle_fill, 'Highlights', () => onItemTapped(0)),
                _buildDrawerItem(1, Icons.calendar_today, 'Schedule', () => onItemTapped(1)),
                _buildDrawerItem(2, Icons.star, 'Top Rated', () => onItemTapped(2)),
                _buildDrawerItem(3, Icons.group, 'Team', () => onItemTapped(3)),

                const Divider(color: Color(0xFF374151)),

                // NEW: Admin Simulation Toggle
                SwitchListTile(
                  title: const Text("Simulate Admin", style: TextStyle(color: Colors.white)),
                  secondary: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                      color: isAdmin ? const Color(0xFF4F46E5) : Colors.grey
                  ),
                  value: isAdmin,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (bool value) {
                    onAdminChanged(value); // Trigger callback
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Version 1.0.0\nRole: ${isAdmin ? 'Admin' : 'User'}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title, VoidCallback onTap) {
    final bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}