import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/standing.dart';
import 'package:kick_chronicle/services/tim_service.dart';
import 'package:kick_chronicle/widgets/left_drawer.dart';
import 'package:kick_chronicle/modules/kalender/schedule_app_bar.dart';
import 'package:kick_chronicle/modules/tim/team_schedule_page.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

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

  String _uploadSeason = '24/25';
  String? _uploadFileName;
  String? _uploadCsvContent;
  bool _isUploadingCsv = false;

  bool _isStaff = false;
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

      final isStaff = await service.isStaff();
      final seasons = await service.fetchSeasons();
      final defaultSeason = seasons.isNotEmpty ? seasons.last : null;
      final standings = await service.fetchStandings(season: defaultSeason);

      if (mounted) {
        setState(() {
          _isStaff = isStaff;
          _seasons = seasons;
          _selectedSeason = defaultSeason;
          _uploadSeason = defaultSeason ?? _uploadSeason;
          _standings = standings;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isStaff = false;
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

  Future<void> _refreshAfterMutation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = TimService(request);

      final seasons = await service.fetchSeasons();
      String? seasonToUse = _selectedSeason;
      if (seasonToUse != null && !seasons.contains(seasonToUse)) {
        seasonToUse = seasons.isNotEmpty ? seasons.last : null;
      }

      final standings = await service.fetchStandings(season: seasonToUse);

      if (mounted) {
        setState(() {
          _seasons = seasons;
          _selectedSeason = seasonToUse;
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

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _pickStandingsCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      String? csvContent;

      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      }

      if (csvContent == null || csvContent.trim().isEmpty) {
        _showSnack('Failed to read CSV file.', backgroundColor: Colors.red);
        return;
      }

      if (!mounted) return;
      setState(() {
        _uploadFileName = file.name;
        _uploadCsvContent = csvContent;
      });

      _showSnack('CSV loaded: ${file.name}');
    } catch (e) {
      _showSnack('Failed to pick CSV: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _uploadStandingsCsv() async {
    final csv = _uploadCsvContent;
    if (csv == null || csv.trim().isEmpty) {
      _showSnack('Please choose a CSV file first.', backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isUploadingCsv = true;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = TimService(request);

      final resp = await service.uploadStandingsCsv(
        season: _uploadSeason,
        csvContent: csv,
      );

      final status = resp['status']?.toString();
      if (status == 'success') {
        _showSnack(resp['message']?.toString() ?? 'Upload successful.');

        if (mounted) {
          setState(() {
            _uploadFileName = null;
            _uploadCsvContent = null;
            _selectedSeason = _uploadSeason;
          });
        }

        await _refreshAfterMutation();
      } else {
        _showSnack(
          resp['message']?.toString() ?? 'Upload failed.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showSnack('Upload failed: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCsv = false;
        });
      }
    }
  }

  Future<void> _openStandingForm([Standing? existing]) async {
    final seasonOptions = (_seasons.isNotEmpty)
        ? _seasons
        : const ['22/23', '23/24', '24/25'];

    String seasonValue = existing?.season ??
        _selectedSeason ??
        (seasonOptions.isNotEmpty ? seasonOptions.last : '24/25');

    final teamController = TextEditingController(text: existing?.team ?? '');
    final positionController =
        TextEditingController(text: existing?.position.toString() ?? '');
    final playedController =
        TextEditingController(text: existing?.played.toString() ?? '0');
    final wonController =
        TextEditingController(text: existing?.won.toString() ?? '0');
    final drawnController =
        TextEditingController(text: existing?.drawn.toString() ?? '0');
    final lostController =
        TextEditingController(text: existing?.lost.toString() ?? '0');
    final gfController =
        TextEditingController(text: existing?.goalsFor.toString() ?? '0');
    final gaController =
        TextEditingController(text: existing?.goalsAgainst.toString() ?? '0');
    final ptsController =
        TextEditingController(text: existing?.points.toString() ?? '0');

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool isSaving = false;
          String? errorText;

          InputDecoration deco(String hint) => InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1F2937),
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              );

          Widget numberField({
            required String label,
            required TextEditingController controller,
            int min = 0,
            int? max,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: deco(label),
                  validator: (value) {
                    final v = int.tryParse(value ?? '');
                    if (v == null) return 'Invalid';
                    if (v < min) return 'Min $min';
                    if (max != null && v > max) return 'Max $max';
                    return null;
                  },
                ),
              ],
            );
          }

          return Theme(
            data: ThemeData.dark().copyWith(
              dialogBackgroundColor: Colors.black,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4F46E5),
                surface: Colors.black,
              ),
            ),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                Future<void> onSave() async {
                  if (isSaving) return;
                  if (!formKey.currentState!.validate()) return;

                  final position = int.tryParse(positionController.text) ?? 0;
                  if (position < 1 || position > 20) {
                    setStateDialog(() {
                      errorText = 'Position must be between 1 and 20.';
                    });
                    return;
                  }

                  final payload = <String, dynamic>{
                    'season': seasonValue,
                    'position': position,
                    'team': teamController.text.trim(),
                    'played': int.parse(playedController.text),
                    'won': int.parse(wonController.text),
                    'drawn': int.parse(drawnController.text),
                    'lost': int.parse(lostController.text),
                    'goals_for': int.parse(gfController.text),
                    'goals_against': int.parse(gaController.text),
                    'points': int.parse(ptsController.text),
                  };

                  final request = context.read<CookieRequest>();
                  final service = TimService(request);

                  setStateDialog(() {
                    isSaving = true;
                    errorText = null;
                  });

                  Map<String, dynamic> resp;
                  if (existing == null) {
                    resp = await service.createStanding(payload);
                  } else {
                    final id = int.tryParse(existing.id);
                    if (id == null) {
                      setStateDialog(() {
                        isSaving = false;
                        errorText = 'Invalid standing id.';
                      });
                      return;
                    }
                    resp = await service.editStanding(id, payload);
                  }

                  if (!mounted) return;

                  if (resp['status'] == 'success') {
                    Navigator.pop(dialogContext);
                    _showSnack(resp['message']?.toString() ?? 'Saved.');
                    await _refreshAfterMutation();
                    return;
                  }

                  setStateDialog(() {
                    isSaving = false;
                    errorText = resp['message']?.toString() ?? 'Failed to save.';
                  });
                }

                return AlertDialog(
                  title: Text(
                    existing == null ? 'Add Standing' : 'Edit Standing',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SizedBox(
                    width: 520,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (errorText != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Text(
                                  errorText!,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Text(
                              'Season',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: seasonValue,
                              dropdownColor: const Color(0xFF111827),
                              decoration: deco('Season'),
                              items: seasonOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setStateDialog(() {
                                  seasonValue = v;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Team',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: teamController,
                              style: const TextStyle(color: Colors.white),
                              decoration: deco('Team name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Team is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            numberField(
                              label: 'Position',
                              controller: positionController,
                              min: 1,
                              max: 20,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: numberField(
                                    label: 'Pld',
                                    controller: playedController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: numberField(
                                    label: 'Pts',
                                    controller: ptsController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: numberField(
                                    label: 'W',
                                    controller: wonController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: numberField(
                                    label: 'D',
                                    controller: drawnController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: numberField(
                                    label: 'L',
                                    controller: lostController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: numberField(
                                    label: 'GF',
                                    controller: gfController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: numberField(
                                    label: 'GA',
                                    controller: gaController,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: isSaving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      teamController.dispose();
      positionController.dispose();
      playedController.dispose();
      wonController.dispose();
      drawnController.dispose();
      lostController.dispose();
      gfController.dispose();
      gaController.dispose();
      ptsController.dispose();
    }
  }

  Future<void> _showStandingActions(Standing standing) async {
    if (!_isStaff) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B0B0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  standing.team,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openStandingForm(standing);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteStanding(standing);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteStanding(Standing standing) async {
    final id = int.tryParse(standing.id);
    if (id == null) {
      _showSnack('Invalid standing id.', backgroundColor: Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text('Confirm deletion', style: TextStyle(color: Colors.white)),
            content: Text(
              'Delete ${standing.team} (pos ${standing.position})?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final request = context.read<CookieRequest>();
    final service = TimService(request);
    final resp = await service.deleteStanding(id);

    if (resp['status'] == 'success') {
      _showSnack(resp['message']?.toString() ?? 'Deleted.');
      await _refreshAfterMutation();
      return;
    }

    _showSnack(
      resp['message']?.toString() ?? 'Failed to delete.',
      backgroundColor: Colors.red,
    );
  }

  Future<void> _showClearSeasonDialog() async {
    if (!_isStaff) return;

    final options = (_seasons.isNotEmpty)
        ? _seasons
        : const ['22/23', '23/24', '24/25'];

    String season = _selectedSeason ?? (options.isNotEmpty ? options.last : '24/25');

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return Theme(
              data: ThemeData.dark().copyWith(dialogBackgroundColor: Colors.black),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return AlertDialog(
                    title: const Text(
                      'Clear season standings',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select season to delete all standings:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: season,
                          dropdownColor: const Color(0xFF111827),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1F2937),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                          ),
                          items: options
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setStateDialog(() {
                              season = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This will delete ALL standings for the selected season.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Delete all'),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    final request = context.read<CookieRequest>();
    final service = TimService(request);
    final resp = await service.clearSeason(season);

    if (resp['status'] == 'success') {
      _showSnack(resp['message']?.toString() ?? 'Season cleared.');
      await _refreshAfterMutation();
      return;
    }

    _showSnack(
      resp['message']?.toString() ?? 'Failed to clear season.',
      backgroundColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredStandings;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const ScheduleAppBar(),
      drawer: const LeftDrawer(),
      floatingActionButton: _isStaff
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              onPressed: () => _openStandingForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitial,
          color: const Color(0xFF4F46E5),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _headerSection()),
                if (_isStaff) SliverToBoxAdapter(child: _uploadSection()),
                SliverToBoxAdapter(child: _filterSection()),
                ..._buildStandingsSlivers(rows),
              ],
            ),
          ),
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

  Widget _uploadSection() {
    const seasonOptions = ['22/23', '23/24', '24/25'];

    final decoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFF111827),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4F46E5)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E111A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Standings Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Season',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: seasonOptions.contains(_uploadSeason)
                  ? _uploadSeason
                  : seasonOptions.last,
              dropdownColor: const Color(0xFF111827),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: decoration,
              items: seasonOptions
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s,
                      child: Text(_formatSeasonLabel(s)),
                    ),
                  )
                  .toList(),
              onChanged: _isUploadingCsv
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _uploadSeason = value;
                      });
                    },
            ),
            const SizedBox(height: 14),
            const Text(
              'CSV File',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _uploadFileName ?? 'No file chosen',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploadingCsv ? null : _pickStandingsCsv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Choose File'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a CSV file with columns: pos, team, pld, w, d, l, gf, ga, gd, pts',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_uploadCsvContent != null && !_isUploadingCsv)
                    ? _uploadStandingsCsv
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isUploadingCsv
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Upload Standings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
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
          if (_isStaff) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Admin mode: long-press a row to edit/delete.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showClearSeasonDialog,
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'Clear season',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
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

  List<Widget> _buildStandingsSlivers(List<Standing> rows) {
    if (_isLoading && _standings.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_hasError && _standings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (rows.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              "No standings found for this filter",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ];
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

    final children = <Widget>[];
    for (final season in seasonsOrder) {
      children.add(
        _seasonTableCard(
          seasonLabel: _formatSeasonLabel(season),
          rows: grouped[season]!,
        ),
      );
      children.add(const SizedBox(height: 16));
    }
    children.add(_legend());
    children.add(const SizedBox(height: 24));

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildListDelegate(children),
        ),
      ),
    ];
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

    return GestureDetector(
      onLongPress: _isStaff ? () => _showStandingActions(s) : null,
      child: Container(
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamSchedulePage(
                              teamName: s.team,
                              queryTeamName: s.calendarTeamQuery,
                            ),
                          ),
                        );
                      },
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
                  color: s.goalDifference >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
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
    final String? assetPath = s.assetLogoPath;

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
