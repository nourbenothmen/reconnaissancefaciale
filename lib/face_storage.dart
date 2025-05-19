import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FaceStorageFirebase {
  static const double similarityThreshold = 0.98;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  Future<void> savePatientData(
      String firstName,
      String lastName,
      String phone,
      String birthDate,
      String email, // Nouveau paramètre pour l'email
      List<double> faceData,
      ) async {
    try {
      await _firestore.collection('patients').add({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'birthDate': birthDate,
        'email': email, // Ajout du champ email
        'faceData': faceData,
        'createdAt': FieldValue.serverTimestamp(),
        'listeVisites': [],
      });
    } catch (e) {
      print('Erreur sauvegarde Firestore: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPatientData(String patientId) async {
    final doc = await _firestore.collection('patients').doc(patientId).get();
    if (doc.exists) {
      return doc.data()!; // listeVisites already in {date, time} format
    } else {
      throw Exception('Patient not found');
    }
  }

  Future<void> addVisit(String patientId, DateTime dateTime, {bool reminderSent = false}) async {
    final date = _dateFormat.format(dateTime);
    final time = _timeFormat.format(dateTime);
    final visitData = {'date': date, 'time': time, 'reminderSent': reminderSent};

    final patientDoc = await _firestore.collection('patients').doc(patientId).get();
    if (patientDoc.exists) {
      final currentData = patientDoc.data() ?? {};
      var currentVisits = currentData['listeVisites'] ?? [];
      if (currentVisits is Map<String, dynamic>) {
        currentVisits = currentVisits.values.toList();
      } else if (currentVisits is! List) {
        currentVisits = [];
      }
      if (!currentVisits.any((v) => (v as Map<String, dynamic>)['date'] == date && (v as Map<String, dynamic>)['time'] == time)) {
        await _firestore.collection('patients').doc(patientId).update({
          'listeVisites': FieldValue.arrayUnion([visitData]),
        });
      }
    }
  }

  Future<void> updatePatientProfile(
      String patientId,
      String firstName,
      String lastName,
      DateTime birthDate,
      ) async {
    final patientRef = _firestore.collection('patients').doc(patientId);
    await patientRef.update({
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
    });
  }

  Future<void> addTask(String patientId, String taskDescription, DateTime taskDateTime) async {
    await _firestore.collection('tasks').add({
      'patientId': patientId,
      'description': taskDescription,
      'date': _dateFormat.format(taskDateTime),
      'time': _timeFormat.format(taskDateTime),
      'timestamp': Timestamp.fromDate(taskDateTime),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getTasks(String patientId) async {
    final querySnapshot = await _firestore
        .collection('tasks')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: false)
        .get();
    return querySnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> newTask) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'description': newTask['description'],
      'date': newTask['date'],
      'time': newTask['time'],
      'timestamp': newTask['timestamp'],
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Future<String?> authenticateFace(List<double> newFaceData) async {
    try {
      QuerySnapshot query = await _firestore.collection('patients').get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['faceData'] == null) continue;

        List<double> storedData = List<double>.from(data['faceData']);
        double similarity = _cosineSimilarity(storedData, newFaceData);

        if (similarity >= similarityThreshold) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      print("Erreur d'authentification: $e");
      return null;
    }
  }

  Future<void> deleteFaceData(String userName) async {
    final querySnapshot = await _firestore
        .collection('patients')
        .where('firstName', isEqualTo: userName)
        .get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
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