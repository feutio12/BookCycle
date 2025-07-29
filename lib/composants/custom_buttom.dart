import 'package:flutter/material.dart';


class CustomButtom extends StatelessWidget {

  final String label;
  final Color background;
  final VoidCallback action;

  const CustomButtom({
    super.key,
    required this.label,
    required this.background,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: action,
        child: Text(label),
    );
  }
}
