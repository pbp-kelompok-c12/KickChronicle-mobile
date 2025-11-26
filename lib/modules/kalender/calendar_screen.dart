import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import 'package:kick_chronicle/models/calendar_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Future<List<Match>> _futureMatches;
  final String djangoBaseUrl = 'http://localhost:8000/kalender/api/get_matches/';

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    
    final request = context.read<CookieRequest>();
    _futureMatches = fetchMatches(request, _selectedDay); 
  }

  Future<List<Match>> fetchMatches(CookieRequest request, DateTime date) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = '$djangoBaseUrl?date=$dateStr'; 

    try {
      final response = await request.get(url); 
      
      if (response is Map<String, dynamic> && response.containsKey('matches')) {
        final List<dynamic> matchData = response['matches'];
        return matchData.map((json) => Match.fromJson(json)).toList();
      } else {
        return matchFromJson(response.toString());
      }
    } catch (e) {
      print(e);
      throw Exception('Gagal memuat jadwal pertandingan.');
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        
        final request = context.read<CookieRequest>();
        _futureMatches = fetchMatches(request, _selectedDay);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isStaff = request.loggedIn; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pertandingan'),
        actions: [
          if (isStaff) 
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigasi ke halaman Add Schedule
              },
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          TableCalendar(
            locale: 'id_ID', 
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            calendarFormat: CalendarFormat.month,
            onDaySelected: _onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          
          const Divider(height: 1),

          Expanded(
            child: FutureBuilder<List<Match>>(
              future: _futureMatches,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } 
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}.'));
                } 
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal pada tanggal ${DateFormat('dd MMMM yyyy').format(_selectedDay)}.', style: const TextStyle(color: Colors.grey)),
                  );
                }
                
                final List<Match> matches = snapshot.data!;
                
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchCard(
                      match: match,
                      isStaff: isStaff,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MatchCard extends StatelessWidget {
  final Match match;
  final bool isStaff; 

  const MatchCard({
    super.key,
    required this.match,
    required this.isStaff,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(match.date);
    
    final cardContent = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: Text(match.team1, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
                const SizedBox(width: 8),
                (match.team1Logo != null && match.team1Logo!.isNotEmpty) 
                  ? Image.network(match.team1Logo!, height: 36, width: 36, errorBuilder: (c, o, s) => const Icon(Icons.shield_outlined, size: 36))
                  : const Icon(Icons.shield_outlined, size: 36),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(timeString, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ),

          Expanded(
            child: Row(
              children: [
                (match.team2Logo != null && match.team2Logo!.isNotEmpty) 
                  ? Image.network(match.team2Logo!, height: 36, width: 36, errorBuilder: (c, o, s) => const Icon(Icons.shield_outlined, size: 36))
                  : const Icon(Icons.shield_outlined, size: 36),
                const SizedBox(width: 8),
                Flexible(child: Text(match.team2, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );

    final mainWidget = Card(
        color: Colors.grey[850], 
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            // NAVIGASI KE DETAIL MATCH
          },
          child: cardContent,
        ),
      );

    if (isStaff) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () { 
                // NAVIGASI KE EDIT PAGE
              },
            ),
            Expanded(child: mainWidget),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () { 
                // PANGGIL FUNGSI DELETE MATCH
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: mainWidget,
      );
    }
  }
}