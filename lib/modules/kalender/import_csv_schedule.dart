import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:universal_io/io.dart';

class ImportCsvSchedulePage extends StatefulWidget {
  const ImportCsvSchedulePage({super.key});

  @override
  State<ImportCsvSchedulePage> createState() => _ImportCsvSchedulePageState();
}

class _ImportCsvSchedulePageState extends State<ImportCsvSchedulePage> {
  String? _fileName;
  String? _csvContent;

  Future<void> _pickCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // penting untuk web
      );

      if (result == null) return;

      setState(() {
        _fileName = result.files.single.name;
      });

      // Platform: Web → bytes sudah tersedia
      if (result.files.single.bytes != null) {
        _csvContent = utf8.decode(result.files.single.bytes!);
      } 
      // Platform: Android/Emulator → ambil path
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

  void _importCsv() {
    if (_csvContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada file CSV yang dipilih")),
      );
      return;
    }

    // Di sini kamu bisa parsing atau kirim ke Django melalui API
    print("📄 CSV CONTENT:");
    print(_csvContent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV berhasil diproses")),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fileName ?? 'Belum ada file...',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickCsv,
                        icon: const Icon(Icons.file_open),
                        label: const Text("Pilih File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _importCsv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Import Schedule',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal",
                        style: TextStyle(color: Colors.grey)),
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
