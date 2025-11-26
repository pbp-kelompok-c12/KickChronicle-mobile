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

  final String djangoFullApiUrl =
      'http://localhost:8000/kalender/api/get_matches/';

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
        constraints: const BoxConstraints(maxWidth: 900), 
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[900],
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
                        return AlertDialog(
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


  Widget _buildHeaderButton(
      String text, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isStaff = true; // FOR TESTING ONLY

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isStaff)
            Row(
              children: [
                _buildHeaderButton('Add Schedule', Icons.add, () {}),
                _buildHeaderButton('Import CSV', Icons.upload_file, () {}),
              ],
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildDateHeader(),
          Expanded(
            child: FutureBuilder<List<Match>>(
              future: _futureMatches,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'There are no matches scheduled for this date',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final List<Match> matches = snapshot.data!;

                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchCard(
                        match: match, isStaff: isStaff);
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

  Widget _buildLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        height: 30,
        width: 30,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => const Icon(Icons.shield_outlined,
            size: 30, color: Colors.grey),
      );
    }
    return const Icon(Icons.shield_outlined,
        size: 30, color: Colors.grey);
  }

  Widget _buildAdminButton(
      String text, Color color, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white38),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
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
                        const TextStyle(fontWeight: FontWeight.bold),
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
                        const TextStyle(fontWeight: FontWeight.bold),
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
        onTap: () {},
        child: cardContent,
      ),
    );

    if (isStaff) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAdminButton('Edit', Colors.white, () {}),
                const SizedBox(width: 12),
                Expanded(child: mainWidget),
                const SizedBox(width: 12),
                _buildAdminButton('Delete', Colors.white, () {}),
              ],
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), 
            child: mainWidget,
          ),
        ),
      );
    }
  }
}
