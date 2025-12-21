import 'package:flutter/material.dart';
import 'package:kick_chronicle/models/calendar_model.dart';
import 'package:intl/intl.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DetailSchedulePage extends StatelessWidget {
  final Match match;
  const DetailSchedulePage({super.key, required this.match});
  String get baseHost => ApiConfig.baseUrl;
  String get icsBaseUrl => "${ApiConfig.baseUrl}/kalender/export/";

  Future<void> _exportIcs(BuildContext context) async {
    if (match.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID jadwal tidak ditemukan.')),
      );
      return;
    }

    final url = Uri.parse('$icsBaseUrl${match.id!}/');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka URL ekspor: $url')));
    }
  }

  Widget _buildLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets')) {
        return Image.asset(
          url,
          height: 60,
          width: 60,
          fit: BoxFit.contain,
          errorBuilder: (c, o, s) => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade500),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 40,
              color: Colors.white70,
            ),
          ),
        );
      }

      final String fullUrl = url.startsWith('http') ? url : baseHost + url;

      return Image.network(
        fullUrl,
        height: 60,
        width: 60,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade500),
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 40,
            color: Colors.white70,
          ),
        ),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: const Icon(Icons.shield_outlined, size: 40, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(match.date);
    final formattedTime = DateFormat('HH:mm').format(match.date);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Detail Jadwal',
          style: TextStyle(color: Colors.white),
        ),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLogo(match.team1Logo),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.team1,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLogo(match.team2Logo),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.team2,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40, color: Colors.white10),
                        Text(
                          '🗓️ Date: $formattedDate',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '⏰ Time: $formattedTime',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (match.description != null &&
                      match.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Match Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match.description!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[300],
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _exportIcs(context),
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Export to Calendar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Colors.white, width: 2.0),
                      ),
                    ),
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
