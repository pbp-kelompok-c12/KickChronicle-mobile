import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({super.key});

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController team1Controller = TextEditingController();
  final TextEditingController team1LogoController = TextEditingController();
  final TextEditingController team2Controller = TextEditingController();
  final TextEditingController team2LogoController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

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
      initialTime: TimeOfDay.now(),
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


  Future<void> submit() async {
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

    await request.post(
      "http://localhost:8000/kalender/api/add_match/",
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate == null
        ? "Pick Date"
        : DateFormat("yyyy-MM-dd").format(selectedDate!);

    final timeText = selectedTime == null
        ? "Pick Time"
        : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(),
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
                    "Add Schedule",
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
                    onPressed: submit,
                    child: const Text("Submit"),
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
