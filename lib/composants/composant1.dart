import 'package:flutter/material.dart';

class CustomButtomNav extends StatelessWidget {
  final String label;
  final VoidCallback action;
  final Color background;
  final double large;

  const CustomButtomNav({
    super.key,
    required this.label,
    required this.action,
    required this.background,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * large,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: background,
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(label,style: TextStyle(
            fontSize: 16,fontWeight: FontWeight.bold
        ),),
      ),
    );
  }
}