import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/standing.dart';
import 'package:kick_chronicle/services/tim_service.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';
import 'package:kick_chronicle/modules/kalender/schedule_app_bar.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class HomePageTim extends StatefulWidget {
  const HomePageTim({super.key});

  @override
  State<HomePageTim> createState() => _HomePageTimState();
}

class _HomePageTimState extends State<HomePageTim> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Standing> _standings = [];
  List<String> _seasons = [];
  String? _selectedSeason; // null = all

  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = TimService(request);

      final seasons = await service.fetchSeasons();
      final defaultSeason = seasons.isNotEmpty ? seasons.last : null;
      final standings = await service.fetchStandings(season: defaultSeason);

      if (mounted) {
        setState(() {
          _seasons = seasons;
          _selectedSeason = defaultSeason;
          _standings = standings;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _standings = [];
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadStandings({String? season}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _selectedSeason = season;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = TimService(request);
      final standings = await service.fetchStandings(season: season);

      if (mounted) {
        setState(() {
          _standings = standings;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _standings = [];
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Standing> get _filteredStandings {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _standings;
    return _standings.where((s) => s.team.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredStandings;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const ScheduleAppBar(),
      drawer: const LeftDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _headerSection(),
            _filterSection(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitial,
                color: const Color(0xFF4F46E5),
                child: _buildBody(rows),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0F),
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Premier League Standings",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "View final standings for Premier League seasons",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _filterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Filter by Season",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _seasonChip(null, "All Seasons"),
                ..._seasons.map((s) => _seasonChip(s, _formatSeasonLabel(s))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    hintText: "Search club name",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() {}),
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
        ],
      ),
    );
  }

  String _formatSeasonLabel(String s) {
    switch (s) {
      case '22/23':
        return '2022/2023';
      case '23/24':
        return '2023/2024';
      case '24/25':
        return '2024/2025';
      default:
        return s;
    }
  }

  Widget _seasonChip(String? value, String label) {
    final bool active =
        (value == null && _selectedSeason == null) || value == _selectedSeason;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          _reloadStandings(season: value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4F46E5) : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF6366F1) : const Color(0xFF374151),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[300],
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Standing> rows) {
    if (_isLoading && _standings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Failed to load standings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please check your connection and try again.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (rows.isEmpty) {
      return const Center(
        child: Text(
          "No standings found for this filter",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Kelompokkan per musim seperti di standings.html
    final Map<String, List<Standing>> grouped = {};
    for (final s in rows) {
      grouped.putIfAbsent(s.season, () => []).add(s);
    }

    // Urutkan musim pakai urutan dari API bila ada
    final List<String> seasonsOrder;
    if (_seasons.isEmpty) {
      seasonsOrder = grouped.keys.toList()..sort();
    } else {
      seasonsOrder = _seasons
          .where((season) => grouped.keys.contains(season))
          .toList();
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final season in seasonsOrder) ...[
            _seasonTableCard(
              seasonLabel: _formatSeasonLabel(season),
              rows: grouped[season]!,
            ),
            const SizedBox(height: 16),
          ],
          _legend(),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    Text header(String label) => Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: header('POS')),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: header('TEAM')),
          Expanded(child: header('PLD')),
          Expanded(child: header('W')),
          Expanded(child: header('D')),
          Expanded(child: header('L')),
          Expanded(child: header('GF')),
          Expanded(child: header('GA')),
          Expanded(child: header('GD')),
          Expanded(child: header('PTS')),
        ],
      ),
    );
  }

  Widget _seasonTableCard({
    required String seasonLabel,
    required List<Standing> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: [
          // Header biru seperti di template HTML
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1D4ED8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Season $seasonLabel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _tableHeader(),
                const SizedBox(height: 4),
                for (final s in rows) _tableRow(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Standing s) {
    Color stripeColor;
    if (s.position <= 4) {
      stripeColor = Colors.blueAccent;
    } else if (s.position == 5) {
      stripeColor = Colors.greenAccent;
    } else if (s.position == 6) {
      stripeColor = Colors.orangeAccent;
    } else if (s.position >= 18) {
      stripeColor = Colors.redAccent;
    } else {
      stripeColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            color: stripeColor,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(
              s.position.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _teamLogo(s),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.team,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _cellText(s.played.toString()),
          ),
          Expanded(
            child: _cellText(s.won.toString()),
          ),
          Expanded(
            child: _cellText(s.drawn.toString()),
          ),
          Expanded(
            child: _cellText(s.lost.toString()),
          ),
          Expanded(
            child: _cellText(s.goalsFor.toString()),
          ),
          Expanded(
            child: _cellText(s.goalsAgainst.toString()),
          ),
          Expanded(
            child: Text(
              s.goalDiffLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.goalDifference >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              s.points.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellText(String value) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }

  Widget _teamLogo(Standing s) {
    // Ikuti pendekatan modul kalender: pakai aset lokal hasil konversi path static.
    final String? assetPath = s.logoUrl;

    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _avatarFallback(s);
        },
      );
    }

    return _avatarFallback(s);
  }

  Widget _avatarFallback(Standing s) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        s.team.isNotEmpty ? s.team[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _legend() {
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 4,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          item(Colors.blueAccent, "Champions League"),
          item(Colors.greenAccent, "Europa League"),
          item(Colors.orangeAccent, "Europa Conference League"),
          item(Colors.redAccent, "Relegation"),
        ],
      ),
    );
  }
}
