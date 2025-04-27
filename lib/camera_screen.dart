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
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _showInstructions = false);
    });
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
      if (mounted) setState(() {});
    } catch (e) {
      print("Erreur lors de l'initialisation de la caméra: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose().then((_) {
      print("Camera controller fully disposed");
    }).catchError((e) {
      print("Error disposing camera: $e");
    });
    _textController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!isProcessing && _controller.value.isInitialized) {
      setState(() => isProcessing = true);

      try {
        await _initializeControllerFuture;
        XFile image = await _controller.takePicture();

        if (widget.isRegisterScreen && _textController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Veuillez entrer un nom d'utilisateur"),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        String userName = widget.isRegisterScreen ? _textController.text.trim() : '';
        await widget.onPictureTaken(image, userName);

      } catch (e) {
        print("Erreur de capture : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la capture: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => isProcessing = false);
      }
    }
  }

  Widget _cameraPreviewWidget() {
    if (!_controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
            ),
            SizedBox(height: 20),
            Text(
              "Initialisation de la caméra...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
          child: CameraPreview(_controller),
        ),
        if (_showInstructions)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face_retouching_natural, size: 50, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      widget.isRegisterScreen
                          ? "Positionnez votre visage dans le cadre"
                          : "Regardez droit vers la caméra",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Assurez-vous d'être dans un endroit bien éclairé",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isRegisterScreen ? "Enregistrement facial" : "Authentification",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isRegisterScreen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Votre nom d'utilisateur...",
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    prefixIcon: Icon(Icons.person, color: Colors.deepPurpleAccent),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
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
                              Icon(Icons.error, color: Colors.red, size: 50),
                              SizedBox(height: 20),
                              Text(
                                'Erreur de la caméra',
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _initializeCamera,
                                child: Text("Réessayer"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: ElevatedButton(
                onPressed: _captureImage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isProcessing) Icon(Icons.camera_alt, size: 24),
                      if (!isProcessing) SizedBox(width: 10),
                      Text(
                        isProcessing ? "Traitement en cours..." : "Capturer",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.deepPurple.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}