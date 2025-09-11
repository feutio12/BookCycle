// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isChecked = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Vérifier si l'utilisateur est déjà connecté
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "Aucun utilisateur trouvé avec cet email";
          break;
        case 'wrong-password':
          message = "Mot de passe incorrect";
          break;
        case 'invalid-email':
          message = "Email invalide";
          break;
        default:
          message = "Une erreur s'est produite. Veuillez réessayer";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion"),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Card(
              color: secondaryColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    FlutterLogo(size: 80), // Remplacez par votre logo
                    SizedBox(height: 24),
                    Text(
                      "BookCycle Admin",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Connectez-vous à votre compte",
                      style: TextStyle(
                        color: Palette.textSecondary,
                      ),
                    ),
                    SizedBox(height: 32),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Email",
              labelStyle: TextStyle(color: Palette.textSecondary),
              hintText: "Entrez votre email",
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.email, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Mot de passe",
              labelStyle: TextStyle(color: Palette.textSecondary),
              hintText: "Entrez votre mot de passe",
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.lock, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isChecked,
                onChanged: (value) => setState(() => _isChecked = value!),
                fillColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return primaryColor;
                    }
                    return Colors.white24;
                  },
                ),
              ),
              Text("Se souvenir de moi", style: TextStyle(color: Colors.white70)),
              Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Implémenter la réinitialisation du mot de passe
                },
                child: Text(
                  "Mot de passe oublié?",
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultBorderRadius),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                "Se connecter",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}