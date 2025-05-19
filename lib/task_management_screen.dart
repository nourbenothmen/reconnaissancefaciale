import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'face_storage.dart';
import 'all_tasks_screen.dart';

class TaskManagementScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final Function(List<Map<String, dynamic>>) onTasksMatched;

  const TaskManagementScreen({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.onTasksMatched,
  }) : super(key: key);

  @override
  _TaskManagementScreenState createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final TextEditingController _taskDescriptionController = TextEditingController();
  DateTime? _taskDateTime;
  final FaceStorageFirebase _storage = FaceStorageFirebase();
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> matchedTasks = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isPeriodicCheckRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTasks();
    _startPeriodicCheck();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tunis')); // Set to Tunisia timezone
    print('Current timezone: ${tz.local.name}'); // Log timezone for verification
  }

  Future<void> _loadTasks() async {
    try {
      final fetchedTasks = await _storage.getTasks(widget.patientId);
      if (mounted) {
        setState(() {
          tasks = fetchedTasks;
        });
        _checkForMatchingTasks();
        _scheduleNotifications();
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  void _startPeriodicCheck() {
    if (_isPeriodicCheckRunning) return;
    _isPeriodicCheckRunning = true;
    Future.doWhile(() async {
      if (!mounted) {
        _isPeriodicCheckRunning = false;
        return false;
      }
      await Future.delayed(const Duration(seconds: 10));
      _checkForMatchingTasks();
      return true;
    });
  }

  void _checkForMatchingTasks() {
    if (!mounted) return;
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final currentDate = dateFormat.format(now);

    print('Checking tasks at ${dateFormat.format(now)} ${timeFormat.format(now)}');

    List<Map<String, dynamic>> newMatchedTasks = [];

    for (var task in tasks) {
      print('Task: ${task['description']}, Date: ${task['date']}, Time: ${task['time']}');
      final taskDateTime = DateTime.parse(
          '${task['date'].split('/')[2]}-${task['date'].split('/')[1]}-${task['date'].split('/')[0]} '
              '${task['time'].split(':')[0]}:${task['time'].split(':')[1]}:00');
      if (task['date'] == currentDate &&
          taskDateTime.difference(now).inMinutes.abs() <= 5) {
        print('Match found: ${task['description']}');
        newMatchedTasks.add(task);
      }
    }

    if (mounted) {
      setState(() {
        matchedTasks = newMatchedTasks;
      });
      widget.onTasksMatched(matchedTasks);
    }
  }
  Future<void> _scheduleNotifications() async {
    print('Attempting to schedule notifications for ${tasks.length} tasks');
    for (var task in tasks) {
      final taskDateTime = DateTime.parse(
          '${task['date'].split('/')[2]}-${task['date'].split('/')[1]}-${task['date'].split('/')[0]} '
              '${task['time'].split(':')[0]}:${task['time'].split(':')[1]}:00');
      if (taskDateTime.isAfter(DateTime.now())) {
        try {
          print('Scheduling exact alarm for ${task['description']} at ${taskDateTime}');
          await flutterLocalNotificationsPlugin.zonedSchedule(
            task['id'].hashCode,
            'Rappel de tâche',
            '${task['description']} à ${task['date']} ${task['time']}',
            tz.TZDateTime.from(taskDateTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_channel_id',
                'Task Reminders',
                channelDescription: 'Notifications for task reminders',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
          print('Successfully scheduled notification for ${task['description']} at ${task['date']} ${task['time']}');
        } catch (e) {
          print('Failed to schedule exact alarm for ${task['description']}: $e');
          print('Attempting inexact alarm for ${task['description']}');
          await flutterLocalNotificationsPlugin.zonedSchedule(
            task['id'].hashCode,
            'Rappel de tâche',
            '${task['description']} à ${task['date']} ${task['time']}',
            tz.TZDateTime.from(taskDateTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_channel_id',
                'Task Reminders',
                channelDescription: 'Notifications for task reminders',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexact,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
          print('Successfully scheduled inexact notification for ${task['description']} as fallback');
        }
      } else {
        print('Skipping notification for ${task['description']} as it is in the past');
      }
    }
  }
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _taskDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_taskDateTime ?? DateTime.now()),
      );
      if (pickedTime != null && mounted) {
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
  }

  Future<void> _addTask() async {
    if (_taskDescriptionController.text.isEmpty || _taskDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer une description et une date/heure."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _storage.addTask(
      widget.patientId,
      _taskDescriptionController.text,
      _taskDateTime!,
    );
    if (mounted) {
      setState(() {
        _taskDescriptionController.clear();
        _taskDateTime = null;
      });
      await _loadTasks();
    }
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    _taskDescriptionController.text = task['description'];
    _taskDateTime = DateTime.parse(
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
              controller: _taskDescriptionController,
              decoration: InputDecoration(labelText: "Description", labelStyle: GoogleFonts.poppins()),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _selectDateTime(context),
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
              if (_taskDescriptionController.text.isEmpty || _taskDateTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez remplir tous les champs."),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final newTask = {
                'description': _taskDescriptionController.text,
                'date': DateFormat('dd/MM/yyyy').format(_taskDateTime!),
                'time': DateFormat('HH:mm').format(_taskDateTime!),
                'timestamp': Timestamp.fromDate(_taskDateTime!),
              };
              await _storage.updateTask(task['id'], newTask);
              Navigator.pop(context);
              if (mounted) {
                _taskDescriptionController.clear();
                _taskDateTime = null;
                await _loadTasks();
              }
            },
            child: Text("Enregistrer", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    await _storage.deleteTask(task['id']);
    await flutterLocalNotificationsPlugin.cancel(task['id'].hashCode);
    if (mounted) await _loadTasks();
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF1E90FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: GoogleFonts.poppins(color: Colors.white),
    );
  }

  @override
  void dispose() {
    _isPeriodicCheckRunning = false;
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des tâches", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllTasksScreen(),
                ),
              );
            },
          ),
        ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_taskDescriptionController, "Description de la tâche", Icons.task),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectDateTime(context),
                child: Text(
                  _taskDateTime != null
                      ? "Date/Heure: ${DateFormat('dd/MM/yyyy HH:mm').format(_taskDateTime!)}"
                      : "Choisir Date/Heure",
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF).withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addTask,
                child: Text("Ajouter", style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF).withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
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
            ],
          ),
        ),
      ),
    );
  }
}