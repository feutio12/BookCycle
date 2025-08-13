import 'package:bookcycle/pages/auth/registerpage.dart';
import 'package:bookcycle/composants/CustomTextfield.dart';
import 'package:bookcycle/pages/homepage.dart';
import 'package:bookcycle/pages/pages%20rincipales/Acceuilpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Récupérer les infos supplémentaires depuis Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Homepage(
              userData: userDoc.data() as Map<String, dynamic>? ?? {},
            )),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Erreur de connexion';
        if (e.code == 'user-not-found') {
          errorMessage = 'Utilisateur non trouvé';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Mot de passe incorrect';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Bienvenue",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Image.asset("assets/images/sss.jpg", height: 120),
                  const SizedBox(height: 30),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email requis';
                      if (!value.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Mot de passe',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Mot de passe requis';
                      if (value.length < 6) return '6 caractères minimum';
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('CONNEXION'),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Register Link
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text("Pas de compte ? S'inscrire"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}