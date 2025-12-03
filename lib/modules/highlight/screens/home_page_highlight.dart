import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:kick_chronicle/services/highlight_service.dart';
import 'package:kick_chronicle/modules/highlight/widgets/match_card.dart';
import 'package:kick_chronicle/utils/left_drawer.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/modules/highlight/screens/edit_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/add_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/import_highlight_page.dart';
import 'package:kick_chronicle/modules/highlight/screens/admin_highlight_page.dart';

class HomePageHighlight extends StatefulWidget {
  const HomePageHighlight({super.key});

  @override
  State<HomePageHighlight> createState() => _HomePageHighlightState();
}

class _HomePageHighlightState extends State<HomePageHighlight> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Highlight> _highlights = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _currentPage = 1;
  String _currentQuery = "";
  static const int _pageSize = 5;

  // State to simulate admin login
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final url = 'http://10.0.2.2:8000/delete-highlight-flutter/${highlight.id}/';
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

  void _onDrawerItemTapped(int index) {
    setState(() { _selectedIndex = index; });
    if (Navigator.canPop(context)) { Navigator.pop(context); }
  }

  // UPDATED: Dynamic Aspect Ratio Calculation
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [Color(0xFFF06292), Color(0xFFFF8A65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Center(child: Text("KC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              const Flexible(
                fit: FlexFit.loose,
                child: Text(
                  "Kick Chronicle",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
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

          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4F46E5),
              child: Icon(_isAdmin ? Icons.admin_panel_settings : Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: LeftDrawer(
        selectedIndex: _selectedIndex,
        onItemTapped: _onDrawerItemTapped,
        isAdmin: _isAdmin,
        onAdminChanged: (bool value) {
          setState(() {
            _isAdmin = value;
          });
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(8)),
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
                    decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text("Search", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
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
                          // UPDATED: Using dynamic calculation function
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

                                // Conditional Buttons for Admin
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
                                        // UPDATED: Spacing reduced from 8 to 4
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