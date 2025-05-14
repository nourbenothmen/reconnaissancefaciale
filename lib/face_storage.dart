import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FaceStorageFirebase {
  static const double similarityThreshold = 0.98;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePatientData(
      String firstName,
      String lastName,
      String phone,
      String birthDate,
      List<double> faceData,
      ) async {
    try {
      await _firestore.collection('patients').add({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'birthDate': birthDate,
        'faceData': faceData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur sauvegarde Firestore: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPatientData(String patientId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (!doc.exists) {
        // Retourne une map vide plutôt que de throw une exception
        return {};
      }

      return doc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print("Erreur Firestore: $e");
      return {};
    }
  }

  Future<String?> authenticateFace(List<double> newFaceData) async {
    try {
      QuerySnapshot query = await _firestore.collection('patients').get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Vérifie que le document contient bien faceData
        if (data['faceData'] == null) continue;

        List<double> storedData = List<double>.from(data['faceData']);
        double similarity = _cosineSimilarity(storedData, newFaceData);

        if (similarity >= similarityThreshold) {
          return doc.id; // Retourne l'ID du document trouvé
        }
      }
      return null;
    } catch (e) {
      print("Erreur d'authentification: $e");
      return null;
    }
  }

  Future<void> deleteFaceData(String userName) async {
    await _firestore.collection('patients').doc(userName).delete();
  }


  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return 0.0;

    double dotProduct = 0.0, norm1 = 0.0, norm2 = 0.0;
    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }
    return (norm1 == 0 || norm2 == 0)
        ? 0.0
        : dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}