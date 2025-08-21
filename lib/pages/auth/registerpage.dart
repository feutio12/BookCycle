import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../composants/CustomButtom.dart';
import '../../composants/CustomTextfield.dart';
import 'loginpage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // pour créer l'utilisateur dans Firebase Auth
        UserCredential _ = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Erreur d'inscription";
        if (e.code == 'weak-password') {
          errorMessage = 'Mot de passe trop faible';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Email déjà utilisé';
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
                  const Text("Créer un compte", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  Image.asset("assets/images/BookCycle.png", height: 220),
                  const SizedBox(height: 30),

                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nom complet',
                    prefixIcon: Icons.person,
                    validator: (value) => value!.isEmpty ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 15),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'Email requis' :
                    !value.contains('@') ? 'Email invalide' : null,
                  ),
                  const SizedBox(height: 15),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Mot de passe',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Mot de passe requis' :
                    value.length < 6 ? '6 caractères minimum' : null,
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  CustomTextField(
                    controller: _confirmController,
                    labelText: 'Confirmer mot de passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) => value != _passwordController.text ?
                    'Les mots de passe ne correspondent pas' : null,
                  ),
                  const SizedBox(height: 25),

                  // Submit Button - REMPLACÉ PAR CustomButton
                  CustomButton(
                    onPressed: _submitForm,
                    text: "S'INSCRIRE",
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 15),

                  // Login Link
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const LoginPage())),
                    child: const Text(
                        "Déjà un compte ? Se connecter",
                      style: TextStyle(color: Colors.blue),
                    ) ,
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