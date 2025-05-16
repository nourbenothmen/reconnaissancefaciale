import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'face_storage.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({Key? key}) : super(key: key);

  @override
  _AllTasksScreenState createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final FaceStorageFirebase _storage = FaceStorageFirebase();
  List<Map<String, dynamic>> allTasks = [];

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: false)
          .get();
      setState(() {
        allTasks = querySnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de chargement des tâches : $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    final TextEditingController _descriptionController = TextEditingController(text: task['description']);
    DateTime? _taskDateTime = DateTime.parse(
        '${task['date'].split('/')[2]}-${task['date'].split('/')[1]}-${task['date'].split('/')[0]} '
            '${task['time'].split(':')[0]}:${task['time'].split(':')[1]}:00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier la tâche", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description", labelStyle: GoogleFonts.poppins()),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _taskDateTime ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFF1E90FF),
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E90FF)),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_taskDateTime ?? DateTime.now()),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _taskDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Date et Heure",
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _taskDateTime != null
                      ? "${DateFormat('dd/MM/yyyy').format(_taskDateTime!)} ${DateFormat('HH:mm').format(_taskDateTime!)}"
                      : "Sélectionner...",
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              if (_descriptionController.text.isEmpty || _taskDateTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez remplir tous les champs."),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final newTask = {
                'description': _descriptionController.text,
                'date': DateFormat('dd/MM/yyyy').format(_taskDateTime!),
                'time': DateFormat('HH:mm').format(_taskDateTime!),
                'timestamp': Timestamp.fromDate(_taskDateTime!),
              };
              await _storage.updateTask(task['id'], newTask);
              Navigator.pop(context);
              await _loadAllTasks();
            },
            child: Text("Enregistrer", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    await _storage.deleteTask(task['id']);
    await _loadAllTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Toutes les tâches", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E90FF), Color(0xFF87CEFA)],
            ),
          ),
        ),
        elevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E90FF), Color(0xFFE6E6FA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: allTasks.isEmpty
              ? const Center(child: Text("Aucune tâche trouvée.", style: TextStyle(color: Colors.white)))
              : ListView.builder(
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              return Card(
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(task['description'], style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text("${task['date']} ${task['time']}", style: GoogleFonts.poppins(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _editTask(task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteTask(task),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}