import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:kick_chronicle/models/calendar_model.dart';
import 'package:kick_chronicle/modules/kalender/add_schedule.dart'; 
import 'package:kick_chronicle/modules/kalender/edit_schedule.dart'; 
import 'package:kick_chronicle/modules/kalender/detail_schedule.dart'; 
import 'package:kick_chronicle/modules/kalender/import_csv_schedule.dart'; 
import 'package:kick_chronicle/widgets/left_drawer.dart';
import 'package:kick_chronicle/modules/kalender/schedule_app_bar.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

final String baseHost = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS
    ? "http://localhost:8000"
    : "http://10.0.2.2:8000";


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
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

  Future<void> deleteMatch(CookieRequest request, int matchId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus Match ID $matchId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    final response = await request.post(
      baseHost + '/kalender/api/delete_match/$matchId/',
      {},
    );

    if (mounted) {
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil dihapus.')),
        );
        setState(() {
          _futureMatches = fetchMatches(request, _selectedDay);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menghapus jadwal.')),
        );
      }
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

  Widget _buildHeaderButton(String text, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white38),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isStaff = true; 

    return Scaffold(
      appBar: const ScheduleAppBar(),
      drawer: const LeftDrawer(),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          _buildDateHeader(),
          const SizedBox(height: 6),
          if (isStaff)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderButton(
                        'Add Schedule',
                        Icons.add,
                        () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddSchedulePage(),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              _futureMatches = fetchMatches(request, _selectedDay);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderButton(
                        'Import CSV',
                        Icons.upload_file,
                        () async { 
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImportCsvSchedulePage(),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              _futureMatches = fetchMatches(request, _selectedDay);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    .map((match) => MatchCard(
                          match: match,
                          isStaff: isStaff,
                          onDelete: () => deleteMatch(request, match.id!), 
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSchedulePage(
                                  matchToEdit: match,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                _futureMatches = fetchMatches(request, _selectedDay);
                              });
                            }
                          },
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

class MatchCard extends StatelessWidget {
  final Match match;
  final bool isStaff;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MatchCard({
    super.key,
    required this.match,
    required this.isStaff,
    this.onDelete,
    this.onEdit,
  });

  Widget _buildLogo(String? url) {
    if (url != null && url.isNotEmpty) {
        
        // --- PERBAIKAN LOGIKA PEMUATAN LOGO ---
        // Logika ini memprioritaskan aset lokal yang sudah di-fix di model
        
        if (url.startsWith('assets')) {
            // 1. Path dari model: assets/images/... -> Image.asset
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
        
        // 2. Fallback: Muat sebagai Image.network (Jika model tidak mengembalikan path asset)
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

    if (isStaff) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAdminButton('Edit', Colors.white, onEdit ?? () {}), 
                const SizedBox(width: 12),
                Expanded(child: mainWidget),
                const SizedBox(width: 12),
                _buildAdminButton('Delete', Colors.white, onDelete ?? () {}),
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
            constraints: const BoxConstraints(maxWidth: 700),
            child: mainWidget,
          ),
        ),
      );
    }
  }
}