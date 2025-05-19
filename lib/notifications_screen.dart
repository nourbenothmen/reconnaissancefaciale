import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> matchedTasks;

  const NotificationsScreen({Key? key, required this.matchedTasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E90FF), Color(0xFFE6E6FA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: matchedTasks.isEmpty
              ? Center(
            child: Text(
              "Aucune notification pour le moment",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          )
              : ListView.builder(
            itemCount: matchedTasks.length,
            itemBuilder: (context, index) {
              final task = matchedTasks[index];
              return Card(
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.orange),
                  title: Text(
                    task['description'],
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "À ${task['date']} ${task['time']}",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}