import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math';


class CoordinatesPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;

  CoordinatesPainter({
    required this.faces,
    required this.imageSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final Paint pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (Face face in faces) {
      final Map<FaceContourType, FaceContour?> contours = {
        FaceContourType.face: face.contours[FaceContourType.face],
        FaceContourType.leftEye: face.contours[FaceContourType.leftEye],
        FaceContourType.rightEye: face.contours[FaceContourType.rightEye],
        FaceContourType.noseBridge: face.contours[FaceContourType.noseBridge],
        FaceContourType.noseBottom: face.contours[FaceContourType.noseBottom],
        FaceContourType.upperLipTop: face.contours[FaceContourType.upperLipTop],
        FaceContourType.upperLipBottom: face.contours[FaceContourType.upperLipBottom],
        FaceContourType.lowerLipTop: face.contours[FaceContourType.lowerLipTop],
        FaceContourType.lowerLipBottom: face.contours[FaceContourType.lowerLipBottom],
      };

      for (var entry in contours.entries) {
        final FaceContour? contour = entry.value;
        if (contour != null) {
          for (final Point<int> point in contour.points) {
            double dx = point.x * scaleX;
            double dy = point.y * scaleY;

            // Adapter les coordonnées pour la caméra frontale
            if (isFrontCamera) {
              dx = size.width - dx;
            }

            // Dessiner les points clés
            canvas.drawCircle(Offset(dx, dy), 3, pointPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CoordinatesPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
