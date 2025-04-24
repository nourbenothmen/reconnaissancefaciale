import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  Future<List<double>> extractFaceData(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) throw Exception("Aucun visage détecté");

    final Face face = faces.first;

    final List<FaceLandmarkType> desiredLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
    ];

    List<double> landmarkData = [];

    for (FaceLandmarkType type in desiredLandmarks) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        landmarkData.add(landmark.position.x.toDouble());
        landmarkData.add(landmark.position.y.toDouble());
      } else {
        landmarkData.add(0.0);
        landmarkData.add(0.0);
      }
    }

    return landmarkData;
  }
}
