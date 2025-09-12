import 'package:bookcycle/pages/auth/registerpage.dart';
import 'package:bookcycle/composants/CustomTextfield.dart';
import 'package:bookcycle/pages/home/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../composants/CustomButtom.dart';
import '../admin/admin_dashboard.dart';

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
  static const String loginTitle = 'Bienvenue sur BookCycle! 📚';
  static const String loginSubtitle = 'Connectez-vous pour continuer';

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
          MaterialPageRoute(builder: (_) => AdminDashboard()),
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
        errorMessage = 'Aucun compte trouvé avec cet email';
        break;
      case 'wrong-password':
        errorMessage = 'Mot de passe incorrect';
        break;
      case 'invalid-email':
        errorMessage = 'Format d\'email invalide';
        break;
      case 'user-disabled':
        errorMessage = 'Ce compte a été désactivé';
        break;
      default:
        errorMessage = 'Une erreur s\'est produite lors de la connexion';
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

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir votre email';
    if (!value.contains('@')) return 'Email invalide';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir votre mot de passe';
    if (value.length < 6) return '6 caractères minimum requis';
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
              Colors.blue.shade50, Colors.white, Colors.green.shade50,
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
                              height: isLargeScreen ? 200 : 180,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              loginTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColorDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loginSubtitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                                  hintext: "Votre mot de passe",
                                  prefixIcon: Icons.lock,
                                  obscureText: obscurePassword,
                                  surfixIcon: IconButton(
                                      onPressed: () { setState(() { obscurePassword = !obscurePassword;});},
                                      icon: obscurePassword
                                          ? Icon(Icons.visibility_off, color: Colors.blue.shade300)
                                          : Icon(Icons.visibility, color: Colors.blue.shade300)
                                  ),
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () { },
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                CustomButton(
                                  onPressed: _submitForm,
                                  text: 'Se connecter',
                                  isLoading: _isLoading,

                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Lien d'inscription
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Nouveau sur BookCycle ? ",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()),
                              ),
                              child: Text(
                                "S'inscrire",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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