import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/models/calendar_model.dart'; 

class EditSchedulePage extends StatefulWidget {
  final Match matchToEdit;

  const EditSchedulePage({super.key, required this.matchToEdit});

  @override
  State<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController team1Controller;
  late final TextEditingController team1LogoController;
  late final TextEditingController team2Controller;
  late final TextEditingController team2LogoController;
  late final TextEditingController descriptionController;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    team1Controller = TextEditingController(text: widget.matchToEdit.team1);
    team1LogoController = TextEditingController(text: widget.matchToEdit.team1Logo);
    team2Controller = TextEditingController(text: widget.matchToEdit.team2);
    team2LogoController = TextEditingController(text: widget.matchToEdit.team2Logo);
    descriptionController = TextEditingController(text: widget.matchToEdit.description);

    selectedDate = widget.matchToEdit.date;
    selectedTime = TimeOfDay.fromDateTime(widget.matchToEdit.date);
  }

  @override
  void dispose() {
    team1Controller.dispose();
    team1LogoController.dispose();
    team2Controller.dispose();
    team2LogoController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void pickDate() async {
    final DateTime? date = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 320,
            child: CalendarDatePicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              initialDate: selectedDate ?? DateTime.now(),
              onDateChanged: (value) => Navigator.pop(context, value),
            ),
          ),
        );
      },
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  void pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  Future<void> submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null || selectedTime == null) return;

    final dt = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final request = context.read<CookieRequest>();
    
    // PERBAIKAN KRITIS: Menggunakan operator Null Assertion (!) untuk mendapatkan int
    final matchId = widget.matchToEdit.id!; 

    final response = await request.post(
      // Menggunakan matchId
      'http://localhost:8000/kalender/api/edit_match/$matchId/',
      {
        "team1": team1Controller.text,
        "team1_logo": team1LogoController.text,
        "team2": team2Controller.text,
        "team2_logo": team2LogoController.text,
        "datetime": dt.toIso8601String(),
        "description": descriptionController.text,
      },
    );

    if (!mounted) return;

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil diubah.')),
      );
      // Mengirim true agar CalendarScreen me-refresh data
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal mengubah jadwal. Pastikan Anda sudah login.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN UI: Menggunakan operator Null Assertion (!)
    final matchId = widget.matchToEdit.id!;

    final dateText = selectedDate == null
        ? "Pick Date"
        : DateFormat("yyyy-MM-dd").format(selectedDate!);

    final timeText = selectedTime == null
        ? "Pick Time"
        : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Back to Schedule"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Edit Match",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: team1Controller,
                    decoration: const InputDecoration(labelText: "Team 1"),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  TextFormField(
                    controller: team1LogoController,
                    decoration:
                        const InputDecoration(labelText: "Team 1 Logo"),
                  ),
                  TextFormField(
                    controller: team2Controller,
                    decoration: const InputDecoration(labelText: "Team 2"),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  TextFormField(
                    controller: team2LogoController,
                    decoration:
                        const InputDecoration(labelText: "Team 2 Logo"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: pickDate,
                    child: Text(dateText),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: pickTime,
                    child: Text(timeText),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: submitEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save Edit"),
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