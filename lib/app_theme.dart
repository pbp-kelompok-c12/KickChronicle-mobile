import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050505), // Deep black background
    primaryColor: const Color(0xFF4F46E5), // Purple accent

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF050505),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F0F0F),
      selectedItemColor: Color(0xFF4F46E5),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),

    useMaterial3: true,
  );
}