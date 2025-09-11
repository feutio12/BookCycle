// color_constants.dart
import 'package:flutter/material.dart';

const primaryColor = Color(0xFF2697FF);
const primaryLightColor = Color(0xFF73C2FB);
const secondaryColor = Color(0xFF292929);
const secondaryLightColor = Color(0xFF3A3A3A);
const bgColor = Color(0xFF212121);
const greenColor = Color(0xFF6bab58);
const errorColor = Color(0xFFF44336);
const successColor = Color(0xFF4CAF50);
const warningColor = Color(0xFFFF9800);

const defaultPadding = 16.0;
const double defaultBorderRadius = 12.0;
const double cardPadding = 20.0;

class Palette {
  static const Color wrapperBg = Color(0xFF212121);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2697FF), Color(0xFF0080FF)],
  );
}