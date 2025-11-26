import 'dart:convert';

List<Match> matchFromJson(String str) {
  return List<Match>.from(json.decode(str).map((x) => Match.fromJson(x['fields'])));
}

class Match {
  final String team1;
  final String? team1Logo;
  final String team2;
  final String? team2Logo;
  final DateTime date; 
  final String? description;

  Match({
    required this.team1,
    this.team1Logo,
    required this.team2,
    this.team2Logo,
    required this.date,
    this.description,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final String dateTimeString = '${json['date']} ${json['time']}';
    return Match(
      team1: json['team_1'] as String, 
      team1Logo: json['team_1_logo'] as String?, 
      team2: json['team_2'] as String,
      team2Logo: json['team_2_logo'] as String?,
      date: DateTime.parse(dateTimeString), 
      description: json['description'] as String?, 
    );
  }
}