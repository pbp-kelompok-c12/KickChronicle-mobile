import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:kick_chronicle/modules/highlight/widgets/favorited_card.dart';
import 'package:kick_chronicle/modules/highlight/widgets/match_card.dart';
import 'package:kick_chronicle/services/api_mobile.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FavoritedPage extends StatefulWidget {
  const FavoritedPage({super.key});

  @override
  State<FavoritedPage> createState() => _FavoritedPageState();
}

class _FavoritedPageState extends State<FavoritedPage> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;

  bool _isLoading = false;
  bool _hasMore = false;
  bool _hasError = false;

  bool _isAdmin = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus();
      _loadFavorites();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          !_hasError) {
        _loadFavorites();
      }
    });
  }

  Future<void> _checkAdminStatus() async {
    final request = context.read<CookieRequest>();
    String url = kIsWeb
        ? "http://127.0.0.1:8000/auth/check-superuser/"
        : "http://10.0.2.2:8000/auth/check-superuser/";

    try {
      final response = await request.get(url);
      if (response["status"] == true) {
        setState(() => _isAdmin = response["is_superuser"]);
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();

    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String logoutUrl = "$baseUrl/auth/mobile/logout/";

    try {
      final resp = await request.logout(logoutUrl);
      if (resp["status"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Goodbye, ${resp["username"]}!")),
        );
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final api = ApiMobile.fromContext(context);
    final res = await api.getFavorites();

    print(res.toString());
    if (!mounted) return;

    if (res["ok"]) {
      final List list = res["data"]["favorites"];
      setState(() {
        favorites = List<Map<String, dynamic>>.from(list);
        isLoading = false;
        _isLoading = false;
        _hasMore = false;
      });
    } else {
      setState(() {
        isLoading = false;
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _removeFavorite(String highlightId) async {
    final api = ApiMobile.fromContext(context);
    final res = await api.toggleFavorite(highlightId: highlightId);

    if (res["ok"]) {
      setState(() {
        favorites.removeWhere((item) => item["id"].toString() == highlightId);
      });
    }
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 1200) return 1.1;
    return 1.15;
  }

  AppBar _buildHeader() {
    final request = context.watch<CookieRequest>();

    return AppBar(
      titleSpacing: 0,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      title: _isAdmin
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
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
                  const Text(
                    "Favorited Matches",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        if (_isAdmin) ...[
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pushNamed(context, "/admin-highlights"),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, "/import-highlight"),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, "/add-highlight"),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: const Color(0xFF1F2937),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2C3246),
              child: Icon(
                _isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
            onSelected: (value) {
              if (value == "logout") _handleLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: LeftDrawer(),
      appBar: _buildHeader(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? const Center(
              child: Text(
                "No favorited matches yet.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.yellow, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        "Favorited Matches",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: _getCardAspectRatio(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final data = favorites[index];
                      final highlight = Highlight.fromJson(data);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: FavoritedCard(highlight: highlight)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 40,
                            width: 130,
                            child: TextButton(
                              onPressed: () => _removeFavorite(highlight.id),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: const BorderSide(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "Remove",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }, childCount: favorites.length),
                  ),
                ),
              ],
            ),
    );
  }
}
