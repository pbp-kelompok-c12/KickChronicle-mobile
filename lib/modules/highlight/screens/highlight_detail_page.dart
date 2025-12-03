import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class HighlightDetailPage extends StatefulWidget {
  final Highlight highlight;

  const HighlightDetailPage({super.key, required this.highlight});

  @override
  State<HighlightDetailPage> createState() => _HighlightDetailPageState();
}

class _HighlightDetailPageState extends State<HighlightDetailPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayerController.convertUrlToId(widget.highlight.url);
    videoId ??= '';

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeStats = widget.highlight.homeStanding;
    final awayStats = widget.highlight.awayStanding;
    final bool hasStats = homeStats != null && awayStats != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "KC",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Kick Chronicle",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4F46E5),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
        backgroundColor: const Color(0xFF050505),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF050505),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.highlight.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Rate"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text("Favorite"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.highlight.description,
                    style: TextStyle(color: Colors.grey[400]),
                  ),

                  const SizedBox(height: 24),

                  // --- STATISTICS SECTION ---
                  const Text(
                    "Statistic",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  if (hasStats)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow("TEAM", "MATCH", "WIN", "TIE", "LOSE", isHeader: true),
                          const Divider(height: 1, color: Color(0xFF374151)),

                          // Home Row
                          _buildStatRow(
                              homeStats!.team,
                              homeStats.played.toString(),
                              homeStats.won.toString(),
                              homeStats.drawn.toString(),
                              homeStats.lost.toString()
                          ),

                          const Divider(height: 1, color: Color(0xFF374151)),

                          // Away Row
                          _buildStatRow(
                              awayStats!.team,
                              awayStats.played.toString(),
                              awayStats.won.toString(),
                              awayStats.drawn.toString(),
                              awayStats.lost.toString()
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: const Center(
                        child: Text(
                          "No standings data available for this match.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // --- COMMENTS SECTION ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Comments",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("0 Comments", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Comment Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Write a comment...",
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: const Color(0xFF1F2937),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: const Text("Send"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // UPDATED: Replaced dummy comments with Empty State
                        const Center(
                          child: Text(
                            "No comments yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String col1, String col2, String col3, String col4, String col5, {bool isHeader = false}) {
    TextStyle style = TextStyle(
      color: isHeader ? Colors.grey[400] : Colors.white,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 10 : 12,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(isHeader ? col1 : col1, style: style)),
          Expanded(child: Center(child: Text(col2, style: style))),
          Expanded(child: Center(child: Text(col3, style: style))),
          Expanded(child: Center(child: Text(col4, style: style))),
          Expanded(child: Center(child: Text(col5, style: style))),
        ],
      ),
    );
  }

  // Helper method kept but unused for now
  Widget _buildCommentItem(String username, String time, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}