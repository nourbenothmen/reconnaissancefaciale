import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;

  FaceDetectorPainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (Face face in faces) {
      for (final contour in face.contours.values) {
        if (contour != null) {
          for (final point in contour.points) {
            double dx = point.x * scaleX;
            double dy = point.y * scaleY;
            canvas.drawCircle(Offset(dx, dy), 3, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
