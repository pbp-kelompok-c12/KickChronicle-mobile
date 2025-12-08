
class Standing {
  Standing({
    required this.id,
    required this.season,
    required this.position,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.logoUrl,
  });

  final String id;
  final String season;
  final int position;
  final String team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final String? logoUrl;

  factory Standing.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String fixLogoPath(String? path) {
      if (path == null || path.isEmpty) return "";

      // Ambil hanya path-nya, hilangkan host jika ada.
      final uri = Uri.tryParse(path);
      final rawPath = uri?.path ?? path;

      // Ikuti pendekatan kalender: /static/images -> assets/images
      if (rawPath.contains("/static/images/")) {
        return rawPath.replaceFirst("/static/images/", "assets/images/");
      }
      if (rawPath.startsWith("/images/")) {
        return rawPath.replaceFirst("/images/", "assets/images/");
      }
      if (rawPath.startsWith("images/")) {
        return "assets/$rawPath";
      }
      if (rawPath.contains("/images/")) {
        return "assets${rawPath.replaceFirst('/static/', '/')}";
      }

      return rawPath;
    }

    return Standing(
      id: json['id']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      position: toInt(json['position']),
      team: json['team']?.toString() ?? '',
      played: toInt(json['played']),
      won: toInt(json['won']),
      drawn: toInt(json['drawn']),
      lost: toInt(json['lost']),
      goalsFor: toInt(json['goals_for']),
      goalsAgainst: toInt(json['goals_against']),
      goalDifference: toInt(json['goal_difference']),
      points: toInt(json['points']),
      logoUrl: fixLogoPath(json['logo_url'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'season': season,
      'position': position,
      'team': team,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goals_for': goalsFor,
      'goals_against': goalsAgainst,
      'goal_difference': goalDifference,
      'points': points,
      'logo_url': logoUrl,
    };
  }

  String get formattedSeason {
    switch (season) {
      case '22/23':
        return '2022/2023';
      case '23/24':
        return '2023/2024';
      case '24/25':
        return '2024/2025';
      default:
        return season;
    }
  }

  String get goalDiffLabel =>
      goalDifference >= 0 ? '+$goalDifference' : goalDifference.toString();

  // Sudah berupa path aset hasil konversi dari logoUrl backend.
  String? get assetLogoPath {
    if (logoUrl == null || logoUrl!.isEmpty) return null;
    return logoUrl;
  }
}
