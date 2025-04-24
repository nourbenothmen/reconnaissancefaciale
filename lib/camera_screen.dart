import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  final Function(XFile, String) onPictureTaken;
  final bool isRegisterScreen;
  final String? userName;

  const CameraScreen({Key? key, required this.onPictureTaken, this.isRegisterScreen = false, this.userName})
      : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextEditingController _textController = TextEditingController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("Aucune caméra disponible");
      }

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.high);
      await _controller.initialize();
      setState(() {}); // Mettre à jour l'UI après l'initialisation
    } catch (e) {
      print("Erreur lors de l'initialisation de la caméra: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!isProcessing && _controller.value.isInitialized) {
      setState(() {
        isProcessing = true;
      });

      try {
        await _initializeControllerFuture; // Vérifier que la caméra est prête
        XFile image = await _controller.takePicture();

        // Si nous sommes dans l'écran d'enregistrement, on vérifie que le nom est bien fourni
        if (widget.isRegisterScreen && _textController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veuillez entrer un nom d'utilisateur")));
          return;
        }

        String userName = _textController.text.trim();

        widget.onPictureTaken(image, userName);
        print("Nom d'utilisateur enregistré .......: $userName");

      } catch (e) {
        print("Erreur de capture : $e");
      } finally {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture de Visage"),
        backgroundColor: Colors.deepPurpleAccent,  // Utilisation d'une couleur moderne pour l'AppBar
        elevation: 5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (widget.isRegisterScreen)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "Entrez votre nom...",
                  hintStyle: TextStyle(color: Colors.grey[600]), // Couleur plus douce pour l'indication
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),  // Coins arrondis
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur de la caméra : ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton.icon(
              onPressed: _captureImage, // Capture l'image
              icon: Icon(Icons.camera_alt, color: Colors.white), // Icône caméra
              label: Text(
                isProcessing ? "Traitement..." : "Capturer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent, // Couleur de fond attrayante
                minimumSize: Size(250, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Coins arrondis pour les boutons
                ),
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
          if (isProcessing)
            CircularProgressIndicator(),  // Afficher un indicateur de traitement pendant la capture
        ],
      ),
    );
  }
}
