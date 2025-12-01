import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/modules/kalender/calendar_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest(); 
        
        return request;
      },
      child: MaterialApp(
        title: 'Kick Chronicle App',
        theme: ThemeData(
          brightness: Brightness.dark, 
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const CalendarScreen(), 
      ),
    );
  }
}