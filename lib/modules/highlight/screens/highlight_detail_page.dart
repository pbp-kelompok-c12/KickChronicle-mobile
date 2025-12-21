import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe;
import 'package:kick_chronicle/services/komen_like_service.dart';
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

  // Mobile Controller
  mobile.YoutubePlayerController? _mobileController;
  // Web Controller
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

  // --- HELPER 1: CACHE BUSTING UNTUK AVATAR ---
  String _getAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // Jika URL relative (misal /media/...), biarkan apa adanya atau tambahkan base URL jika perlu
    // Di sini kita asumsikan URL valid, kita hanya tambah timestamp cache busting
    if (url.contains('?')) {
      return "$url&v=${DateTime.now().millisecondsSinceEpoch}";
    }
    return "$url?v=${DateTime.now().millisecondsSinceEpoch}";
  }

  // --- HELPER 2: RELATIVE TIME (FIXED TIMEZONE BUG) ---
  String _timeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Just now';
    try {
      // 1. Parse string ke DateTime
      // PENTING: Jika Django mengirim waktu UTC 'naive' (tanpa Z), Flutter menganggapnya Local.
      // Kita paksa anggap UTC dulu jika perlu, lalu convert ke Local.
      DateTime date;
      if (!dateString.endsWith('Z')) {
        // Asumsikan backend kirim UTC tapi lupa 'Z', kita tambahkan manual
        date = DateTime.parse("${dateString}Z").toLocal();
      } else {
        date = DateTime.parse(dateString).toLocal();
      }

      final DateTime now = DateTime.now();
      final Duration diff = now.difference(date);

      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      return 'Just now';
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

    if (text.isEmpty) return;

    final res = await api.addComment(highlightId: highlightId, content: text);
    if (!res['ok']) return;

    final data = res['data'];

    // PENTING: Perbaikan Data Lokal
    // 1. Paksa 'is_owner' jadi true karena kita baru saja mengirimnya.
    // 2. Gunakan waktu sekarang (DateTime.now()) agar langsung muncul "Just now".
    // 3. Handle avatar: gunakan dari response, kalau null cari dari history user.

    // Mencoba mencari avatar user dari komentar sebelumnya (jika ada) untuk fallback
    String? userAvatar = data['avatar'];
    if (userAvatar == null || userAvatar.isEmpty) {
      try {
        final existingComment = _comments.firstWhere(
          (c) => c['user'] == data['user'],
          orElse: () => {},
        );
        if (existingComment.isNotEmpty) {
          userAvatar = existingComment['avatar'];
        }
      } catch (_) {}
    }

    setState(() {
      _comments.insert(0, {
        'id': data['id'],
        'user': data['user'],
        'content': data['content'],
        // FIX TIMESTAMP: Gunakan waktu lokal saat ini
        'created_at': DateTime.now().toIso8601String(),
        'avatar': userAvatar,
        // FIX DELETE BUTTON: Paksa true
        'is_owner': true,
      });
      _commentsCount += 1;
      _commentController.clear();
    });
  }

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

    setState(() {
      _userRating = rating;
    });

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
                          color: val <= selected
                              ? Colors.amber
                              : Colors.grey[400],
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
          return _buildPageBody(context: context, playerWidget: player);
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
          child: Row(mainAxisSize: MainAxisSize.min),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THE VIDEO PLAYER
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
                  // --- HEADER HIGHLIGHT & ACTIONS ---
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
                          foregroundColor: _isFavorite
                              ? const Color.fromARGB(255, 255, 234, 0)
                              : Colors.white,
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
                                  hintStyle: TextStyle(color: Colors.grey[600]),
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
                            children: _comments.map((c) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF374151),
                                    child: ClipOval(
                                      child: Image.network(
                                        _getAvatarUrl(c['avatar']),
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, _, __) =>
                                            const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                      ),
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['user'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _timeAgo(c['created_at']),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      c['content'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  trailing: (c['is_owner'] == true)
                                      ? GestureDetector(
                                          onTap: () => _confirmDelete(c['id']),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
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
          Expanded(flex: 3, child: Text(col1, style: style)),
          Expanded(
            child: Center(child: Text(col2, style: style)),
          ),
          Expanded(
            child: Center(child: Text(col3, style: style)),
          ),
          Expanded(
            child: Center(child: Text(col4, style: style)),
          ),
          Expanded(
            child: Center(child: Text(col5, style: style)),
          ),
        ],
      ),
    );
  }
}
