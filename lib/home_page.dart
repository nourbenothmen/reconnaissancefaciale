import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reconnfaciale/task_management_screen.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'face_storage.dart';

class HomePage extends StatefulWidget {
  final String user;
  final Map<String, dynamic>? patientData;
  final String patientId;
  final TaskManagementScreen? taskManagementScreen;

  const HomePage({
    Key? key,
    required this.user,
    this.patientData,
    required this.patientId,
    this.taskManagementScreen,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  late final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    print('HomePage patientData: ${widget.patientData}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _printPatientRecord() async {
    if (widget.patientData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucun patient sélectionné pour l'impression."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final birthDate = widget.patientData!['birthDate'] != null
        ? _dateFormat.format(DateTime.parse(widget.patientData!['birthDate']))
        : 'Non renseignée';
    var listeVisites = widget.patientData!['listeVisites'] ?? [];
    if (listeVisites is Map<String, dynamic>) {
      listeVisites = listeVisites.values.toList();
    } else if (listeVisites is! List) {
      listeVisites = [];
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Fiche Patient',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe853), color: PdfColors.blue),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '${widget.patientData!['firstName']} ${widget.patientData!['lastName']}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 10),
              _buildPdfDetailItem('Date de naissance', birthDate, pw.IconData(0xe551)),
              _buildPdfDetailItem('Téléphone', widget.patientData!['phone'] ?? 'Non renseigné', pw.IconData(0xe0cd)),
              if (listeVisites.isNotEmpty)
                ...listeVisites.map((visit) {
                  final String visitDateStr = visit['date'] as String? ?? '';
                  final String visitTimeStr = visit['time'] as String? ?? '';
                  if (visitDateStr.isEmpty || visitTimeStr.isEmpty) {
                    return _buildPdfDetailItem('Visite', 'Données manquantes', pw.IconData(0xe916));
                  }
                  try {
                    final DateTime visitDateTime = _dateFormat.parse(visitDateStr);
                    final List<String> timeParts = visitTimeStr.split(':');
                    final DateTime fullDateTime = DateTime(
                      visitDateTime.year,
                      visitDateTime.month,
                      visitDateTime.day,
                      int.parse(timeParts[0]),
                      int.parse(timeParts[1]),
                    );
                    return _buildPdfDetailItem(
                      'Visite',
                      '${_dateFormat.format(fullDateTime)} à ${_timeFormat.format(fullDateTime)}',
                      pw.IconData(0xe916),
                    );
                  } catch (e) {
                    return _buildPdfDetailItem('Visite', 'Date invalide', pw.IconData(0xe916));
                  }
                }),
              pw.SizedBox(height: 20),
              pw.Text(
                'Généré le : ${_dateFormat.format(DateTime.now())} ${_timeFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impression de la fiche patient terminée."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  pw.Widget _buildPdfDetailItem(String label, String value, pw.IconData icon) {
    return pw.Row(
      children: [
        pw.Icon(icon, color: PdfColors.blue, size: 20),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientCard() {
    if (widget.patientData == null) {
      return const Center(
        child: Text(
          "Aucune donnée patient disponible",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final birthDate = widget.patientData!['birthDate'] != null
        ? _dateFormat.format(DateTime.parse(widget.patientData!['birthDate']))
        : 'Non renseignée';
    var listeVisites = widget.patientData!['listeVisites'] ?? [];
    print('Before conversion - listeVisites type: ${listeVisites.runtimeType}');
    if (listeVisites is Map<String, dynamic>) {
      listeVisites = listeVisites.values.toList();
    } else if (listeVisites is! List) {
      listeVisites = [];
    }
    print('After conversion - listeVisites type: ${listeVisites.runtimeType}, content: $listeVisites');

    // Trier les visites par date et heure dans l'ordre croissant, seulement si ce n'est pas vide
    if (listeVisites is List && listeVisites.isNotEmpty) {
      print('Sorting listeVisites: $listeVisites');
      listeVisites.sort((a, b) {
        final dateA = _dateFormat.parse(a['date'] as String? ?? '01/01/2000');
        final timeA = a['time'] as String? ?? '00:00';
        final timePartsA = timeA.split(':');
        final fullDateTimeA = DateTime(
          dateA.year,
          dateA.month,
          dateA.day,
          timePartsA.isNotEmpty ? int.tryParse(timePartsA[0]) ?? 0 : 0,
          timePartsA.length > 1 ? int.tryParse(timePartsA[1]) ?? 0 : 0,
        );

        final dateB = _dateFormat.parse(b['date'] as String? ?? '01/01/2000');
        final timeB = b['time'] as String? ?? '00:00';
        final timePartsB = timeB.split(':');
        final fullDateTimeB = DateTime(
          dateB.year,
          dateB.month,
          dateB.day,
          timePartsB.isNotEmpty ? int.tryParse(timePartsB[0]) ?? 0 : 0,
          timePartsB.length > 1 ? int.tryParse(timePartsB[1]) ?? 0 : 0,
        );

        return fullDateTimeA.compareTo(fullDateTimeB);
      });
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E90FF).withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.patientData!['firstName']} ${widget.patientData!['lastName']}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),
            _buildDetailItem('Date de naissance', birthDate, Icons.cake),
            _buildDetailItem('Téléphone', widget.patientData!['phone'] ?? 'Non renseigné', Icons.phone),
            if (listeVisites.isNotEmpty)
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                          const SizedBox(width: 16),
                          Text(
                            'Liste des visites',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16.0,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Heure',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                        rows: listeVisites.map<DataRow>((visit) {
                          print('Visit in UI: $visit');
                          final String visitDateStr = visit['date'] as String? ?? '';
                          final String visitTimeStr = visit['time'] as String? ?? '';
                          if (visitDateStr.isEmpty || visitTimeStr.isEmpty) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'Données manquantes',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          try {
                            final DateTime visitDateTime = _dateFormat.parse(visitDateStr);
                            final List<String> timeParts = visitTimeStr.split(':');
                            final DateTime fullDateTime = DateTime(
                              visitDateTime.year,
                              visitDateTime.month,
                              visitDateTime.day,
                              int.parse(timeParts[0]),
                              int.parse(timeParts[1]),
                            );
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    _dateFormat.format(fullDateTime),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _timeFormat.format(fullDateTime),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } catch (e) {
                            print('Error parsing visit: $e');
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'Date invalide',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        }).toList() as List<DataRow>,
                      ),
                    ),
                  ]
              )
            else
              _buildDetailItem('Liste des visites', 'Aucune visite enregistrée', Icons.calendar_today),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil Patient",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer fiche patient',
            onPressed: _printPatientRecord,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Text(
                    "Bienvenue, ${widget.user}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildPatientCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}