import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart'; // Nécessaire pour accéder à MyApp

class HomePage extends StatelessWidget {
  final String user;

  HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDE7F6),
      appBar: AppBar(
        title: Text("Accueil"),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
        centerTitle: true,
        leading: Icon(Icons.home),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.solidSmileBeam, size: 70, color: Colors.deepPurple),
              SizedBox(height: 20),
              Text(
                "Salut, $user ! 👋",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple[700],
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Bienvenue sur l'application d'authentification faciale.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => MyApp()),
                        (Route<dynamic> route) => false,
                  );
                },
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Déconnexion", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
