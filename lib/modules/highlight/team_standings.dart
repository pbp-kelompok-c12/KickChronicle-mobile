class TeamStanding {
  final String team;
  final int played;
  final int won;
  final int drawn;
  final int lost;

  TeamStanding({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      team: json['team'] ?? "Unknown",
      played: json['played'] ?? 0,
      won: json['won'] ?? 0,
      drawn: json['drawn'] ?? 0,
      lost: json['lost'] ?? 0,
    );
  }
}