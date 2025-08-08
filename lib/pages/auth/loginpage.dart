import 'package:bookcycle/pages/auth/registerpage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/homepage.dart';

import '../../composants/CustomTextfield.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Homepage()),
          );
        }
      });
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
                  const Text("Bienvenue", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Image.asset("assets/images/sss.jpg", height: 120),
                  const SizedBox(height: 30),
          
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
                  const SizedBox(height: 25),
          
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('CONNEXION'),
                    ),
                  ),
                  const SizedBox(height: 15),
          
                  // Register Link
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const RegisterPage())),
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