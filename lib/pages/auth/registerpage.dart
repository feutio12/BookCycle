// registerpage.dart - Version améliorée avec une interface plus joyeuse
import 'package:bookcycle/pages/home/homepage.dart';
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
  static const String registerTitle = "Rejoignez la communauté BookCycle! 🌟";
  static const String registerSubtitle = "Créez votre compte en quelques secondes";
  static const String haveAccountText = "Déjà membre ? Connectez-vous";

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

      // Créer la structure utilisateur avec sous-collections
      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
        'stats': {
          'booksAdded': 0,
          'auctionsCreated': 0,
          'auctionsWon': 0,
          'rating': 5.0
        }
      };

      // Enregistrer les informations supplémentaires dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      // Créer les sous-collections pour l'utilisateur
      await _firestore.collection('users').doc(userCredential.user!.uid)
          .collection('books').doc('init').set({'created': FieldValue.serverTimestamp()});

      await _firestore.collection('users').doc(userCredential.user!.uid)
          .collection('auctions').doc('init').set({'created': FieldValue.serverTimestamp()});

      await _firestore.collection('users').doc(userCredential.user!.uid)
          .collection('chats').doc('init').delete();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
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
        errorMessage = 'Veuillez choisir un mot de passe plus fort';
        break;
      case 'email-already-in-use':
        errorMessage = 'Un compte existe déjà avec cet email';
        break;
      case 'invalid-email':
        errorMessage = 'Format d\'email invalide';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Cette opération n\'est pas autorisée';
        break;
      default:
        errorMessage = "Une erreur s'est produite lors de l'inscription";
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir votre nom';
    if (value.length < 2) return 'Le nom doit contenir au moins 2 caractères';
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir votre email';
    if (!value.contains('@')) return 'Format d\'email invalide';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir un mot de passe';
    if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';

    // Vérification de la force du mot de passe
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Incluez au moins une majuscule';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Incluez au moins un chiffre';
    }
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
    // Déterminer si on est sur un écran large
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: isLargeScreen
                  ? const BoxConstraints(maxWidth: 500)
                  : const BoxConstraints.expand(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration et titre
                        Column(
                          children: [
                            Image.asset(
                              "assets/images/BookCycle.png",
                              height: isLargeScreen ? 180 : 150,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              registerTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColorDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              registerSubtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Formulaire
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _nameController,
                                  labelText: 'Nom complet',
                                  hintext: "Votre nom et prénom",
                                  prefixIcon: Icons.person,
                                  validator: _nameValidator,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  hintext: "Votre adresse email",
                                  prefixIcon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _passwordController,
                                  labelText: 'Mot de passe',
                                  hintext: "Créez un mot de passe sécurisé",
                                  prefixIcon: Icons.lock,
                                  obscureText: obscurePassword,
                                  surfixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                      icon: obscurePassword
                                          ? Icon(Icons.visibility_off, color: Colors.blue.shade300)
                                          : Icon(Icons.visibility, color: Colors.blue.shade300)
                                  ),
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _confirmController,
                                  labelText: 'Confirmer le mot de passe',
                                  hintext: "Confirmez votre mot de passe",
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: obscureconfirmPassword,
                                  surfixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscureconfirmPassword = !obscureconfirmPassword;
                                        });
                                      },
                                      icon: obscureconfirmPassword
                                          ? Icon(Icons.visibility_off, color: Colors.blue.shade300)
                                          : Icon(Icons.visibility, color: Colors.blue.shade300)
                                  ),
                                  validator: _confirmPasswordValidator,
                                ),
                                const SizedBox(height: 24),

                                CustomButton(
                                  onPressed: _submitForm,
                                  text: 'Créer mon compte',
                                  isLoading: _isLoading,

                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Lien de connexion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Déjà inscrit ? ",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              ),
                              child: Text(
                                "Se connecter",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Conditions d'utilisation
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "En vous inscrivant, vous acceptez nos conditions d'utilisation et notre politique de confidentialité",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}