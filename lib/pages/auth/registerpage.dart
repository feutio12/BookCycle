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

  // Constantes
  static const String adminEmail = 'admin@gmail.com';
  static const String registerTitle = "S'INSCRIRE";
  static const String haveAccountText = "Déjà un compte ? Se connecter";
  static const String pageTitle = "Créer un compte";

  bool obscurePassword = true;
  bool obscureconfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Déterminer le rôle de l'utilisateur
      final role = email == adminEmail ? 'admin' : 'user';

      // Enregistrer les informations supplémentaires dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
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
      case 'weak-password':
        errorMessage = 'Mot de passe trop faible';
        break;
      case 'email-already-in-use':
        errorMessage = 'Email déjà utilisé';
        break;
      case 'invalid-email':
        errorMessage = 'Email invalide';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Opération non autorisée';
        break;
      default:
        errorMessage = "Erreur d'inscription";
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) return 'Nom requis';
    if (value.length < 2) return 'Nom trop court';
    return null;
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

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
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
                      pageTitle,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold
                      )
                  ),
                  Image.asset(
                      "assets/images/BookCycle.png",
                      height: 220
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nom complet',
                    hintext: "Entrez votre nom complet",
                    prefixIcon: Icons.person,
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: 15),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintext: "Entrez votre email",
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 15),

                  // Password Field
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
                        icon: obscurePassword ? Icon(Icons.visibility_off, color: Colors.blue.shade300,) : Icon(Icons.visibility,color: Colors.blue.shade300,)
                    ),
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  CustomTextField(
                    controller: _confirmController,
                    labelText: 'Confirmer mot de passe',
                    hintext: "Confirmez votre mot de passe",
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscureconfirmPassword,
                    surfixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureconfirmPassword = !obscureconfirmPassword;
                          });
                        },
                        icon: obscureconfirmPassword ? Icon(Icons.visibility_off, color: Colors.blue.shade300,) : Icon(Icons.visibility,color: Colors.blue.shade300,)
                    ),
                    validator: _confirmPasswordValidator,
                  ),
                  const SizedBox(height: 25),

                  // Submit Button
                  CustomButton(
                    onPressed: _submitForm,
                    text: registerTitle,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 15),

                  // Login Link
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage())
                    ),
                    child: const Text(
                      haveAccountText,
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