import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/screen_manage.dart';

class Registerpage extends StatelessWidget {
  const Registerpage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const Text(
                    "Créer un compte",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: screenHeight * 0.01),
                  SizedBox(
                    height: screenHeight * 0.2,
                    child: Image.asset(
                      "assets/images/sss.jpg",
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
          
              const Text(
                "Remplissez les informations pour créer votre compte",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
          
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  labelStyle: const TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.blue),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
          
              // Champ mot de passe
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: const TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
          
              // Confirmation mot de passe
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  labelStyle: const TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
          
              // Bouton d'inscription
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScreenManage(),
                    ),
                  );
                },
                child: const Text("S'INSCRIRE"),
              ),
              SizedBox(height: screenHeight * 0.02),
          
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Loginpage(),
                    ),
                  );
                },
                child: const Text(
                  "Déjà un compte ? Se connecter",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}