import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:provider/provider.dart'; 
import 'package:pbp_django_auth/pbp_django_auth.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

class ImportCsvSchedulePage extends StatefulWidget {
  const ImportCsvSchedulePage({super.key});

  @override
  State<ImportCsvSchedulePage> createState() => _ImportCsvSchedulePageState();
}

class _ImportCsvSchedulePageState extends State<ImportCsvSchedulePage> {
  String? _fileName;
  String? _csvContent;

  final String baseHost = ApiConfig.baseUrl;

  Future<void> _pickCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, 
      );

      if (result == null) return;

      setState(() {
        _fileName = result.files.single.name;
      });

      if (result.files.single.bytes != null) {
        _csvContent = utf8.decode(result.files.single.bytes!);
      } 
      else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        _csvContent = await file.readAsString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File berhasil di-load: $_fileName")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat file CSV: $e")),
      );
    }
  }

  Future<void> _importCsv() async { 
    if (_csvContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada file CSV yang dipilih")),
      );
      return;
    }

    final request = context.read<CookieRequest>();
    final String importUrl = "$baseHost/kalender/api/import_flutter/"; 

    try {
      final response = await request.post(
          importUrl,
          {'csv_content': _csvContent}, 
      );

      if (mounted) {
          if (response['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['message'] ?? "Impor jadwal berhasil!")),
              );
              Navigator.pop(context, true); 
          } else {
              String errorMsg = "Impor gagal. ";
              if (response.containsKey('errors')) {
                 errorMsg += "Detail Form: " + response['errors'].toString();
              } else {
                 errorMsg += response['message'] ?? "Kesalahan tak terduga dari server.";
              }
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
              );
          }
      }

    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Kesalahan jaringan saat impor: $e")),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Back to Schedule', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                [
                  const Text(
                    "Import Schedule from CSV",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fileName ?? 'No file choosen',
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _pickCsv,
                          icon: const Icon(Icons.file_upload, size: 20),
                          label: const Text("Choose File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, 
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  OutlinedButton(
                    onPressed: _importCsv,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white, width: 2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Import Schedule',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white, width: 2.0), 
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}