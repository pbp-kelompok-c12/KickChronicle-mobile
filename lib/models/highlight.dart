import 'dart:convert';

List<Highlight> highlightFromJson(String str) => List<Highlight>.from(json.decode(str).map((x) => Highlight.fromJson(x)));

String highlightToJson(List<Highlight> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Highlight {
  String id;
  String name;
  String url;
  dynamic manualThumbnailUrl;
  String description;
  DateTime createdAt;
  Season season;

  Highlight({
    required this.id,
    required this.name,
    required this.url,
    required this.manualThumbnailUrl,
    required this.description,
    required this.createdAt,
    required this.season,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
    id: json["id"],
    name: json["name"],
    url: json["url"],
    manualThumbnailUrl: json["manual_thumbnail_url"],
    description: json["description"],
    createdAt: DateTime.parse(json["created_at"]),
    season: seasonValues.map[json["season"]]!,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
    "manual_thumbnail_url": manualThumbnailUrl,
    "description": description,
    "created_at": createdAt.toIso8601String(),
    "season": seasonValues.reverse[season],
  };
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
