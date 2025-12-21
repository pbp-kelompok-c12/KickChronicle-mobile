import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kick_chronicle/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/models/calendar_model.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;

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
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFCCCCCC),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
              background: Colors.black,
            ),
            dialogBackgroundColor: Colors.black,
            textTheme: const TextTheme(
              titleLarge: TextStyle(color: Colors.white),
              labelLarge: TextStyle(color: Colors.white),
            ),
          ),
          child: AlertDialog(
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
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFCCCCCC),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
              background: Colors.black,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Colors.white),
              displayMedium: TextStyle(color: Colors.white),
              labelLarge: TextStyle(color: Colors.white),
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
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

    final String dateStr = DateFormat("yyyy-MM-dd").format(selectedDate!);
    final String timeStr = 
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    final request = context.read<CookieRequest>();
    
    final matchId = widget.matchToEdit.id!; 

    String baseUrl = ApiConfig.baseUrl;
    String editMatchUrl = '$baseUrl/kalender/edit/$matchId/';
    
    final response = await request.post(
      editMatchUrl,
      {
        "team_1": team1Controller.text, 
        "team_1_logo": team1LogoController.text, 
        "team_2": team2Controller.text,
        "team_2_logo": team2LogoController.text,
        "date": dateStr, 
        "time": timeStr, 
        "description": descriptionController.text,
      },
    );

    if (!mounted) return;

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil diubah.')),
      );
      Navigator.pop(context, true); 
    } else {
      String errorMsg = "Gagal mengubah jadwal. ";
      if (response.containsKey('errors') && response['errors'] is Map) {
          Map errors = response['errors'] as Map;
          errorMsg += "Detail Form: " + errors.values.map((v) => (v is List) ? v.join(', ') : v).join('; ');
      } else {
          errorMsg += response['message'] ?? 'Pastikan Anda sudah login.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isRequired = true,
  }) {
    const Color inputFillColor = Color(0xFF1A1A1A); 
    const Color labelColor = Color(0xFFCCCCCC);
    const Color borderColor = Color(0xFF333333);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: labelColor),
          filled: true,
          fillColor: inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6), 
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF666666), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: borderColor),
          ),
        ),
        validator: isRequired
            ? (v) => (v == null || v.isEmpty) ? "Field ini wajib diisi" : null
            : null,
      ),
    );
  }

  Widget _buildDateButton({required String text, required VoidCallback onPressed, required IconData icon}) {
    const Color inputFillColor = Color(0xFF1A1A1A); 
    const Color borderColor = Color(0xFF333333);
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: inputFillColor, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: borderColor), 
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 16)), 
          Icon(icon, size: 18, color: const Color(0xFFCCCCCC)), 
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate == null
        ? "Pick Date"
        : DateFormat("dd-MM-yyyy").format(selectedDate!);

    final timeText = selectedTime == null
        ? "Pick Time"
        : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Back to Schedule", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black, 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      "Edit Schedule",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextInput(team1Controller, "Team 1"),
                    _buildTextInput(team1LogoController, "Team 1 Logo", isRequired: false),
                    _buildTextInput(team2Controller, "Team 2"),
                    _buildTextInput(team2LogoController, "Team 2 Logo", isRequired: false),
                    
                    const SizedBox(height: 20),
                    
                    _buildDateButton(onPressed: pickDate, text: dateText, icon: Icons.calendar_today),
                    const SizedBox(height: 10),
                    _buildDateButton(onPressed: pickTime, text: timeText, icon: Icons.access_time),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextInput(descriptionController, "Description", maxLines: 3, isRequired: false),
                    
                    const SizedBox(height: 25),
                    
                    const Divider(color: Color(0xFF374151), height: 1),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitEdit,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Save Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}