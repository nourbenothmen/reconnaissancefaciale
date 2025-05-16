import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class CameraScreen extends StatefulWidget {
  final Function(XFile, Map<String, dynamic>) onPictureTaken;
  final bool isRegisterScreen;

  const CameraScreen({
    Key? key,
    required this.onPictureTaken,
    this.isRegisterScreen = false,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _birthDate;
  bool isProcessing = false;
  bool _showInstructions = true;
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;

  final Color dodgerBlue = const Color(0xFF1E90FF);

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showInstructions = false);
    });

    _lottieController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _particleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("Aucune caméra disponible");

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.high);
      await _controller.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      print("Erreur d'initialisation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur caméra: ${e.toString()}")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: dodgerBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: dodgerBlue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _lottieController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!isProcessing && _controller.value.isInitialized) {
      setState(() => isProcessing = true);
      _lottieController.forward();

      try {
        await _initializeControllerFuture;
        XFile image = await _controller.takePicture();

        if (widget.isRegisterScreen) {
          if (_firstNameController.text.isEmpty ||
              _lastNameController.text.isEmpty ||
              _phoneController.text.isEmpty ||
              _birthDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Veuillez remplir tous les champs", style: GoogleFonts.poppins()),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => isProcessing = false);
            _lottieController.reset();
            return;
          }
          Map<String, dynamic> patientData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'birthDate': _birthDate?.toIso8601String() ?? '',
          };

          await widget.onPictureTaken(image, patientData);
        } else {
          await widget.onPictureTaken(image, {});
        }

        _particleController.forward(from: 0);
      } catch (e) {
        print("Erreur de capture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}", style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            isProcessing = false;
            _lottieController.reset();
          });
        }
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(icon, color: dodgerBlue),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dodgerBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _birthDate != null ? dodgerBlue : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: dodgerBlue),
            const SizedBox(width: 16),
            Text(
              _birthDate != null
                  ? "Naissance: ${DateFormat('dd/MM/yyyy').format(_birthDate!)}"
                  : "Sélectionnez la date",
              style: GoogleFonts.poppins(
                color: _birthDate != null ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (!_controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/scanning.json', width: 100, height: 100, repeat: true),
            const SizedBox(height: 10),
            Text(
              "Initialisation caméra...",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.previewSize?.height ?? 0,
                  height: _controller.value.previewSize?.width ?? 0,
                  child: CameraPreview(_controller),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: dodgerBlue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    _showInstructions ? "Positionnez votre visage dans le cadre" : "Prêt à capturer",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: FaceOverlayPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isRegisterScreen ? "Enregistrement patient" : "Authentification",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [dodgerBlue, const Color(0xFF87CEFA)],
            ),
          ),
        ),
        elevation: 10,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [dodgerBlue, const Color(0xFFE6E6FA)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (widget.isRegisterScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Informations patient",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_firstNameController, "Prénom", Icons.person),
                        const SizedBox(height: 12),
                        _buildTextField(_lastNameController, "Nom", Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildTextField(_phoneController, "Téléphone", Icons.phone),
                        const SizedBox(height: 12),
                        _buildDatePicker(),
                      ],
                    ),
                  ),
                Expanded(
                  flex: widget.isRegisterScreen ? 2 : 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dodgerBlue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return _cameraPreviewWidget();
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 50),
                                const SizedBox(height: 20),
                                Text(
                                  'Erreur caméra',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _initializeCamera,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dodgerBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Réessayer",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset('assets/scanning.json', width: 100, height: 100, repeat: true),
                              const SizedBox(height: 10),
                              Text(
                                "Initialisation...",
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: AnimatedButton(
                    icon: Icons.camera_alt,
                    label: isProcessing ? "Traitement..." : "Capturer",
                    color: dodgerBlue,
                    onPressed: _captureImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const AnimatedButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => _controller.forward(),
      onExit: (PointerExitEvent event) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [widget.color, widget.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, color: Colors.white, size: 28),
                label: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E90FF).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radiusX = size.width * 0.3;
    final double radiusY = size.height * 0.4;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: radiusX * 2, height: radiusY * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) => false;
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E90FF).withOpacity(0.5);
    final random = Random();
    for (int i = 0; i < 20; i++) {
      final offset = Offset(
        size.width / 2 + random.nextDouble() * 100 * animationValue * (random.nextBool() ? 1 : -1),
        size.height / 2 + random.nextDouble() * 100 * animationValue * (random.nextBool() ? 1 : -1),
      );
      canvas.drawCircle(offset, 2 * animationValue, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}