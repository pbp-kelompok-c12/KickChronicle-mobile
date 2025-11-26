import 'dart:convert';

List<Match> matchFromJson(dynamic data, DateTime selectedDate) {
  if (data is Map<String, dynamic> && data.containsKey('matches')) {
    return List<Match>.from(
      data['matches'].map((x) => Match.fromJson(x, selectedDate)),
    );
  }
  return [];
}


class Match {
  final int? id;
  final String team1;
  final String? team1Logo;
  final String team2;
  final String? team2Logo;
  final DateTime date;
  final String? description;

  Match({
    this.id,
    required this.team1,
    this.team1Logo,
    required this.team2,
    this.team2Logo,
    required this.date,
    this.description,
  });

  factory Match.fromJson(Map<String, dynamic> json, DateTime selectedDate) {
    final String dateString =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';

    final String dateTimeString = '$dateString ${json['start_time']}';

    return Match(
      id: json['id'] as int?,
      team1: json['team_1'] as String,
      team1Logo: json['team_1_logo'] as String?,
      team2: json['team_2'] as String,
      team2Logo: json['team_2_logo'] as String?,
      date: DateTime.parse(dateTimeString),
      description: json['description'] as String?,
    );
  }
}
