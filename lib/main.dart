import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_storage.dart';
import 'face_detector.dart';
import 'camera_screen.dart';
import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Authentification Faciale", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.purpleAccent,
          centerTitle: true,
        ),
        body: MainPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatelessWidget {
  final FaceStorage storage = FaceStorage();
  final FaceDetectorService detector = FaceDetectorService();

  void _register(BuildContext context) async {
    String userName = ''; // À adapter si tu veux saisir le nom avant

    Navigator.push(context, MaterialPageRoute(builder: (context) => CameraScreen(
      isRegisterScreen: true,
      userName: userName,
      onPictureTaken: (XFile image, String userName) async {
        File file = File(image.path);
        List<double> faceData = await detector.extractFaceData(file);
        await storage.saveFaceData(userName, faceData);

        List<double>? savedFaceData = await storage.getFaceData(userName);
        print("Nom d'utilisateur: $userName");
        print("Données du visage: $savedFaceData");

        Navigator.pop(context);
      },
    )));
  }

  void _authenticate(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CameraScreen(
      isRegisterScreen: false,
      onPictureTaken: (XFile image, String userName) async {
        File file = File(image.path);
        List<double> faceData = await detector.extractFaceData(file);
        String? name = await storage.authenticateFace(faceData);
        Navigator.pop(context);

        if (name != null) {
          List<double>? savedFaceData = await storage.getFaceData(name);
          print("Nom d'utilisateur authentifié: $name");
          print("Données du visage: $faceData");

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(user: name)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Visage non reconnu ou données supprimées")));
        }
      },
    )));
  }

  void _deleteUserData(BuildContext context, String userName) async {
    await storage.deleteFaceData(userName);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Données supprimées pour $userName")));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _register(context),
            icon: Icon(Icons.app_registration, color: Colors.white, size: 30),
            label: Text("S'inscrire", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              minimumSize: Size(250, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 10,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _authenticate(context),
            icon: Icon(Icons.login, color: Colors.white, size: 30),
            label: Text("S'authentifier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: Size(250, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 10,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _deleteUserData(context, 'nour'),
            child: Text("Supprimer les données", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: Size(250, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 10,
            ),
          ),
        ],
      ),
    );
  }
}
