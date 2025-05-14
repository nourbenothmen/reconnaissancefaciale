// Importation des bibliothèques nécessaires
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// Service de détection de visage
class FaceDetectorService {
  // Création d'une instance de FaceDetector avec options activées
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,   // Active la détection
      // des contours du visage
      enableLandmarks: true,  // Active la détection
      // des points de repère (landmarks)
    ),
  );

  // Méthode pour extraire les données des landmarks du visage
  Future<List<double>> extractFaceData(File imageFile) async {
    // Conversion du fichier image en un InputImage compatible avec ML Kit
    final InputImage inputImage = InputImage.fromFile(imageFile);

    // Traitement de l'image pour détecter les visages
    final List<Face> faces = await faceDetector.processImage(inputImage);

    // Si aucun visage détecté, on lève une exception
    if (faces.isEmpty) throw Exception("Aucun visage détecté");

    // On prend uniquement le premier visage détecté
    final Face face = faces.first;

    // Liste des types de landmarks que l'on souhaite extraire
    final List<FaceLandmarkType> desiredLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
    ];

    // Liste pour stocker les coordonnées x, y des landmarks
    List<double> landmarkData = [];

    // Pour chaque type de landmark, on récupère sa position (si disponible)
    for (FaceLandmarkType type in desiredLandmarks) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        // Si le landmark est détecté, on ajoute ses coordonnées x et y
        landmarkData.add(landmark.position.x.toDouble());
        landmarkData.add(landmark.position.y.toDouble());
      } else {
        // Si le landmark n'est pas détecté, on ajoute (0.0, 0.0) par défaut
        landmarkData.add(0.0);
        landmarkData.add(0.0);
      }
    }

    // Retourne la liste de coordonnées du visage
    return landmarkData;
  }
}
