import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:kick_chronicle/models/calendar_model.dart';
import 'package:kick_chronicle/modules/kalender/detail_schedule.dart';
import 'package:kick_chronicle/utils/constants.dart';

class TeamSchedulePage extends StatefulWidget {
  const TeamSchedulePage({
    super.key,
    required this.teamName,
    String? queryTeamName,
  }) : queryTeamName = queryTeamName ?? teamName;

  final String teamName;
  final String queryTeamName;

  @override
  State<TeamSchedulePage> createState() => _TeamSchedulePageState();
}

class _TeamSchedulePageState extends State<TeamSchedulePage> {
  late Future<List<Match>> _futureMatches;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _futureMatches = _fetchTeamMatches(request);
  }

  Future<List<Match>> _fetchTeamMatches(CookieRequest request) async {
    final url =
        '${ApiConfig.baseUrl}/kalender/api/team_matches/?team=${Uri.encodeComponent(widget.queryTeamName)}';
    final rawResponse = await request.get(url);
    return teamMatchesFromJson(rawResponse);
  }

  Widget _buildLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets')) {
        return Image.asset(
          url,
          height: 30,
          width: 30,
          fit: BoxFit.contain,
          errorBuilder: (c, o, s) =>
              const Icon(Icons.shield_outlined, size: 30, color: Colors.grey),
        );
      }

      final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
      return Image.network(
        fullUrl,
        height: 30,
        width: 30,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) =>
            const Icon(Icons.shield_outlined, size: 30, color: Colors.grey),
      );
    }
    return const Icon(Icons.shield_outlined, size: 30, color: Colors.grey);
  }

  Widget _matchCard(Match match) {
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                color: Colors.white,
              ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailSchedulePage(match: match),
              ),
            );
          },
          child: cardContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.teamName,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Match>>(
        future: _futureMatches,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load schedule.',
                style: TextStyle(color: Colors.grey[300]),
              ),
            );
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return Center(
              child: Text(
                'No matches found for this team.',
                style: TextStyle(color: Colors.grey[300]),
              ),
            );
          }

          matches.sort((a, b) => a.date.compareTo(b.date));

          final List<Widget> children = [];
          DateTime? lastDay;
          final dateFormatter = DateFormat('d MMMM yyyy');

          for (final match in matches) {
            final day =
                DateTime(match.date.year, match.date.month, match.date.day);

            if (lastDay == null || day != lastDay) {
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    dateFormatter.format(day),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
              lastDay = day;
            }

            children.add(
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: _matchCard(match),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: children,
          );
        },
      ),
    );
  }
}
