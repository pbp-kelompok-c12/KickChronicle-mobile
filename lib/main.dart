import 'package:flutter/material.dart';
import 'package:kick_chronicle/modules/highlight/screens/home_page_highlight.dart';
import 'package:kick_chronicle/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

void main() {
  runApp(const KickChronicleApp());
}

class KickChronicleApp extends StatelessWidget {
  const KickChronicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Kick Chronicle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePageHighlight(),
      ),
    );
  }
}