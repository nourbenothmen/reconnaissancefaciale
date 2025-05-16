import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'face_storage.dart';

class RDVScreen extends StatefulWidget {
  final String user;
  final Map<String, dynamic>? patientData;
  final String patientId;
  final VoidCallback? onVisitAdded;

  const RDVScreen({
    Key? key,
    required this.user,
    this.patientData,
    required this.patientId,
    this.onVisitAdded,
  }) : super(key: key);

  @override
  _RDVScreenState createState() => _RDVScreenState();
}

class _RDVScreenState extends State<RDVScreen> with TickerProviderStateMixin {
  late final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  late final DateFormat _timeFormat = DateFormat('HH:mm');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fonction pour récupérer tous les patients et filtrer les rendez-vous du jour
  Stream<QuerySnapshot> _getPatients() {
    return _firestore.collection('patients').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Format today's date for comparison
    String today = _dateFormat.format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gestion des Rendez-vous",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E90FF), Color(0xFFE6E6FA)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Text(
                    "Bienvenue, ${widget.user}",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _scheduleAppointment,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Prendre un rendez-vous",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF).withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rendez-vous du jour",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E90FF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getPatients(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins());
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // List to store all visits for today across all patients
                        List<Map<String, dynamic>> todayVisits = [];

                        // Iterate over all patients
                        for (var patientDoc in snapshot.data!.docs) {
                          var patientData = patientDoc.data() as Map<String, dynamic>;
                          var listeVisites = patientData['listeVisites'] as List<dynamic>? ?? [];

                          // Filter visits for today
                          for (var visit in listeVisites) {
                            if (visit['date'] == today) {
                              todayVisits.add({
                                'firstName': patientData['firstName'] ?? 'Prénom inconnu',
                                'lastName': patientData['lastName'] ?? 'Nom inconnu',
                                'visitDate': visit['date'],
                                'visitTime': visit['time'],
                              });
                            }
                          }
                        }

                        if (todayVisits.isEmpty) {
                          return Text(
                            "Aucun rendez-vous prévu pour aujourd'hui",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todayVisits.length,
                          itemBuilder: (context, index) {
                            var visit = todayVisits[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF1E90FF)),
                                title: Text(
                                  "${visit['firstName']} ${visit['lastName']}",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${visit['visitDate']} à ${visit['visitTime']}",
                                  style: GoogleFonts.poppins(),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.notifications, color: Colors.orange),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Rappel envoyé pour ${visit['firstName']} ${visit['lastName']} à ${visit['visitTime']}",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleAppointment() async {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E90FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E90FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      selectedDate = pickedDate;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E90FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E90FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      selectedTime = pickedTime;
    }

    if (selectedDate != null && selectedTime != null) {
      final scheduledDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (scheduledDateTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Veuillez choisir une date et heure futures."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final TimeOfDay confirmedTime = selectedTime;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirmer le rendez-vous", style: GoogleFonts.poppins()),
          content: Text(
            "Rendez-vous programmé pour :\n"
                "${_dateFormat.format(scheduledDateTime)} à "
                "${confirmedTime.format(context)}",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final faceStorage = FaceStorageFirebase();
                try {
                  await faceStorage.addVisit(widget.patientId, scheduledDateTime);
                  widget.onVisitAdded?.call(); // Notify MainPage to refresh
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Rendez-vous programmé pour le ${_dateFormat.format(scheduledDateTime)} à ${confirmedTime.format(context)}",
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Erreur lors de l'enregistrement du rendez-vous: $e",
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text("Confirmer", style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Aucun rendez-vous sélectionné.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}