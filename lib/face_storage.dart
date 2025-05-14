import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class FaceStorage {
  // Seuil minimal de similarité pour authentification
  static const double similarityThreshold = 0.98;
  // Sauvegarde les données faciales
  Future<void> saveFaceData(String name, List<double> faceData) async {
    if (name.isEmpty || faceData.isEmpty) {
      print("Erreur : Nom d'utilisateur ou données vides !");
      return; // Validation : on n'enregistre pas des données vides
    }
    final prefs = await SharedPreferences.getInstance();
    // Sauvegarde les données encodées en JSON
    await prefs.setString(name, jsonEncode(faceData));
    print("✅ Données sauvegardées pour $name: ${jsonEncode(faceData)}");
  }


  // Récupère les données faciales
  Future<List<double>?> getFaceData(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    String? faceDataStr = prefs.getString(userName);

    if (faceDataStr != null) {
      try {
        List<double> faceData = List<double>.from(jsonDecode(faceDataStr));
        print("📥 Données récupérées pour $userName: $faceData");
        return faceData;
      } catch (e) {
        print("❌ Erreur de décodage des données de $userName: $e");
      }
    }
    return null;
  }

  // Supprime les données faciales
  Future<void> deleteFaceData(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userName);
    print('🗑️ Données supprimées pour $userName');
  }

  Future<String?> authenticateFace(List<double> newFaceData) async {
    final prefs = await SharedPreferences.getInstance();

    // Boucle sur tous les utilisateurs enregistrés
    for (String key in prefs.getKeys()) {
      try {
        // Lecture et décodage des données
        List<dynamic> storedRaw = jsonDecode(prefs.getString(key)!);
        List<double> storedFaceData = List<double>.from(storedRaw.map((e) => e.toDouble()));

        // Si les tailles de vecteurs sont différentes, on ignore
        if (storedFaceData.length != newFaceData.length) {
          print("⚠️ Vecteurs de tailles différentes pour $key. Ignoré.");
          continue;
        }

        // Calcul de la similarité
        double similarity = cosineSimilarity(storedFaceData, newFaceData);
        print("🔍 Similarité avec $key: $similarity");

        // Authentification si seuil atteint
        if (similarity >= similarityThreshold) {
          print("✅ Visage authentifié pour $key");
          return key; // Utilisateur reconnu
        }
      } catch (e) {
        print("⚠️ Erreur lors de l'analyse des données pour $key: $e");
      }
    }

    print("❌ Aucun visage correspondant trouvé");
    return null; // Aucun utilisateur correspondant
  }
  double cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return 0.0; // Vérifie que les vecteurs ont la même taille

    double dotProduct = 0.0, norm1 = 0.0, norm2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i]; // Produit scalaire
      norm1 += vec1[i] * vec1[i]; // Norme du premier vecteur
      norm2 += vec2[i] * vec2[i]; // Norme du second vecteur
    }

    if (norm1 == 0 || norm2 == 0) return 0.0; // Évite division par 0

    return dotProduct / (sqrt(norm1) * sqrt(norm2)); // Formule de la similarité cosinus
  }
}
