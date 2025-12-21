import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:kick_chronicle/services/highlight_service.dart';
import 'package:kick_chronicle/modules/highlight/widgets/match_card.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kick_chronicle/modules/highlight/screens/edit_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/add_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/import_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/admin_highlight_page.dart';
import 'package:kick_chronicle/modules/auth_profil/screens/login_page.dart';
import 'package:kick_chronicle/widgets/navbar_user_profile.dart';

class HomePageHighlight extends StatefulWidget {
  const HomePageHighlight({super.key});

  @override
  State<HomePageHighlight> createState() => _HomePageHighlightState();
}

class _HomePageHighlightState extends State<HomePageHighlight> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Highlight> _highlights = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _currentPage = 1;
  String _currentQuery = "";
  static const int _pageSize = 5;

  // Real Admin State
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus(); // Check role first
      _fetchPage();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading && _hasMore && !_hasError) {
        _fetchPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- NEW: Check Admin Status from Backend ---
  Future<void> _checkAdminStatus() async {
    final request = context.read<CookieRequest>();
    // You need an endpoint in Django that returns {"is_superuser": true/false}
    // Example: http://127.0.0.1:8000/auth/check-admin/
    // If you don't have one, you might need to rely on login response data stored locally.
    // For now, I'll assume a hypothetical endpoint or check against a known property if your auth package supports it.

    // NOTE: Replace this URL with your actual endpoint to check user role
    // If you haven't built this endpoint yet, you need to add it to your Django views.
    final String url = "${ApiConfig.baseUrl}/auth/check-superuser/";

    try {
      // Trying to fetch user info.
      // If this endpoint doesn't exist yet, this block will fail silently or log error.
      final response = await request.get(url);
      if (response != null && response['status'] == true) {
        setState(() {
          _isAdmin = response['is_superuser'] ?? false;
        });
      }
    } catch (e) {
      // Fallback or ignore if endpoint doesn't exist yet
      print("Could not verify admin status: $e");
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout(BuildContext context, CookieRequest request) async {
    String baseUrl = ApiConfig.baseUrl;
    String logoutUrl = "$baseUrl/auth/mobile/logout/";

    try {
      final response = await request.logout(logoutUrl);

      if (context.mounted) {
        if (response['status']) {
          String uname = response['username'] ?? "User";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sampai jumpa, $uname!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _performSearch() {
    setState(() {
      _currentQuery = _searchController.text.trim();
      _highlights.clear();
      _currentPage = 1;
      _hasMore = true;
      _hasError = false;
    });
    _fetchPage();
  }

  Future<void> _refreshData() async {
    setState(() {
      _highlights.clear();
      _currentPage = 1;
      _hasMore = true;
      _hasError = false;
    });
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final request = context.read<CookieRequest>();
      final newItems = await fetchHighlights(request, page: _currentPage, query: _currentQuery);
      setState(() {
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          bool isDuplicate = false;
          if (_highlights.isNotEmpty) {
            if (_highlights.any((item) => item.id == newItems.first.id)) {
              isDuplicate = true;
            }
          }
          if (newItems.length < _pageSize) { _hasMore = false; }
          if (isDuplicate) {
            _hasMore = false;
          } else {
            _highlights.addAll(newItems);
            _currentPage++;
          }
        }
      });
    } catch (e) {
      setState(() { _hasError = true; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load data.")));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteHighlight(Highlight highlight) async {
    final request = context.read<CookieRequest>();
    final url =
        "${ApiConfig.baseUrl}/delete-highlight-flutter/${highlight.id}/";
    try {
      final response = await request.post(url, {});
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted!")));
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Highlight highlight) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('Delete Highlight', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Delete "${highlight.name}"?', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteHighlight(highlight);
              },
            ),
          ],
        );
      },
    );
  }


  // Calculate Aspect Ratio
  double _getCardAspectRatio(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    // Logic:
    // Mobile (< 600px): Uses 1 column. Ratio needs to be portrait-ish to fit text.
    // Tablet/Desktop (> 600px): Uses 2+ columns. Grid cells get wider, so we need a higher ratio (closer to square or landscape) to prevent them from becoming too tall.

    if (width < 600) {
      if (_isAdmin) {
        return 1.04; // Mobile ratio
      } else {
        return 1.2;
      }
    } else if (width < 1200) {
      if (_isAdmin) {
        return 0.95; // Mobile ratio
      } else {
        return 1.1;
      }
    } else {
      if (_isAdmin) {
        return 1.0; // Mobile ratio
      } else {
        return 1.15;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        // EDIT: Only show the logo and text if NOT an admin
        title: _isAdmin
            ? null
            : Padding(
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
                    child: Text("KC",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18))),
              ),
              const SizedBox(width: 12),
              const Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "Kick Chronicle",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // REAL ADMIN CHECK
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
              tooltip: "Admin Console",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminHighlightPage()),
                );
                _refreshData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
              tooltip: "Import CSV",
              onPressed: () async {
                final bool? imported = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImportHighlightPage()),
                );
                if (imported == true) { _refreshData(); }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: "Add Highlight",
              onPressed: () async {
                final bool? added = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddHighlightPage()),
                );
                if (added == true) { _refreshData(); }
              },
            ),
          ],

          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NavbarUserProfile(), // Gunakan widget yang baru kita buat
          ),
        ],
      ),
      drawer: LeftDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _performSearch(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search highlights...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _performSearch,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Center(
                        child: Text(
                            "Search",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_highlights.isEmpty && _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_highlights.isEmpty && _hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No Internet Connection", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Please check your network and try again.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _performSearch,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }
                if (_highlights.isEmpty && !_isLoading) {
                  return const Center(child: Text("No highlights found", style: TextStyle(color: Colors.white)));
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: _getCardAspectRatio(context),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final highlight = _highlights[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: MatchCard(highlight: highlight)),

                                // CONDITIONAL RENDER: Edit/Delete buttons only if _isAdmin is true
                                if (_isAdmin)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final bool? refreshed = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => EditHighlightPage(highlight: highlight)),
                                              );
                                              if (refreshed == true) { _refreshData(); }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                              minimumSize: const Size(0, 42),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text("Edit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () { _confirmDelete(context, highlight); },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                              minimumSize: const Size(0, 42),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text("Delete", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                          childCount: _highlights.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: _hasMore
                              ? const CircularProgressIndicator()
                              : const Text("You have reached the end of the list", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}