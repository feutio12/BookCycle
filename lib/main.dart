import 'package:bookcycle/navigate.dart';
import 'package:bookcycle/pages/animation.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/pages/homepage.dart';
import 'package:bookcycle/utils/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    // Fallback en cas d'erreur Firebase
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erreur de connexion. Veuillez réessayer.'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookCycle',
      home: FutureBuilder<bool>(
        future: _checkFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashAnimation();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen('Erreur de chargement');
          }

          if (snapshot.data == true) {
            return const Navigate();
          }

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashAnimation();
              }

              if (userSnapshot.hasError) {
                return _buildErrorScreen('Erreur d\'authentification');
              }

              if (userSnapshot.hasData && AuthService.isUserLoggedIn()) {
                return const Homepage();
              } else {
                return const LoginPage();
              }
            },
          );
        },
      ),
    );
  }

  static Future<bool> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('first_launch') ?? true;
      if (isFirstLaunch) {
        await prefs.setBool('first_launch', false);
      }
      return isFirstLaunch;
    } catch (e) {
      // En cas d'erreur SharedPreferences, on considère que ce n'est pas le premier lancement
      return false;
    }
  }

  static Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                runApp(const MyApp());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}