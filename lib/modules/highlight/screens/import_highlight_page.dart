import 'dart:convert'; // For jsonDecode if response is string
import 'dart:io'; // Not needed for web/bytes based upload usually, but good for File(path)
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http; // pbp_django_auth uses http internally, but we might need multipart request support

class ImportHighlightPage extends StatefulWidget {
  const ImportHighlightPage({super.key});

  @override
  State<ImportHighlightPage> createState() => _ImportHighlightPageState();
}

class _ImportHighlightPageState extends State<ImportHighlightPage> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Important for web/cross-platform byte access
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    final request = context.read<CookieRequest>();
    const url = 'http://127.0.0.1:8000/add-highlights-csv-flutter/';

    try {
      // pbp_django_auth might not have a direct multipart/form-data helper convenient for files.
      // However, it's often easier to use the underlying http package or construct it manually
      // if the library doesn't support file upload directly.
      //
      // Assuming pbp_django_auth's CookieRequest doesn't block us from accessing cookies,
      // we can construct a MultipartRequest manually but we need the cookies.
      //
      // ALTERNATIVE: Since pbp_django_auth wraps http, let's try to see if we can use its client
      // or just standard http.post with manual cookie handling if needed.
      // But for simplicity in this snippet, let's assume we can use a standard MultipartRequest
      // and if pbp_django_auth is needed for session, we might need a workaround.

      // Let's try creating a Multipart request using the 'http' package which pbp_django_auth is based on.
      // But we need to ensure session cookies are passed if authentication was required (you said admin check not needed for now).

      // Since authentication is NOT required for this specific view (per your request), standard http is fine.

      // NOTE: You need to add 'http' to pubspec.yaml if not already there,
      // but pbp_django_auth depends on it so it should be available.

      // We will use the request.postUrl (which expects json) or similar? No, that won't work for files.
      // We have to implement a custom multipart upload here.

      var uri = Uri.parse(url);
      var multipartRequest = http.MultipartRequest("POST", uri);

      // Add the file
      // On web/mobile, use bytes.
      if (_pickedFile!.bytes != null) {
        multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              'csv_file',
              _pickedFile!.bytes!,
              filename: _pickedFile!.name,
            )
        );
      } else if (_pickedFile!.path != null) {
        // Fallback for mobile if bytes are null (though withData: true usually populates bytes on web, path on mobile)
        multipartRequest.files.add(
            await http.MultipartFile.fromPath(
              'csv_file',
              _pickedFile!.path!,
            )
        );
      }

      var streamResponse = await multipartRequest.send();
      var response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Import successful!")),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        if (mounted) {
          // Parse error message
          try {
            final resJson = jsonDecode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${resJson['message']}")),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed. Status: ${response.statusCode}")),
            );
          }
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        title: const Text("Import Highlights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select CSV File (.csv)",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // File Picker Row
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Choose File"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedFile != null ? _pickedFile!.name : "No file chosen",
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                "Header row: Name, URL, Description, Manual Thumbnail URL (optional), Season (e.g. 2024/2025)",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, // Full width button
                child: ElevatedButton(
                  onPressed: (_pickedFile != null && !_isUploading) ? _uploadFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), // Blue accent
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: _isUploading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text("Upload & Import Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}