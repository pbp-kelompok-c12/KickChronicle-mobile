import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:kick_chronicle/modules/kalender/calendar_screen_admin.dart'; 
import 'package:kick_chronicle/modules/kalender/calendar_screen_user.dart'; 

final String baseHost = ApiConfig.baseUrl;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  bool _isStaff = false; 

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final request = context.read<CookieRequest>();
    final url = '$baseHost/kalender/api/check_admin/'; 
    try {
      final response = await request.get(url);
      if (response.containsKey('is_staff') && response['is_staff'] == true) {
           _isStaff = true;
      }

    } catch (e) {
      _isStaff = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_isStaff) {
      return const AdminCalendarView(); 
    } else {
      return const UserCalendarView();  
    }
  }
}