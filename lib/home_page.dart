import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  final String user;
  final Map<String, dynamic>? patientData;

  const HomePage({
    Key? key,
    required this.user,
    this.patientData,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _starController;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _printPatientRecord() async {
    if (widget.patientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun patient sélectionné pour l'impression."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Format birth date
    final birthDate = widget.patientData!['birthDate'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.patientData!['birthDate']))
        : 'Non renseignée';
    final lastVisit = widget.patientData!['lastVisit'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.patientData!['lastVisit']))
        : 'Première visite';

    // Create a PDF document
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
                  color: PdfColors.indigo,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe853), color: PdfColors.cyan), // Person icon
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
              _buildPdfDetailItem('Date de naissance', birthDate, pw.IconData(0xe551)), // Cake icon
              _buildPdfDetailItem('Téléphone', widget.patientData!['phone'] ?? 'Non renseigné', pw.IconData(0xe0cd)), // Phone icon
              _buildPdfDetailItem('Dernière visite', lastVisit, pw.IconData(0xe916)), // Calendar icon
              pw.SizedBox(height: 20),
              pw.Text(
                'Généré le : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
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

    // Print the PDF
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impression de la fiche patient terminée."),
        backgroundColor: Colors.green,
      ),
    );
  }

  pw.Widget _buildPdfDetailItem(String label, String value, pw.IconData icon) {
    return pw.Row(
      children: [
        pw.Icon(icon, color: PdfColors.cyan, size: 20),
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

  void _scheduleAppointment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Prendre un RDV"),
        content: Text("Voulez-vous prendre un rendez-vous pour ce patient ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Rendez-vous programmé"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    if (widget.patientData == null) {
      return Container();
    }

    final birthDate = widget.patientData!['birthDate'] != null
        ? DateFormat('dd/MM/yyyy').format(
        DateTime.parse(widget.patientData!['birthDate']))
        : 'Non renseignée';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.indigo.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.cyan),
              title: Text(
                '${widget.patientData!['firstName']} ${widget.patientData!['lastName']}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Dossier patient',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            const Divider(color: Colors.white54),
            _buildDetailItem('Date de naissance', birthDate, Icons.cake),
            _buildDetailItem('Téléphone', widget.patientData!['phone'], Icons.phone),
            _buildDetailItem('Dernière visite',
                widget.patientData!['lastVisit'] ?? 'Première visite',
                Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
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
              colors: [Colors.indigo, Colors.cyan],
            ),
          ),
        ),
        elevation: 10,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer fiche patient',
            onPressed: _printPatientRecord,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Prendre RDV',
            onPressed: _scheduleAppointment,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.pinkAccent],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/scanning.json',
                      width: 150,
                      height: 150,
                      repeat: false,
                    ),
                    Text(
                      "Bienvenue, ${widget.user}",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_showDetails) _buildPatientCard(),
                    if (!_showDetails)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDetails = true;
                            });
                          },
                          icon: const Icon(Icons.visibility, color: Colors.white),
                          label: Text(
                            "Afficher les détails",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MyApp()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        "Déconnexion",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}