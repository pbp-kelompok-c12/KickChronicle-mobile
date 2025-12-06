import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/models/highlight.dart';

class EditHighlightPage extends StatefulWidget {
  final Highlight highlight;

  const EditHighlightPage({super.key, required this.highlight});

  @override
  State<EditHighlightPage> createState() => _EditHighlightPageState();
}

class _EditHighlightPageState extends State<EditHighlightPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _thumbnailController;
  late TextEditingController _descriptionController;
  late TextEditingController _createdAtController;

  String? _selectedSeason;

  // Hardcoded season options based on your Enum logic or screenshot
  final List<String> _seasonOptions = ["22/23", "23/24", "24/25"];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.highlight.name);
    _urlController = TextEditingController(text: widget.highlight.url);
    _thumbnailController = TextEditingController(text: widget.highlight.manualThumbnailUrl ?? "");
    _descriptionController = TextEditingController(text: widget.highlight.description);
    _createdAtController = TextEditingController(text: widget.highlight.createdAt.toString()); // Simplified ISO string

    // Map the current enum to the string value for the dropdown
    _selectedSeason = seasonValues.reverse[widget.highlight.season];
    // Fallback if the map fails
    if (!_seasonOptions.contains(_selectedSeason)) {
      _selectedSeason = _seasonOptions.last;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _thumbnailController.dispose();
    _descriptionController.dispose();
    _createdAtController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final request = context.read<CookieRequest>();

    // Replace with your actual local IP/URL
    final url = 'http://127.0.0.1:8000/edit-highlight-flutter/${widget.highlight.id}/';

    final response = await request.postJson(
      url,
      jsonEncode({
        'name': _nameController.text,
        'url': _urlController.text,
        'manual_thumbnail_url': _thumbnailController.text.isEmpty ? null : _thumbnailController.text,
        'description': _descriptionController.text,
        'season': _selectedSeason,
      }),
    );

    if (context.mounted) {
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Changes saved successfully!")),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response['message']}")),
        );
      }
    }
  }

  // Helper to build consistent input fields
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? helperText,
    bool readOnly = false,
    String? Function(String?)? validator, // ADDED: Custom validator support
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1F2937), // Dark grey background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          // UPDATED: Use the passed validator, or default to required check if not readOnly
          validator: validator ?? (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back to Main Menu",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        titleSpacing: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit Highlight",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    label: "Name",
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a name";
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: "Url",
                    controller: _urlController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a video URL";
                      }
                      // Simple URL regex check (optional but good)
                      // if (!Uri.parse(value).isAbsolute) {
                      //   return "Please enter a valid URL";
                      // }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: "Manual thumbnail url",
                    controller: _thumbnailController,
                    helperText: "Enter URL for a thumbnail if the video URL isn't from YouTube/Vimeo.",
                    validator: (value) {
                      // Optional field, so return null (valid) even if empty
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: "Description",
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a description";
                      }
                      return null;
                    },
                  ),

                  // Created At (Read-only recommended for integrity, but styled as input)
                  _buildTextField(label: "Created at", controller: _createdAtController, readOnly: true),

                  // Season Dropdown
                  const Text(
                    "Season",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSeason,
                    dropdownColor: const Color(0xFF1F2937),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      helperText: "Select the season this highlight belongs to.",
                      helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    items: _seasonOptions.map((String season) {
                      return DropdownMenuItem<String>(
                        value: season,
                        child: Text(season),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSeason = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select a season";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100), // Orange color from screenshot
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}