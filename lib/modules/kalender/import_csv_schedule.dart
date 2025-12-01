import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ImportCsvSchedulePage extends StatefulWidget {
  const ImportCsvSchedulePage({super.key});

  @override
  State<ImportCsvSchedulePage> createState() => _ImportCsvSchedulePageState();
}

class _ImportCsvSchedulePageState extends State<ImportCsvSchedulePage> {
  String? _fileName;
  String? _filePath;
  bool _isLoading = false;

  final String importUrl = 'http://localhost:8000/kalender/import_csv_schedule/';

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    } else {
      setState(() {
        _filePath = null;
        _fileName = null;
      });
    }
  }

  Future<void> _submitImport(CookieRequest request) async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file CSV terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(_filePath!);
      var req = http.MultipartRequest('POST', Uri.parse(importUrl));
      req.files.add(
        await http.MultipartFile.fromPath(
          'csv_file', 
          file.path,
          filename: _fileName,
        ),
      );

      String cookieHeader = request.cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
          
      req.headers['Cookie'] = cookieHeader;
      var streamedResponse = await req.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302 || (response.statusCode >= 200 && response.statusCode < 300)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import jadwal berhasil!')),
          );
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          String errorMessage = response.body.contains("CSRF") 
            ? "Gagal: Sesi login Anda mungkin sudah habis atau file format salah."
            : 'Gagal Import. Status ${response.statusCode}. Cek format file.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Schedule'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Import Schedule from CSV",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Instruksi Format CSV
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instruksi Format File:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'team_1, team_2, date (YYYY-MM-DD), time (HH:MM), description, team_1_logo (URL), team_2_logo (URL)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan 7 kolom ada dan format Tanggal/Waktu sesuai.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Pemilih File
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fileName ?? 'Pilih file CSV...',
                          style: TextStyle(color: _fileName != null ? Colors.white : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.file_upload, size: 18),
                        label: const Text('Pilih File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),

                  // Tombol Submit
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _filePath != null
                              ? () => _submitImport(request)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Import Schedule', style: TextStyle(fontSize: 16)),
                        ),
                        
                  const SizedBox(height: 15),

                  // Tombol Batal
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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