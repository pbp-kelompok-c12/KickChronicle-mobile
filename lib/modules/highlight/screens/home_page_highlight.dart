import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:kick_chronicle/services/highlight_service.dart';
import 'package:kick_chronicle/modules/highlight/widgets/match_card.dart';
import 'package:kick_chronicle/utils/left_drawer.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class HomePageHighlight extends StatefulWidget {
  const HomePageHighlight({super.key});

  @override
  State<HomePageHighlight> createState() => _HomePageHighlightState();
}

class _HomePageHighlightState extends State<HomePageHighlight> {
  int _selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Highlight> _highlights = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false; // New state to track errors/offline status
  int _currentPage = 1;
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPage();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          !_hasError) { // Don't try to auto-load more if we are already in error state
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
      _hasError = false; // Reset error on new search
    });
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false; // Reset error before trying
    });

    try {
      final request = context.read<CookieRequest>();
      final newItems = await fetchHighlights(
          request,
          page: _currentPage,
          query: _currentQuery
      );

      setState(() {
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _highlights.addAll(newItems);
          _currentPage++;
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true; // Set error state
      });
      // Optional: still show snackbar for specific details if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load data. Check your connection."),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      drawer: LeftDrawer(
        selectedIndex: _selectedIndex,
        onItemTapped: _onDrawerItemTapped,
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "Search",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                // 1. Loading State
                if (_highlights.isEmpty && _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Error / Offline State (Only if list is empty)
                if (_highlights.isEmpty && _hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "No Internet Connection",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Please check your network and try again.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _performSearch, // Retry action
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                // 3. Empty Data State
                if (_highlights.isEmpty && !_isLoading) {
                  return const Center(
                      child: Text(
                          "No highlights found",
                          style: TextStyle(color: Colors.white)
                      )
                  );
                }

                // 4. Data List
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return MatchCard(highlight: _highlights[index]);
                            },
                            childCount: _highlights.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                        ),
                      ),

                      if (_hasMore || (_isLoading && _highlights.isNotEmpty))
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}