import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'face_storage.dart';
import 'face_detector.dart';
import 'camera_screen.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("✅ Firebase initialisé !");
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.copyWith(
            headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            bodyMedium: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FaceStorage storage = FaceStorage();
  final FaceDetectorService detector = FaceDetectorService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _register(BuildContext context) async {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
        isRegisterScreen: true, // Mode enregistrement
        onPictureTaken: (XFile image, String userName) async {
          // 1. Convertit l'image en File
          File file = File(image.path);

          // 2. Extrait les caractéristiques du visage
          List<double> faceData = await detector.extractFaceData(file);

          // 3. Sauvegarde dans SharedPreferences/Firestore
          await storage.saveFaceData(userName, faceData);

          // 4. Vérification (debug)
          List<double>? savedFaceData = await storage.getFaceData(userName);
          print("Données enregistrées : $savedFaceData");

          // 5. Retour à l'écran précédent
          Navigator.of(context).pop(userName);
        },
      ),
      // Animation de transition (glissement)
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Départ à droite
        const end = Offset.zero;         // Arrivée au centre
        const curve = Curves.easeInOut;  // Lissage du mouvement
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    )).then((userName) {
      // Feedback après enregistrement
      if (userName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                Icon(Icons.check, color: Colors.white),
                Text("Enregistrement réussi pour $userName!"),
              ]),
              backgroundColor: Colors.white30,
              duration: Duration(seconds: 2),
            )
        );
      }
    });
  }
  void _authenticate(BuildContext context) async {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
        isRegisterScreen: false, // Mode authentification
        onPictureTaken: (XFile image, String userName) async {
          File file = File(image.path);

          // 1. Extrait les caractéristiques du visage
          List<double> faceData = await detector.extractFaceData(file);

          // 2. Compare avec la base de données
          String? name = await storage.authenticateFace(faceData);

          if (name != null) {
            // 3. Succès -> Redirection vers HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(user: name)),
            );
          } else {
            // 4. Échec -> Retour + message d'erreur
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  Icon(Icons.error, color: Colors.white),
                  Text("Visage non reconnu"),
                ]),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      ),
      // Même animation que _register
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
  }

  void _deleteUserData(BuildContext context, String userName) async {
    await storage.deleteFaceData(userName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 10),
            Text("Données supprimées pour $userName"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Authentification Faciale", style: Theme.of(context).textTheme.headlineMedium),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Colors.cyan],
            ),
          ),
        ),
        centerTitle: true,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.pinkAccent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Lottie.asset('assets/scanning.json', width: 150, height: 150, repeat: true),
                ),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _bounceAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.cyan, Colors.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "Bienvenue !",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Authentifiez-vous avec votre visage",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              AnimatedButton(
                icon: Icons.app_registration,
                label: "S'inscrire",
                color: Colors.cyan,
                onPressed: () => _register(context),
              ),
              const SizedBox(height: 40),
              AnimatedButton(
                icon: Icons.login,
                label: "S'authentifier",
                color: Colors.pinkAccent,
                onPressed: () => _authenticate(context),
              ),
              const SizedBox(height: 20),
              // AnimatedButton(
              //   icon: Icons.delete,
              //   label: "Supprimer les données",
              //   color: Colors.redAccent,
              //   onPressed: () => _deleteUserData(context, 'nour'),
              // ),
            ],
          ),
        ),
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
    Key? key,
  }) : super(key: key);

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.8), widget.color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, color: Colors.white, size: 30),
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
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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