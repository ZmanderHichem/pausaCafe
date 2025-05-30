import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:saadoun/consommable.dart';
import 'package:saadoun/signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:saadoun/caisse.dart';
import 'package:saadoun/admin/admin_dashboard.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:saadoun/achat.dart'; // Import the Achat page

import 'package:saadoun/EndShift.dart';
import 'package:saadoun/background.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('Global error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Paus'a café",
      theme: ThemeData(
        primarySwatch: Colors.brown,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GoogleBottomBar(), // Updated to use GoogleBottomBar
      routes: {
        '/EndShift': (context) => const EndShift(),
        '/caisse': (context) => const Caisse(),
        '/consommable': (context) => const ConsommablePage(),
        '/achat': (context) => const Achat(), // Added route for Achat page
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}

// Add the GoogleBottomBar widget implementation
class GoogleBottomBar extends StatefulWidget {
  const GoogleBottomBar({Key? key}) : super(key: key);

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    EndShift(),
    Caisse(),
    ConsommablePage(),
    Achat(),
    AdminDashboard(),
  ];

  final List<Color> _appBarColors = [
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.blue,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final currentColor = _appBarColors[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            'End Shift',
            'Caisse',
            'Consommables',
            'Achat',
            'Admin'
          ][_selectedIndex],
        ),
        backgroundColor: currentColor,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedGradientBackground(
              primaryColor: currentColor,
              secondaryColor: Colors.white,
              accentColor: currentColor.withOpacity(0.9),
            ),
            Container(
              color: Colors.white.withOpacity(0.7),
              child: ClipRRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: currentColor,
        unselectedItemColor: const Color(0xff757575),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.timer),
            title: const Text("End Shift"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.attach_money),
            title: const Text("Caisse"),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.coffee),
            title: const Text("Consom"),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.shopping_cart),
            title: const Text("Achat"),
            selectedColor: Colors.blue,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.admin_panel_settings),
            title: const Text("Admin"),
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const SignIn())));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 238, 238, 238),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Add space between image and text
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Cafe Saadoun',
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 38, 149, 241),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                speed: const Duration(milliseconds: 80),
              ),
            ],
            displayFullTextOnTap: true,
            isRepeatingAnimation: false,

            //totalRepeatCount: 4,
            //pause: const Duration(milliseconds: 1000),
            //displayFullTextOnTap: true,
            //stopPauseOnTap: true,
          )
        ],
      ),
    );
  }
}
