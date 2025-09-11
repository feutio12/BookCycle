import 'package:bookcycle/pages/auth/registerpage.dart';
import 'package:bookcycle/composants/CustomTextfield.dart';
import 'package:bookcycle/pages/home/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../composants/CustomButtom.dart';
import '../admin/dashboard_screen.dart';

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

  // Constantes pour éviter les répétitions de texte
  static const String adminEmail = 'admin@gmail.com';
  static const String loginTitle = 'CONNEXION';
  static const String noAccountText = "Pas de compte ? S'inscrire";

  bool obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

// Vérifier si c'est l'administrateur
      if (email == adminEmail) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
        return;
      }

      // Récupérer les infos supplémentaires depuis Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Homepage(
          userData: userDoc.data() as Map<String, dynamic>? ?? {},
        )),
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;

    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'Utilisateur non trouvé';
        break;
      case 'wrong-password':
        errorMessage = 'Mot de passe incorrect';
        break;
      case 'invalid-email':
        errorMessage = 'Email invalide';
        break;
      case 'user-disabled':
        errorMessage = 'Compte désactivé';
        break;
      default:
        errorMessage = 'Erreur de connexion';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    if (!value.contains('@')) return 'Email invalide';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return '6 caractères minimum';
    return null;
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
                  Text(
                    loginTitle,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 40),
                  Image.asset(
                      "assets/images/BookCycle.png",
                      height: 250
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintext: "Entrez votre email",
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Mot de passe',
                    hintext: "Entrez votre mot de passe",
                    prefixIcon: Icons.lock,
                    obscureText: obscurePassword,
                    surfixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: obscurePassword ?  Icon(Icons.visibility_off, color: Colors.blue.shade300,) : Icon(Icons.visibility,color: Colors.blue.shade300,)
                    ),
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 25),

                  CustomButton(
                    onPressed: _submitForm,
                    text: loginTitle,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      noAccountText,
                      style: TextStyle(color: Colors.blue),
                    ),
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