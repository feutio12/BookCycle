import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {

  final String hintText;
  final IconData icon;
  const CustomTextfield({

    super.key,
    required this.hintText,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
