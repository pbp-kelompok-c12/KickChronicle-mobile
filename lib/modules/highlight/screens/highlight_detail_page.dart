import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe;
import 'package:kick_chronicle/services/komen_like_service.dart';
import 'package:kick_chronicle/widgets/navbar_user_profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HighlightDetailPage extends StatefulWidget {
  final Highlight highlight;

  const HighlightDetailPage({super.key, required this.highlight});

  @override
  State<HighlightDetailPage> createState() => _HighlightDetailPageState();
}

class _HighlightDetailPageState extends State<HighlightDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isFavorite = false;
  int _commentsCount = 0;
  int? _userRating = 0;

  // Mobile Controller (nullable)
  mobile.YoutubePlayerController? _mobileController;
  // Web Controller (nullable)
  iframe.YoutubePlayerController? _webController;

  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();

    // 1. EXTRACT ID AUTOMATICALLY
    String? videoId = mobile.YoutubePlayer.convertUrlToId(widget.highlight.url);
    videoId ??= '';

    // 2. INITIALIZE CONTROLLER BASED ON PLATFORM
    if (kIsWeb) {
      _webController = iframe.YoutubePlayerController.fromVideoId(
        videoId: videoId,
        params: const iframe.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      _isPlayerReady = true;
    } else {
      _mobileController = mobile.YoutubePlayerController(
        initialVideoId: videoId,
        flags: const mobile.YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      )..addListener(_mobileListener);
    }

    _loadInitialData();
  }

  void _mobileListener() {
    if (_mobileController != null &&
        _isPlayerReady &&
        mounted &&
        !_mobileController!.value.isFullScreen) {
      // Logic for state changes if needed
    }
  }

  Future<void> _loadInitialData() async {
    final api = ApiMobile.fromContext(context);
    final highlightId = widget.highlight.id.toString();

    final commentRes = await api.getComments(highlightId: highlightId);
    if (commentRes['ok']) {
      setState(() {
        _comments = List<Map<String, dynamic>>.from(
          commentRes['data']['comments'],
        );
        _commentsCount = _comments.length;
      });
    }

    final favRes = await api.getFavorites();
    if (favRes['ok']) {
      final favs = favRes['data']['favorites'] as List;
      setState(() {
        _isFavorite = favs.any((f) => f['id'].toString() == highlightId);
      });
    }

    final rateRes = await api.getUserRating(highlightId: highlightId);
    if (rateRes['ok']) {
      setState(() {
        _userRating = rateRes['data']['rating'];
      });
    }
  }

  Future<void> _sendComment() async {
    final api = ApiMobile.fromContext(context);
    final highlightId = widget.highlight.id.toString();
    final text = _commentController.text.trim();

Future<void> _deleteComment(int commentId) async {
  final api = ApiMobile.fromContext(context);

  final res = await api.deleteComment(commentId: commentId);
  if (!res['ok']) return;

  setState(() {
    _comments.removeWhere((c) => c['id'] == commentId);
    _commentsCount -= 1;
  });
}

Future<void> _confirmDelete(int commentId) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete comment?"),
      content: const Text("This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (ok == true) {
    _deleteComment(commentId);
  }
}



Future<void> _sendComment() async {
  final api = ApiMobile.fromContext(context);
  final highlightId = widget.highlight.id.toString();
  final text = _commentController.text.trim();

    final res = await api.addComment(highlightId: highlightId, content: text);
    if (!res['ok']) return;

    final data = res['data'];

  final data = res['data'];

  setState(() {
    _comments.insert(0, {
      'id': data['id'],
      'user': data['user'],
      'content': data['content'],
      'created_at': data['created_at'],
      'avatar': data['avatar'], 
    });
  }

  Future<void> _toggleFavorite() async {
    final api = ApiMobile.fromContext(context);
    final res = await api.toggleFavorite(
      highlightId: widget.highlight.id.toString(),
    );

    if (!res['ok']) return;

    setState(() {
      _isFavorite = res['data']['favorited'];
    });
  }

  Future<void> _submitRating(int rating) async {
    final api = ApiMobile.fromContext(context);
    await api.submitRating(
      highlightId: widget.highlight.id.toString(),
      rating: rating,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thanks for rating!")));
    }
  }

  Future<int?> _showRatingDialog() async {
    int selected = _userRating ?? 0;

    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Center(
                child: Text(
                  "Rate this Highlight!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final val = i + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          size: 36,
                          color:
                          val <= selected ? Colors.amber : Colors.grey[400],
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selected = val;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0000ff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0000ff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void deactivate() {
    if (!kIsWeb && _mobileController != null) {
      _mobileController!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _webController?.close();
    } else {
      _mobileController?.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildPageBody(
        context: context,
        playerWidget: iframe.YoutubePlayer(
          controller: _webController!,
          aspectRatio: 16 / 9,
        ),
      );
    } else {
      return mobile.YoutubePlayerBuilder(
        onExitFullScreen: () {
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        },
        player: mobile.YoutubePlayer(
          controller: _mobileController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFEC4899),
          topActions: <Widget>[
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _mobileController!.metadata.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onReady: () {
            _isPlayerReady = true;
          },
        ),
        builder: (context, player) {
          return _buildPageBody(
            context: context,
            playerWidget: player,
          );
        },
      );
    }
  }

  Widget _buildPageBody({
    required BuildContext context,
    required Widget playerWidget,
  }) {
    final homeStats = widget.highlight.homeStanding;
    final awayStats = widget.highlight.awayStanding;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
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
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "Kick Chronicle",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NavbarUserProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THE VIDEO PLAYER
            // Removed BoxConstraints for Web to allow full width expansion
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: playerWidget,
            ),

            // 2. THE REST OF THE UI
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
                        onPressed: () async {
                          final rating = await _showRatingDialog();
                          if (rating != null) _submitRating(rating);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Rate"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _toggleFavorite,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                        label: Text(_isFavorite ? "Favorited" : "Favorite"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (homeStats != null && awayStats != null)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            "TEAM",
                            "MATCH",
                            "WIN",
                            "TIE",
                            "LOSE",
                            isHeader: true,
                          ),
                          const Divider(height: 1, color: Color(0xFF374151)),
                          _buildStatRow(
                            homeStats.team,
                            homeStats.played.toString(),
                            homeStats.won.toString(),
                            homeStats.drawn.toString(),
                            homeStats.lost.toString(),
                          ),
                          const Divider(height: 1, color: Color(0xFF374151)),
                          _buildStatRow(
                            awayStats.team,
                            awayStats.played.toString(),
                            awayStats.won.toString(),
                            awayStats.drawn.toString(),
                            awayStats.lost.toString(),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$_commentsCount Comments",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Write a comment...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1F2937),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _sendComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: const Text("Send"),
                            ),

                            const SizedBox(height: 24),

                            // Empty State
                    if (_comments.isEmpty)
                      const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)))
                    else
                      Column(
                        children: _comments.map((c) {
                          print(c['avatar']);
                          return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF374151),
                            child: ClipOval(
                              child: Image.network(
                                c['avatar'],
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, color: Colors.white, size: 18),
                              ),
                            ),
                          ),

                          title:  Text(
                            c['user'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            c['content'],
                            style: const TextStyle(color: Colors.grey),
                          ),

                        trailing: c['is_owner'] == true ? GestureDetector(
                        onTap: () => _confirmDelete(c['id']),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ) : null,
                        );

                        }).toList(),
                      ),

                            const SizedBox(height: 8),
                          ],
                        ),

                        const SizedBox(height: 24),

                        if (_comments.isEmpty)
                          const Center(
                            child: Text(
                              "No comments yet.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          Column(
                            children:
                            _comments.map((c) {
                              return ListTile(
                                title: Text(
                                  c['user'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  c['content'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }).toList(),
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

  Widget _buildStatRow(
      String col1,
      String col2,
      String col3,
      String col4,
      String col5, {
        bool isHeader = false,
      }) {
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
}