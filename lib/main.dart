import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reconnfaciale/task_management_screen.dart';
import 'face_storage.dart';
import 'face_detector.dart';
import 'camera_screen.dart';
import 'home_page.dart';
import 'rdv_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

// Fonction de niveau supérieur pour gérer les notifications en arrière-plan
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse notificationResponse) async {
  print('Background notification received: ${notificationResponse.payload}');
  // Ajoutez ici toute logique spécifique pour le traitement en arrière-plan si nécessaire
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification tapped in main: ${response.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler, // Référence au gestionnaire
  );

  // Créer le canal de notification
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'task_channel_id',
    'Task Reminders',
    description: 'Notifications for task reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
  bool? isGranted = await Permission.scheduleExactAlarm.isGranted;
  print('SCHEDULE_EXACT_ALARM permission granted: $isGranted');

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  bool? notificationsGranted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.areNotificationsEnabled();
  print('POST_NOTIFICATIONS permission granted: $notificationsGranted');

  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
  print('Current timezone in main: ${tz.local.name}');

  print("✅ Firebase initialisé !");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.copyWith(
            headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            bodyMedium: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final FaceStorageFirebase storage = FaceStorageFirebase();
  final FaceDetectorService detector = FaceDetectorService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  int selectedIndex = 0;
  bool isAuthenticated = false;
  Map<String, dynamic>? patientData;
  String patientId = '';
  List<Map<String, dynamic>> matchedTasks = [];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    pages = [
      const HomePage(user: "Guest", patientData: null, patientId: ""),
      NotificationsScreen(matchedTasks: matchedTasks),
      Container(),
      SettingsScreen(
        patientData: patientData ?? {},
        patientId: patientId,
        onProfileUpdated: _refreshPatientData,
        onTasksMatched: _updateMatchedTasks,
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _register(BuildContext context) async {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
        isRegisterScreen: true,
        onPictureTaken: (XFile image, Map<String, dynamic> patientData) async {
          File file = File(image.path);
          List<double> faceData = await detector.extractFaceData(file);

          await storage.savePatientData(
            patientData['firstName'],
            patientData['lastName'],
            patientData['phone'],
            patientData['birthDate'],
            patientData['email'], // Ajout de l'email passé depuis CameraScreen
            faceData,
          );

          String userName = '${patientData['firstName']} ${patientData['lastName']}';
          Navigator.of(context).pop(userName);
        },
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    )).then((userName) {
      if (userName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check, color: Colors.white),
              Text("Enregistrement réussi pour $userName!"),
            ]),
            backgroundColor: Colors.white30,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _authenticate(BuildContext context) async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
          isRegisterScreen: false,
          onPictureTaken: (XFile image, _) async {
            try {
              File file = File(image.path);
              List<double> faceData = await detector.extractFaceData(file);
              String? newPatientId = await storage.authenticateFace(faceData);

              if (newPatientId != null) {
                try {
                  Map<String, dynamic> newPatientData = await storage.getPatientData(newPatientId);
                  setState(() {
                    isAuthenticated = true;
                    selectedIndex = 0;
                    patientData = newPatientData;
                    patientId = newPatientId;
                    pages[0] = HomePage(
                      user: '${newPatientData['firstName']} ${newPatientData['lastName']}',
                      patientData: newPatientData,
                      patientId: newPatientId,
                    );
                    pages[1] = NotificationsScreen(matchedTasks: matchedTasks);
                    pages[2] = RDVScreen(
                      user: '${newPatientData['firstName']} ${newPatientData['lastName']}',
                      patientData: newPatientData,
                      patientId: newPatientId,
                      onVisitAdded: _refreshPatientData,
                    );
                    pages[3] = SettingsScreen(
                      patientData: newPatientData,
                      patientId: newPatientId,
                      onProfileUpdated: _refreshPatientData,
                      onTasksMatched: _updateMatchedTasks,
                    );
                  });
                  Navigator.pop(context);
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur de chargement des données: ${e.toString()}"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Aucun patient trouvé"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Erreur technique: ${e.toString()}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _deleteUserData(BuildContext context, String userName) async {
    await storage.deleteFaceData(userName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 10),
            Text("Données supprimées pour $userName"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _refreshPatientData() async {
    if (patientId.isNotEmpty) {
      try {
        Map<String, dynamic> updatedPatientData = await storage.getPatientData(patientId);
        setState(() {
          patientData = updatedPatientData;
          pages[0] = HomePage(
            user: '${updatedPatientData['firstName']} ${updatedPatientData['lastName']}',
            patientData: updatedPatientData,
            patientId: patientId,
          );
          pages[1] = NotificationsScreen(matchedTasks: matchedTasks);
          pages[2] = RDVScreen(
            user: '${updatedPatientData['firstName']} ${updatedPatientData['lastName']}',
            patientData: updatedPatientData,
            patientId: patientId,
            onVisitAdded: _refreshPatientData,
          );
          pages[3] = SettingsScreen(
            patientData: updatedPatientData,
            patientId: patientId,
            onProfileUpdated: _refreshPatientData,
            onTasksMatched: _updateMatchedTasks,
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la mise à jour des données: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() {
    setState(() {
      isAuthenticated = false;
      selectedIndex = 0;
      patientData = null;
      patientId = '';
      matchedTasks = [];
      pages[0] = const HomePage(user: "Guest", patientData: null, patientId: "");
      pages[1] = NotificationsScreen(matchedTasks: matchedTasks);
      pages[2] = Container(color: Colors.grey[200], child: const Center(child: Text("RDV Screen")));
      pages[3] = SettingsScreen(
        patientData: {},
        patientId: '',
        onProfileUpdated: _refreshPatientData,
        onTasksMatched: _updateMatchedTasks,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Déconnexion réussie"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateMatchedTasks(List<Map<String, dynamic>> newMatchedTasks) {
    setState(() {
      matchedTasks = newMatchedTasks;
      pages[1] = NotificationsScreen(matchedTasks: matchedTasks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Portail Médical", style: Theme.of(context).textTheme.headlineMedium),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E90FF), Color(0xFF87CEFA)],
            ),
          ),
        ),
        centerTitle: true,
        elevation: 10,
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Déconnexion',
              onPressed: _logout,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E90FF), Color(0xFFE6E6FA)],
          ),
        ),
        child: isAuthenticated
            ? (selectedIndex == 0
            ? HomePage(
          user: '${patientData!['firstName']} ${patientData!['lastName']}',
          patientData: patientData,
          patientId: patientId,
          taskManagementScreen: TaskManagementScreen(
            patientData: patientData!,
            patientId: patientId,
            onTasksMatched: _updateMatchedTasks,
          ),
        )
            : pages[selectedIndex])
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/img.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _bounceAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1E90FF), Color(0xFF87CEFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "Bienvenue au Portail Médical",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Accédez à vos dossiers via reconnaissance faciale",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AnimatedButton(
                icon: Icons.person_add,
                label: "Nouveau Patient",
                color: const Color(0xFF1E90FF),
                onPressed: () => _register(context),
              ),
              const SizedBox(height: 20),
              AnimatedButton(
                icon: Icons.login,
                label: "Connexion Patient",
                color: const Color(0xFF1E90FF),
                onPressed: () => _authenticate(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isAuthenticated
          ? BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.black26,
        selectedItemColor: const Color(0xFF1E90FF),
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.folder),
            label: "Dossier",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.message),
            label: "notifications",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.calendar),
            label: "RDV",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.setting),
            label: "Paramètres",
          ),
        ],
      )
          : null,
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const AnimatedButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => _controller.forward(),
      onExit: (PointerExitEvent event) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.8), widget.color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, color: Colors.white, size: 30),
                label: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}