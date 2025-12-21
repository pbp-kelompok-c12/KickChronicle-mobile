import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AdminHighlightPage extends StatefulWidget {
  const AdminHighlightPage({super.key});

  @override
  State<AdminHighlightPage> createState() => _AdminHighlightPageState();
}

class _AdminHighlightPageState extends State<AdminHighlightPage> {
  List<dynamic> _highlights = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final request = context.read<CookieRequest>();
    final url = "${ApiConfig.baseUrl}/admin-highlight-flutter/";

    try {
      final response = await request.get(url);
      if (mounted) {
        setState(() {
          _highlights = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e")),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} highlight(s)?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    final request = context.read<CookieRequest>();
    final url = "${ApiConfig.baseUrl}/admin-highlight-flutter/";

    try {
      final response = await request.postJson(
        url,
        jsonEncode({'ids': _selectedIds.toList()}),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
          // Clear selection and refresh list
          setState(() {
            _selectedIds.clear();
            _isDeleting = false;
            _isLoading = true;
          });
          _fetchAdminData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response['message']}")),
          );
          setState(() {
            _isDeleting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.addAll(_highlights.map((h) => h['id'].toString()));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        title: const Text("Admin - Manage Highlights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            Row(
              children: [
                const Text("Select All", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Checkbox(
                  value: _highlights.isNotEmpty && _selectedIds.length == _highlights.length,
                  onChanged: _toggleSelectAll,
                  activeColor: const Color(0xFF4F46E5),
                  checkColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ],
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _highlights.isEmpty
                ? const Center(child: Text("No highlights found", style: TextStyle(color: Colors.white)))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _highlights.length,
              separatorBuilder: (ctx, idx) => const Divider(color: Color(0xFF374151)),
              itemBuilder: (context, index) {
                final item = _highlights[index];
                final id = item['id'].toString();
                final isSelected = _selectedIds.contains(id);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) => _toggleItem(id),
                    activeColor: const Color(0xFF4F46E5),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  title: Text(
                    item['name'] ?? "No Name",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Created: ${item['created_at'] ?? 'N/A'}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      // For single deletion, just re-use the delete logic
                      setState(() {
                        _selectedIds.clear();
                        _selectedIds.add(id);
                      });
                      _deleteSelected();
                    },
                  ),
                  onTap: () => _toggleItem(id),
                );
              },
            ),
          ),

          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                border: Border(top: BorderSide(color: Color(0xFF374151))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${_selectedIds.length} selected",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isDeleting ? null : _deleteSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        disabledBackgroundColor: Colors.redAccent.withOpacity(0.5),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.delete),
                      label: Text(_isDeleting ? "Deleting..." : "Delete Selected"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}