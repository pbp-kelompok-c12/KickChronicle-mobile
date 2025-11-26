import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';

class MatchCard extends StatelessWidget {
  final Highlight highlight;

  const MatchCard({
    super.key,
    required this.highlight,
  });

  Map<String, String> _parseMatchDetails(String name) {
    final RegExp scoreRegex = RegExp(r'(\d+)\s*-\s*(\d+)');
    final match = scoreRegex.firstMatch(name);

    String score1 = "0";
    String score2 = "0";
    bool hasScore = false;

    if (match != null) {
      score1 = match.group(1)!;
      score2 = match.group(2)!;
      hasScore = true;
    }

    final List<int> colors = [
      0xFF1A237E, 0xFF2E7D32, 0xFFC62828, 0xFFEF6C00, 0xFF0277BD,
    ];
    int colorIndex = highlight.id.hashCode % colors.length;
    int colorCode = colors[colorIndex];

    return {
      "score1": score1,
      "score2": score2,
      "hasScore": hasScore ? "true" : "false",
      "color": colorCode.toString(),
    };
  }

  String? _getYouTubeThumbnail(String url) {
    final RegExp youtubeRegex = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    final match = youtubeRegex.firstMatch(url);
    if (match != null) {
      final String videoId = match.group(7)!;
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final details = _parseMatchDetails(highlight.name);
    final int colorCode = int.parse(details["color"]!);
    final bool hasScore = details["hasScore"] == "true";
    final String seasonLabel = seasonValues.reverse[highlight.season] ?? "";

    String? backgroundImageUrl = highlight.manualThumbnailUrl;
    if (backgroundImageUrl == null || backgroundImageUrl.isEmpty) {
      backgroundImageUrl = _getYouTubeThumbnail(highlight.url);
    }

    return Container(
      // CHANGED: Removed margin because the Grid handles spacing now
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Color(colorCode),
              child: Stack(
                children: [
                  if (backgroundImageUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        backgroundImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const SizedBox(),
                      ),
                    ),
                  if (backgroundImageUrl == null)
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(Icons.shield,
                                size: 40, color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                        Container(
                          width: 100,
                          color: Colors.white.withOpacity(0.95),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasScore) ...[
                                Text(
                                  details["score1"]!,
                                  style: TextStyle(
                                    color: Color(colorCode),
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                Container(
                                    height: 2, width: 20, color: Colors.grey[400]),
                                Text(
                                  details["score2"]!,
                                  style: TextStyle(
                                    color: Color(colorCode),
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  "VS",
                                  style: TextStyle(
                                    color: Color(colorCode),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Icon(Icons.shield_outlined,
                                size: 40, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  Positioned(
                    right: 0,
                    top: 20,
                    bottom: 20,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.black.withOpacity(0.6),
                        child: const Text(
                          "HIGHLIGHTS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Vertically center content if there's leftover space
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SEASON $seasonLabel",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (highlight.description.length < 20)
                        Expanded(
                          child: Text(
                            highlight.description.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    highlight.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highlight.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}