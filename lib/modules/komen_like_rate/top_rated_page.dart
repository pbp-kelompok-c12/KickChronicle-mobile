import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:kick_chronicle/modules/highlight/widgets/match_card.dart';
import 'package:kick_chronicle/modules/highlight/widgets/top_rated_card.dart';
import 'package:kick_chronicle/services/komen_like_service.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';

class TopRatedPage extends StatefulWidget {
  const TopRatedPage({super.key});

  @override
  State<TopRatedPage> createState() => _TopRatedPageState();
}

class _TopRatedPageState extends State<TopRatedPage> {
  DateTime _selectedDate = DateTime.now();
  List<Highlight> _highlights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopRated();
  }

  Future<void> _fetchTopRated() async {
    setState(() => _loading = true);
    final api = ApiMobile.fromContext(context);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await api.getTopRated(startDate: dateStr, endDate: dateStr);

    if (!mounted) return;

    if (res["ok"]) {
      final List list = res["data"]["highlights"];
      setState(() {
        _highlights = list.map((e) => Highlight.fromJson(e)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _navigateDate(int direction) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: direction));
    });
    _fetchTopRated();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: const Color(0xFF111827),
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchTopRated();
    }
  }

  double _gridRatio(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 1.05;
    if (w < 1200) return 1.1;
    return 1.15;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const LeftDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Top Rated Highlights"),
      ),
      body: Column(
        children: [
         Expanded(
           child: CustomScrollView(
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
              "Top Rated Matches",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
                      ),
                    ),
                  ),
            
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 20, color: Colors.white),
                  onPressed: () => _navigateDate(-1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Center(
                      child: Text(
                        DateFormat('EEEE, dd MMM yyyy')
                            .format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 20, color: Colors.white),
                  onPressed: () => _navigateDate(1),
                ),
              ],
            ),
                      ),
                    ),
                  ),
            
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
                      ),
                    )
            
                  else if (_highlights.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                "No highlights found for this date",
                style: TextStyle(color: Colors.white),
              ),
            ),
                      ),
                    )
            
                  // 5️⃣ GRID
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: _gridRatio(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final highlight = _highlights[index];
                return TopRatedCard(
                  highlight: highlight,
                  rank: index + 1,
                );
              },
              childCount: _highlights.length,
            ),
                      ),
                    ),
                ],
              ),
         ),
        ],
      ),
    );
  }
}
