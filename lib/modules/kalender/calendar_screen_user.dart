import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:kick_chronicle/models/calendar_model.dart';
import 'package:kick_chronicle/modules/kalender/detail_schedule.dart'; 
import 'package:kick_chronicle/modules/kalender/schedule_app_bar.dart'; 
import 'package:kick_chronicle/widgets/left_drawer.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

final String baseHost = ApiConfig.baseUrl;

class UserCalendarView extends StatefulWidget {
  const UserCalendarView({super.key});

  @override
  State<UserCalendarView> createState() => _UserCalendarViewState();
}

class _UserCalendarViewState extends State<UserCalendarView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Future<List<Match>> _futureMatches;

  final String djangoFullApiUrl = baseHost + '/kalender/api/get_matches/';

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    final request = context.read<CookieRequest>();
    _futureMatches = fetchMatches(request, _selectedDay);
  }

  Future<List<Match>> fetchMatches(
      CookieRequest request, DateTime date) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = '$djangoFullApiUrl?date=$dateStr'; 

    try {
      final rawResponse = await request.get(url);
      return matchFromJson(rawResponse, date);
    } catch (e) {
      throw Exception('Failed to load match schedule.');
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

  void _navigateDay(int direction) {
    final newDay = _selectedDay.add(Duration(days: direction));
    _onDaySelected(newDay, newDay);
  }

  Widget _buildDateHeader() {
    final String displayDate =
        DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(_selectedDay);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 20, color: Colors.white),
                onPressed: () => _navigateDay(-1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDialog<DateTime>(
                      context: context,
                      builder: (BuildContext context) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFCCCCCC),
                              onPrimary: Colors.black,
                              surface: Colors.black,  
                              onSurface: Colors.white,
                              background: Colors.black,
                            ),
                            dialogBackgroundColor: Colors.black,
                            textTheme: const TextTheme(
                              titleLarge: TextStyle(color: Colors.white),
                              labelLarge: TextStyle(color: Colors.white),
                            ),
                          ),
                          child: AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: 320.0,
                              child: CalendarDatePicker(
                                initialDate: _selectedDay,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                                onDateChanged: (DateTime newDate) {
                                  Navigator.pop(context, newDate);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    if (pickedDate != null) {
                      _onDaySelected(pickedDate, pickedDate);
                    }
                  },
                  child: Center(
                    child: Text(
                      displayDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    size: 20, color: Colors.white),
                onPressed: () => _navigateDay(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    const bool isStaff = false; 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const ScheduleAppBar(),
      drawer: const LeftDrawer(), 
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          _buildDateHeader(),
          const SizedBox(height: 6),
          
          FutureBuilder<List<Match>>(
            future: _futureMatches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text('Error: ${snapshot.error}.')),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'There are no matches scheduled for this date',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final matches = snapshot.data!;
              return Column(
                children: matches
                    .map((match) => UserMatchCard(
                          match: match,
                          isStaff: isStaff, 
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}


class UserMatchCard extends StatelessWidget {
  final Match match;
  final bool isStaff;

  const UserMatchCard({
    super.key,
    required this.match,
    required this.isStaff,
  });

  Widget _buildLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets')) {
        return Image.asset(
            url,
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (c, o, s) => const Icon(
                Icons.shield_outlined,
                size: 30,
                color: Colors.grey
            ),
        );
      }
      
      String fullUrl = url.startsWith('http') ? url : baseHost + url;
      
      return Image.network(
          fullUrl,
          height: 30,
          width: 30,
          fit: BoxFit.contain,
          errorBuilder: (c, o, s) => const Icon(
              Icons.shield_outlined,
              size: 30,
              color: Colors.grey
          ),
      );
    }
    return const Icon(
        Icons.shield_outlined,
        size: 30,
        color: Colors.grey
    );
  }

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
                Flexible(
                  child: Text(
                    match.team1,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), 
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                _buildLogo(match.team1Logo),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              timeString,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildLogo(match.team2Logo),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    match.team2,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final mainWidget = Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSchedulePage(match: match),
            ),
          );
        },
        child: cardContent,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: mainWidget,
        ),
      ),
    );
  }
}