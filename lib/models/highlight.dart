import 'dart:convert';
import 'package:kick_chronicle/modules/highlight/team_standings.dart'; // Import the new model

List<Highlight> highlightFromJson(String str) => List<Highlight>.from(json.decode(str).map((x) => Highlight.fromJson(x)));

class Highlight {
  String id;
  String name;
  String url;
  dynamic manualThumbnailUrl;
  String description;
  DateTime createdAt;
  Season season;
  TeamStanding? homeStanding;
  TeamStanding? awayStanding;

  Highlight({
    required this.id,
    required this.name,
    required this.url,
    required this.manualThumbnailUrl,
    required this.description,
    required this.createdAt,
    required this.season,
    this.homeStanding,
    this.awayStanding,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
    id: json["id"].toString(), // Ensure string
    name: json["name"],
    url: json["url"],
    manualThumbnailUrl: json["manual_thumbnail_url"],
    description: json["description"],
    createdAt: DateTime.parse(json["created_at"]),
    season: seasonValues.map[json["season"]] ?? Season.THE_2425,
    homeStanding: json["home_standing"] != null
        ? TeamStanding.fromJson(json["home_standing"])
        : null,
    awayStanding: json["away_standing"] != null
        ? TeamStanding.fromJson(json["away_standing"])
        : null,
  );
}

enum Season {
  THE_2223,
  THE_2324,
  THE_2425
}

final seasonValues = EnumValues({
  "22/23": Season.THE_2223,
  "23/24": Season.THE_2324,
  "24/25": Season.THE_2425
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}