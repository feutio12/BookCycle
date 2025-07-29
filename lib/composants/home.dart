import 'package:bookcycle/composants/app_bar_personnalisee.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomTextfield(
              hintText: "Entrez votre nom",
              icon: Icons.person,
          ),
        ],
      )
    );
  }
}
