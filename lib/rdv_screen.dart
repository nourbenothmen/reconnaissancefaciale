import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
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
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Stream<QuerySnapshot> _getPatients() {
    return _firestore.collection('patients').snapshots();
  }

  String _getVisitStatus(String visitDate, String visitTime) {
    final now = DateTime.now();
    final today = _dateFormat.format(now);

    if (visitDate != today) {
      return "N/A";
    }

    final visitDateTime = DateTime.parse(
        "${visitDate.split('/')[2]}-${visitDate.split('/')[1]}-${visitDate.split('/')[0]} "
            "$visitTime:00"
    );

    final difference = visitDateTime.difference(now).inMinutes;

    if (difference > 0) {
      return "Pas encore";
    } else if (difference == 0) {
      return "En consultation";
    } else {
      return "Terminé";
    }
  }

  Future<void> _sendReminderEmail(String patientId, String visitDate, String visitTime) async {
    try {
      final patientDoc = await _firestore.collection('patients').doc(patientId).get();
      if (!patientDoc.exists || !patientDoc.data()!.containsKey('email')) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Aucun email trouvé pour ce patient.")),
        );
        return;
      }

      final patientData = patientDoc.data()! as Map<String, dynamic>;
      final email = patientData['email'] as String?;
      final firstName = patientData['firstName'] ?? 'Patient';
      final lastName = patientData['lastName'] ?? '';

      if (email == null) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Aucun email disponible pour ce patient.")),
        );
        return;
      }

      final smtpServer = gmail('nourelhoudabenothmen0@gmail.com', 'kknc ndzk uwnx qdsw');

      final message = Message()
        ..from = Address('nourelhoudabenothmen0@gmail.com', 'Votre Clinique')
        ..recipients.add(email)
        ..subject = 'Rappel de votre rendez-vous'
        ..html = """
          <h1>Rappel de votre rendez-vous</h1>
          <p>Bonjour $firstName $lastName,</p>
          <p>Vous avez un rendez-vous prévu le $visitDate à $visitTime.</p>
          <p>Merci de confirmer votre présence ou de nous contacter en cas d'annulation.</p>
          <p>Cordialement,<br>Votre Clinique</p>
        """;

      await send(message, smtpServer);

      var listeVisites = patientData['listeVisites'] ?? [];
      if (listeVisites is Map<String, dynamic>) {
        listeVisites = listeVisites.values.toList();
      }
      final visitIndex = listeVisites.indexWhere((v) => (v as Map<String, dynamic>)['date'] == visitDate && (v as Map<String, dynamic>)['time'] == visitTime);
      if (visitIndex != -1) {
        // Mettre à jour la liste localement
        listeVisites[visitIndex]['reminderSent'] = true;
        // Réécrire toute la liste dans Firestore
        await _firestore.collection('patients').doc(patientId).update({
          'listeVisites': listeVisites,
        });
      }

      _scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Rappel envoyé à $email")),
      );
    } catch (e) {
      print("Erreur lors de l'envoi de l'email: $e");
      _scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

                        List<Map<String, dynamic>> todayVisits = [];

                        for (var patientDoc in snapshot.data!.docs) {
                          var patientData = patientDoc.data() as Map<String, dynamic>;
                          var listeVisites = patientData['listeVisites'] ?? [];
                          if (listeVisites is Map<String, dynamic>) {
                            listeVisites = listeVisites.values.toList();
                          }
                          if (listeVisites is List) {
                            for (var visit in listeVisites) {
                              if (visit is Map<String, dynamic> && visit['date'] == today) {
                                todayVisits.add({
                                  'firstName': patientData['firstName'] ?? 'Prénom inconnu',
                                  'lastName': patientData['lastName'] ?? 'Nom inconnu',
                                  'visitDate': visit['date'] as String,
                                  'visitTime': visit['time'] as String,
                                  'patientId': patientDoc.id,
                                  'reminderSent': visit['reminderSent'] ?? false,
                                });
                              }
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
                            String status = _getVisitStatus(visit['visitDate'], visit['visitTime']);
                            Color statusColor = status == "Terminé"
                                ? Colors.green
                                : status == "En consultation"
                                ? Colors.orange
                                : Colors.blue;
                            bool reminderSent = visit['reminderSent'] ?? false;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF1E90FF)),
                                title: Text(
                                  "${visit['firstName']} ${visit['lastName']}",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${visit['visitDate']} à ${visit['visitTime']}",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    Text(
                                      "État : $status",
                                      style: GoogleFonts.poppins(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Rappel : ${reminderSent ? 'Envoyé' : 'Non envoyé'}",
                                      style: GoogleFonts.poppins(
                                        color: reminderSent ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    reminderSent
                                        ? Icons.check_circle
                                        : Icons.notifications,
                                    color: reminderSent ? Colors.green : Colors.orange,
                                  ),
                                  onPressed: reminderSent
                                      ? null
                                      : () async {
                                    await _sendReminderEmail(
                                      visit['patientId'],
                                      visit['visitDate'],
                                      visit['visitTime'],
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
          _scaffoldMessenger.showSnackBar(
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
                  await faceStorage.addVisit(widget.patientId, scheduledDateTime, reminderSent: false);
                  widget.onVisitAdded?.call();
                  if (mounted) {
                    _scaffoldMessenger.showSnackBar(
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
                    _scaffoldMessenger.showSnackBar(
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
        _scaffoldMessenger.showSnackBar(
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