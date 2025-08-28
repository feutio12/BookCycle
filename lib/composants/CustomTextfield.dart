import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintext;
  final IconData prefixIcon;
  final IconButton? surfixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.onChanged,
    this.hintext,
    this.surfixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autofillHints: autofillHints,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintext,
        hintStyle: const TextStyle(color: Colors.grey),
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: surfixIcon,
        prefixIcon: Icon(prefixIcon, color: Colors.blue),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }
}