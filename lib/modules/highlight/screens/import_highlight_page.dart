import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;

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
      withData: true, // Crucial for Web access to bytes
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

    // --- FIX 1: URL CONSISTENCY ---
    // If you run your Flutter app on 'localhost', you MUST send requests to 'localhost'.
    // If you send them to '127.0.0.1', the browser will BLOCK your cookies.
    String url = "${ApiConfig.baseUrl}/add-highlights-csv-flutter/";

    try {
      var uri = Uri.parse(url);
      var multipartRequest = http.MultipartRequest("POST", uri);

      // --- FIX 2: HANDLE COOKIES CORRECTLY ---
      if (kIsWeb) {
        // On Web, the browser handles cookies automatically IF the domains match.
        // We do NOT manually add headers here because it triggers a security error.
        // Ensure your Django settings.py has:
        // CORS_ALLOW_CREDENTIALS = True
        // CORS_ALLOWED_ORIGINS = ["http://localhost:YOUR_FLUTTER_PORT"]
      } else {
        // Mobile logic (Keep this as it was working for mobile)
        Map<String, String> headers = Map.from(request.headers);
        if (request.cookies.isNotEmpty) {
          String cookieHeader = request.cookies.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
          headers['cookie'] = cookieHeader;
        }
        multipartRequest.headers.addAll(headers);
      }

      // Add File
      if (_pickedFile!.bytes != null) {
        multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              'csv_file',
              _pickedFile!.bytes!,
              filename: _pickedFile!.name,
            )
        );
      } else if (_pickedFile!.path != null) {
        multipartRequest.files.add(
            await http.MultipartFile.fromPath(
              'csv_file',
              _pickedFile!.path!,
            )
        );
      }

      var streamResponse = await multipartRequest.send();
      var response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          final resJson = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resJson['message']), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          // DEBUGGING: Print the HTML to console if it fails again
          print("SERVER RESPONSE: ${response.body}");

          String errorMessage = "Upload failed. Status: ${response.statusCode}";
          try {
            final resJson = jsonDecode(response.body); // This crashes if body is HTML
            errorMessage = resJson['message'] ?? errorMessage;
          } catch (_) {
            if (response.body.contains("<!DOCTYPE html>")) {
              errorMessage = "Login Error: Domains mismatch (localhost vs 127.0.0.1)";
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
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
                "Header row required: Name, URL, Description, Manual Thumbnail URL, Season",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_pickedFile != null && !_isUploading) ? _uploadFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
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